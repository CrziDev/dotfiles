# dotfiles

My Arch + Hyprland 0.57 setup. Slate-gray look based on `docs/reference.png`.

## Install

Each top-level folder with a `.config/` (or `.local/`) inside is a stow package.

```sh
cd ~/dotfiles
stow -t ~ hypr waybar swaync rofi kitty mpv networkmanager-dmenu nwg-dock starship fastfetch nvim
stow --no-folding -t ~ gtk qt scripts   # keeps ~/.config/gtk-3.0 etc. as real dirs

~/.local/bin/rice-apply-theme   # GTK theme, icons, fonts, grey Papirus folders (asks for sudo once)
~/.local/bin/rice-apply-mime    # default apps (mime/defaults.tsv) + Thunar prefs
~/.local/bin/rice-dock-pins     # dock pins: kitty, thunar, browser, steam, lutris
```

The starship prompt is a marked block at the end of `~/.bashrc` (`# >>> rice >>>`); `.bashrc` itself isn't stowed.

Not stowed: `wallpapers/`, `mime/`, `palette/` (color table; hex values live in one `colors.*` file per app), `docs/`, `tests/`.

## Keys

| Key | |
|---|---|
| `SUPER+Q` | kitty |
| `SUPER+E` | Thunar |
| `SUPER+SPACE` / `SUPER+R` | launcher |
| `SUPER+C` | close window |
| `SUPER+V` | float |
| `SUPER+J` | toggle split |
| `SUPER+B` | toggle bar |
| `SUPER+L` | lock |
| `SUPER+X` | power menu |
| `SUPER+N` | notifications |
| `SUPER+M` | exit Hyprland |
| `SUPER+S` / `SUPER+SHIFT+S` | scratchpad / move to scratchpad |
| `SUPER+arrows` / `SUPER+SHIFT+arrows` | focus / move window |
| `SUPER+1..0` / `SUPER+SHIFT+1..0` | workspace / move to workspace |
| `Print` or `SUPER+P` / `SHIFT+Print` | screenshot / region |

Bar: mono and transparent over the dusk wallpaper. Click wifi or bluetooth for a menu, right-click for the full settings app. Click the bell or the volume icon for the quick panel (volume, per-app volume, brightness, notifications); click outside to close it. Right-click the bell for do-not-disturb, right-click volume to mute, middle-click volume for the full mixer. Scroll on volume or brightness to change it.

Idle: dim 5 min, lock 10, screens off 11, suspend at 30 only on battery. Fullscreen windows and games block all of it.

Neovim: catppuccin recolored with the palette (`nvim/.config/nvim/lua/config/colors.lua`) and a transparent background, so it shows kitty's own background like the shell does. Plugins are one file per area under `lua/plugins/`. Syntax highlighting needs `tree-sitter-cli`; the parsers install on first start (or `:TSUpdate`).

## Checks

```sh
tests/check.sh all                        # everything
tests/check.sh waybar menus               # specific areas
RICE_UNPLUG_TEST=1 tests/check.sh waybar  # also simulates unplugging HDMI-A-1 (blinks the screen)
```

The live checks open and close test windows, move the cursor, restart waybar and briefly block bluetooth.

`protected` fails if anything under `~/Games`, Steam, Lutris or the game CPU cap changed since `tests/protected.baseline` was taken.

## Restore

See `RESTORE.md`. Old configs are in `~/Documents/Backups/config-backup-2026-11-11/`.

Note: `arc-gtk-theme` from the AUR doesn't build as-is (GNOME Shell theme step). Build it with `-Dthemes=gtk2,gtk3,gtk4,xfwm` in the PKGBUILD.
