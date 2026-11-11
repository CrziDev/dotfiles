# Palette

The slate palette, taken from `docs/reference.png`. Every config uses these names; the
hex values live in one file per format:

- `hypr/.config/hypr/colors.lua` (Hyprland)
- `hypr/.config/hypr/colors.conf` (hyprlock)
- `waybar/.config/waybar/colors.css` and `swaync/.config/swaync/colors.css`
- `rofi/.config/rofi/colors.rasi`
- `kitty/.config/kitty/colors.conf`

`tests/check.sh palette` checks that every file uses all of these and no other colors.

| Token     | Hex       | Used for                          |
|-----------|-----------|-----------------------------------|
| `bg`      | `#1F232A` | bar, launcher, desktop background |
| `surface` | `#262B33` | window surfaces                   |
| `raised`  | `#2E343E` | pills, inputs, hovered rows       |
| `muted`   | `#4B5263` | borders, inactive things          |
| `subtext` | `#8B92A0` | secondary text                    |
| `fg`      | `#C8CCD4` | main text                         |
| `accent`  | `#61AFEF` | selection, active border, focus   |
| `red`     | `#E06C75` | power, errors, critical           |
| `green`   | `#98C379` | CPU icon                          |
| `yellow`  | `#E5C07B` | warnings                          |
| `orange`  | `#D19A66` | temperature                       |
| `teal`    | `#56B6C2` | memory, folders                   |
| `magenta` | `#C678DD` | disk                              |
