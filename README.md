# Focus border for Omarchy

With more than one monitor, it is easy to lose track of which one has keyboard
focus, especially on an empty workspace, where no window border gives it away.
Then `SUPER + 1` switches workspaces on the "wrong" screen.

This [Omarchy](https://omarchy.org/) shell plugin draws a thin outline around
the monitor that has keyboard focus. The outline moves with the focus and can
flash briefly when it lands on another monitor, so you can see where it went.

- Picks a color from your current theme that stands out against the
  background, and follows theme changes.
- Never takes clicks or keyboard focus. It is drawn on top but is purely
  visual.
- Shows nothing when only one monitor is connected.

## Install

```bash
omarchy plugin add https://github.com/KamenDCZ/omarchy-focus-border.git --enable
```

Update later with `omarchy plugin update kamendcz.focus-border`, and remove it
with `omarchy plugin remove kamendcz.focus-border`.

## Turn it off and on

Omarchy switches plugins on and off itself. Both take effect immediately:

```bash
omarchy plugin disable kamendcz.focus-border
omarchy plugin enable kamendcz.focus-border
```

You can also pick the plugin from a list with `omarchy menu plugin`.

> [!NOTE]
> `omarchy plugin disable` removes the plugin's whole entry from
> `~/.config/omarchy/shell.json`, including your [settings](#settings).
> After `enable` you start from the defaults again, so copy your settings
> somewhere first if you want to keep them.

## Settings

All settings are optional. Add them to the plugin's entry in the `plugins`
list of `~/.config/omarchy/shell.json`. Changes apply as soon as you save the
file.

```json
{
  "plugins": [
    {
      "id": "kamendcz.focus-border",
      "color": "auto",
      "width": 2,
      "restOpacity": 0.5,
      "flash": false,
      "flashOpacity": 0.75
    }
  ]
}
```

| Setting        | Default  | Description |
|----------------|----------|-------------|
| `color`        | `"auto"` | `"auto"`, a color name from the current theme (`"yellow"`, `"red"`, `"blue"`, `"accent"`, ...), or a hex value such as `"#f5c211"`. |
| `width`        | `2`      | Outline width in logical pixels (0.5 to 20). |
| `restOpacity`  | `0.5`    | Opacity of the outline while idle (0 to 1). |
| `flash`        | `false`  | Flash the outline when focus moves to another monitor. |
| `flashOpacity` | `0.75`   | Opacity at the peak of the flash (0 to 1). |

Invalid values are ignored and fall back to the default.

### How `"auto"` picks a color

`"auto"` looks at the named colors in the current theme's `colors.toml` (red,
orange, yellow, green, cyan, blue, magenta and their bright variants) and uses
the one with the highest contrast against the theme background. It skips the
theme's accent color, because Hyprland already draws window borders in it and
the two outlines would blend together.

On a dark theme this is usually a yellow or a light green; on a light theme
usually a red. Monochrome themes such as Matte Black have no vivid colors, so
the outline comes out grey there, still with high contrast.

### Width and fractional scaling

A screen cannot draw less than one physical pixel. With fractional scaling,
`width` is multiplied by the scale and rounded, so nearby values can look the
same. At a scale of 1.25, for example, both `0.8` and `1` draw one physical
pixel. Below one physical pixel, the outline disappears.

## Requirements

Omarchy with the Quickshell-based Omarchy shell, running on Hyprland.

## License

[MIT](LICENSE)
