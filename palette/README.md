# Palette

The slate palette (mono: the accent is a soft white, so the rice reads black-and-white), taken from `docs/reference.png`. Every config uses these names; the
hex values live in one file per format:

- `hypr/.config/hypr/colors.lua` (Hyprland)
- `hypr/.config/hypr/colors.conf` (hyprlock)
- `waybar/.config/waybar/colors.css` and `swaync/.config/swaync/colors.css`
- `rofi/.config/rofi/colors.rasi`
- `kitty/.config/kitty/colors.conf`
- `nvim/.config/nvim/lua/config/colors.lua` (Neovim, via catppuccin overrides)

`tests/check.sh palette` checks that every file uses all of these and no other colors.

| Token     | Hex       | Used for                          |
|-----------|-----------|-----------------------------------|
| `bg`      | `#1F232A` | launcher, desktop background      |
| `surface` | `#262B33` | window surfaces                   |
| `raised`  | `#2E343E` | inputs, hovered rows              |
| `muted`   | `#4B5263` | borders, inactive things          |
| `subtext` | `#8B92A0` | secondary text                    |
| `fg`      | `#C8CCD4` | main text                         |
| `accent`  | `#E6E9EF` | selection, borders, bar text     |
| `blue`    | `#61AFEF` | kitty ANSI blue only              |
| `red`     | `#E06C75` | errors, critical states          |
| `green`   | `#98C379` | connected rows, lock check        |
| `yellow`  | `#E5C07B` | warnings                          |
| `orange`  | `#D19A66` | kitty, spare                      |
| `teal`    | `#56B6C2` | kitty, spare                      |
| `magenta` | `#C678DD` | kitty, spare                      |
