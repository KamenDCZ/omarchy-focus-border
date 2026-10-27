import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons as Commons

// Outlines the monitor that has keyboard focus, so it is clear where
// SUPER + 1..9 will switch workspaces. When focus moves to another monitor,
// its outline flashes brighter and settles back to the resting opacity.
//
// Optional settings, on this plugin's entry in shell.json `plugins[]`:
//   { "id": "kamendcz.focus-border", "color": "auto", "width": 2,
//     "restOpacity": 0.5, "flash": false, "flashOpacity": 0.75 }
// "color" is "auto" (the default), a hex value, or a color name from the
// current theme's colors.toml (accent, yellow, red, blue, ...). "auto" picks
// the theme color that contrasts most with the background, skipping the
// accent because Hyprland already draws window borders in it.
// "flash": true turns on the flash on focus change (off by default).
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "kamendcz.focus-border"
  readonly property string shellConfigPath: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
  readonly property string themeColorsPath: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml"

  property var settings: ({})
  // Named colors of the current theme, e.g. { yellow: "#d0a215", ... }.
  property var palette: ({})

  readonly property color borderColor: {
    var c = root.colorSetting(settings.color)
    if (c === null) c = root.autoColor()
    if (c === null) c = Commons.Color.accent
    // Opacity is animated on the item, so drop any alpha in the color itself.
    return Qt.rgba(c.r, c.g, c.b, 1)
  }
  readonly property real borderWidth: root.numberSetting(settings.width, 2, 0.5, 20)
  readonly property real restOpacity: root.numberSetting(settings.restOpacity, 0.5, 0, 1)
  readonly property bool flashEnabled: settings.flash === true
  readonly property real flashOpacity: root.numberSetting(settings.flashOpacity, 0.75, 0, 1)
  property int flashInMs: 120
  property int flashHoldMs: 150
  property int flashOutMs: 600

  readonly property string focusedName: Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name) : ""

  function numberSetting(value, fallback, min, max) {
    var n = Number(value)
    if (value === undefined || value === null || value === "" || !isFinite(n)) return fallback
    return Math.min(max, Math.max(min, n))
  }

  function colorSetting(value) {
    if (typeof value !== "string") return null
    var v = value.trim()
    if (/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(v)) return Qt.color(v)
    var name = v.toLowerCase()
    if (Object.prototype.hasOwnProperty.call(root.palette, name)) return Qt.color(root.palette[name])
    if (name === "accent") return Commons.Color.accent
    return null
  }

  readonly property var autoCandidates: [
    "red", "orange", "yellow", "green", "cyan", "blue", "magenta",
    "bright_red", "bright_yellow", "bright_green", "bright_cyan", "bright_blue", "bright_magenta",
    "color1", "color2", "color3", "color4", "color5", "color6"
  ]

  function luminance(c) {
    function channel(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
    return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
  }

  function contrast(a, b) {
    var la = root.luminance(a)
    var lb = root.luminance(b)
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
  }

  // The theme color with the highest contrast against the background,
  // excluding the accent.
  function autoColor() {
    var background = Commons.Color.background
    var accent = String(Commons.Color.accent).toLowerCase()
    var best = null
    var bestContrast = 0
    for (var i = 0; i < root.autoCandidates.length; i++) {
      var hex = root.palette[root.autoCandidates[i]]
      if (!hex || hex.toLowerCase() === accent) continue
      var c = Qt.color(hex)
      var ratio = root.contrast(c, background)
      if (ratio > bestContrast) {
        best = c
        bestContrast = ratio
      }
    }
    return best
  }

  function readPalette(text) {
    var next = ({})
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]{1,40})\s*=\s*["']?(#[0-9A-Fa-f]{6})\b/)
      if (match) next[match[1].toLowerCase()] = match[2]
    }
    root.palette = next
  }

  function readSettings(text) {
    var next = ({})
    try {
      var config = JSON.parse(text)
      var plugins = config && Array.isArray(config.plugins) ? config.plugins : []
      for (var i = 0; i < plugins.length; i++) {
        var entry = plugins[i]
        if (entry && typeof entry === "object" && String(entry.id) === root.pluginId) {
          next = entry
          break
        }
      }
    } catch (e) {
      // Keep the previous settings while shell.json is mid-edit or invalid.
      return
    }
    root.settings = next
  }

  // Theme switches push new colors to the shell over IPC rather than
  // through a file watch, so re-read the palette whenever they change.
  FileView {
    id: themeColors
    path: root.themeColorsPath
    printErrors: false
    onLoaded: root.readPalette(text())
    onLoadFailed: root.palette = ({})
  }

  Connections {
    target: Commons.Color
    function onAccentChanged() { themeColors.reload() }
    function onBackgroundChanged() { themeColors.reload() }
    function onForegroundChanged() { themeColors.reload() }
  }

  FileView {
    path: root.shellConfigPath
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.readSettings(text())
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      visible: Quickshell.screens.length > 1 && String(modelData.name) === root.focusedName
      color: "transparent"
      // Visual-only: never take clicks or keyboard focus.
      mask: Region {}
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "focus-border"

      onVisibleChanged: if (visible && root.flashEnabled) flash.restart()

      Rectangle {
        id: frame
        anchors.fill: parent
        opacity: root.restOpacity
        color: "transparent"
        border.color: root.borderColor
        border.width: root.borderWidth
        antialiasing: true

        SequentialAnimation {
          id: flash
          NumberAnimation { target: frame; property: "opacity"; from: root.restOpacity; to: root.flashOpacity; duration: root.flashInMs; easing.type: Easing.OutQuad }
          PauseAnimation { duration: root.flashHoldMs }
          NumberAnimation { target: frame; property: "opacity"; to: root.restOpacity; duration: root.flashOutMs; easing.type: Easing.InOutQuad }
        }
      }
    }
  }
}
