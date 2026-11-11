# Arch desktop rice — design

Date: 2026-11-11
Status: approved by Mike 2026-11-11 (including auto dim/lock idle policy)

## Intent

Mike wants his Arch + Hyprland laptop to look like the Archcraft "Openbox" reference
screenshot (simple slate-gray desktop) and, just as important, to make everyday tasks
painless without a terminal:

- connecting to wifi and bluetooth
- opening pictures, zips and videos from the file manager

He handed all tool and config choices to the builder ("free to reset and remove anything
and start from scratch") with one hard rule: **do not remove his files or his games**.

Choices marked **(builder call)** were made by Claude, not by Mike. He can veto them.

## Reference look (what "done" looks like)

The reference image is saved at `~/dotfiles/docs/reference.png` and is the visual spec.
Compare against it, not against memory of Archcraft (it has several looks). It shows
Archcraft's Openbox theme:

- **Palette:** dark slate gray, flat, low contrast. Bar/background ≈ `#1F232A`, window
  surfaces ≈ `#262B33`, raised elements ≈ `#2E343E`, borders/dim text ≈ `#4B5263`,
  text ≈ `#C8CCD4`, accent blue ≈ `#61AFEF` (selected rows, active pills). Small
  colored accents only on icons in the bar (green/teal/orange/pink as in the screenshot).
- **Font:** JetBrains Mono Nerd Font for the bar, launcher, terminal and menus (already
  installed). Regular sans (Noto Sans) for GTK app text, as in the Thunar window.
- **Top bar:** full-width and dark. Content sits in rounded "pill" groups:
  - left: distro logo, workspace dots, CPU, RAM, disk
  - center: clock, media controls with track title
  - right: volume with slider, brightness, wifi name, bluetooth, battery, power button
- **Launcher:** centered rounded panel with a search field and mode buttons on the right
  (apps / run / files / windows). Monospace list with icons; the selected row is filled
  with the accent blue.
- **Windows:** small gaps, rounded corners, thin borders, slight shadow, no heavy blur
  or flashy animations. (Openbox title bars are not reproduced; Hyprland is tiling.)
- **Wallpaper:** grayscale snowy mountains.
- **Dock:** small icon dock, bottom center.
- **Terminal:** same palette, fastfetch on demand with an icon-list layout like the
  screenshot.

## Goals

1. One consistent slate-gray theme across Hyprland, the bar, the launcher, notifications,
   the terminal, GTK apps and Qt apps.
2. Wifi: clicking the bar's wifi pill opens a themed menu. It lists networks, connects,
   asks for the password and can toggle wifi. Right-click opens the full network editor.
3. Bluetooth: clicking the bar's bluetooth pill opens a themed menu. It can power on/off,
   scan, pair, connect and disconnect. Right-click opens Blueman's manager.
4. Files: a file manager where double-click just works:
   - images open in a simple viewer with next/previous browsing
   - zip/7z/rar/tar open in an archive app, with "Extract here" in the right-click menu
   - videos open in mpv with a clickable on-screen control bar
   - image and video folders show thumbnails
   - USB drives and phones mount from the sidebar
5. Volume, brightness, media, power menu (lock / logout / suspend / reboot / shutdown)
   and notifications all reachable from the bar.
6. The configs live in a git-tracked `~/dotfiles` and are symlinked into place, so
   they're versioned and easy to restore.

## Non-goals

- No changes to the shell: bash stays. Only the prompt and fastfetch get themed.
- No changes to Neovim, VS Code (Code - OSS), browsers or other dev tools.
- No clipboard manager, widgets, music visualizer or extra desktop gadgets.
- No kernel, bootloader, display manager or GPU driver changes.

## Anti-goals (failure even if it "works")

- Anything in `~/Games`, Steam (`~/.local/share/Steam`, `~/.steam`), Lutris
  (`~/.local/share/lutris`), Proton/Wine prefixes or personal files (`~/Documents`,
  `~/Pictures`, `~/Downloads`, project folders, etc.) is deleted, moved or modified.
- The game CPU cap stops working: `/usr/local/bin/game-cpu-cap`,
  `/etc/sudoers.d/game-cpu-cap` and the Lutris pre-launch/post-exit hooks must stay intact.
- Games run worse because of the rice. Fullscreen games must not get blur, shadows or
  idle lock/dim, and NVIDIA hybrid setup (`nvidia-open`) must keep working.
- Mike loses network access mid-setup and can't get it back.
- He's left at a broken login with no easy way back. Every replaced config must be
  restorable.
- Muscle memory breaks: existing keybinds keep doing the same thing (see Keybinds).

## Current system (as found 2026-11-11)

- Acer laptop: Ryzen 5 5500U, RTX 3050 Mobile (`nvidia-open`), AMD backlight
  (`amdgpu_bl1`). `/sys/class/power_supply` currently shows only `ACAD` and no battery,
  so the battery module must hide itself when there's no battery.
- Monitors: `eDP-1` 1920x1080 internal (scale `auto`), `HDMI-A-1` 1920x1080 external
  placed to the right. Both are used.
- Hyprland (single 334-line `hyprland.conf`, mostly default), Waybar, Rofi, Kitty, SwayNC,
  hyprshot, flameshot, pipewire/wireplumber, playerctl, brightnessctl. `wofi` is **not**
  installed, so `SUPER+R` (bound to wofi) is broken today. No NVIDIA env lines exist in
  `hyprland.conf`, so don't add any.
- Login: no display manager. Mike logs in at a TTY and starts Hyprland by hand, so
  "logout" in the power menu returns him to the TTY.
- Existing workspace rules: workspaces 1–5 on `HDMI-A-1`, 6–9 on `eDP-1`. Keep them.
- Not installed yet: `stow`, `hyprpaper`, `hypridle`, `hyprlock`, `kvantum`.
  `~/dotfiles` exists but isn't a git repo yet.
- Network: NetworkManager active. `iwd` is installed but inactive; there's no
  `wifi.backend` override, so NetworkManager uses wpa_supplicant. `systemd-networkd` is
  also enabled. Leave it alone; don't touch it as part of this work.
- Bluetooth: bluez + blueman, service active.
- Files: Dolphin + kio-extras, `7zip`, `unzip`, `feh`, `mpv`. No archive GUI, no video
  thumbnailer, no GTK/icon theme set (`~/.config/gtk-3.0/settings.ini` is empty or
  missing).
- Shell: bash (`.bashrc`, `.bash_profile`, `.profile`). AUR helper: `yay`.
- Games: Steam, Lutris, wine-staging, MangoHud.

## Decided "how"

### Safety first

- Before touching anything, copy every config directory or file to be replaced into
  `~/config-backup-2026-11-11/` (hypr, waybar, rofi, kitty, swaync, gtk-3.0, gtk-4.0,
  mimeapps.list, dolphinrc, .bashrc, plus anything else that gets overwritten).
- Add a short `~/dotfiles/RESTORE.md` with the exact commands to put the backup back
  from a TTY (Ctrl+Alt+F3) if Hyprland won't start.
- Package removals use `pacman -Rns` on named packages only. Never remove anything that
  Steam, Lutris, wine or MangoHud depend on. Review the removal list before running it.

### Dotfiles layout (builder call)

`~/dotfiles` is a git repo with one folder per app (`hypr/`, `waybar/`, `rofi/`, `kitty/`,
`swaync/`, `gtk/`, `qt/`, `thunar/`, `mpv/`, `fastfetch/`, `starship/`, `wallpapers/`,
`scripts/`), symlinked into `~/.config` with GNU `stow`. One shared palette file is the
source of colors, so the hex values above live in one place per format (CSS for
Waybar/SwayNC, rasi for Rofi, conf for Kitty/Hyprland).

### Hyprland

- Split into `monitors.conf`, `keybinds.conf`, `look.conf`, `autostart.conf`,
  `rules.conf`, `env.conf`, all sourced from `hyprland.conf`.
- Look: gaps ~5 inner / ~10 outer, rounding 8, 2px border (accent on the active window,
  dim gray otherwise), soft shadow, light blur only on the bar/launcher/notification
  layers, short, subtle animations.
- Window rules: float + center pavucontrol, nm-connection-editor, blueman, file dialogs
  and image viewer. Fullscreen windows and Steam/Lutris games get no blur, no shadow and
  an idle inhibit.
- Autostart: waybar, swaync, hyprpaper, hypridle, polkit agent, dock.
- Keep existing env, input and keyboard settings, and the NVIDIA-related env if any is
  present.

### Keybinds (keep muscle memory)

Keep: `SUPER+Q` terminal (kitty), `SUPER+C` close, `SUPER+M` exit, `SUPER+E` file
manager, `SUPER+V` float, `SUPER+B` toggle bar, `SUPER+SPACE` and `SUPER+R` launcher,
`SUPER+J` toggle split, arrows to move focus, `SUPER+1..0` workspaces,
`SUPER+SHIFT+1..0` move to workspace, `SUPER+S` / `SUPER+SHIFT+S` special workspace,
mouse move/resize, all media/volume/brightness keys, `PRINT` and `SUPER+P` full screenshot.

Fix existing conflicts (builder call): `SUPER+S` was bound to both the launcher and the
special workspace, so it stays special workspace only. `SUPER+P` was bound to both
screenshot and pseudo, so it stays screenshot only.

Add: `SHIFT+PRINT` region screenshot, `SUPER+L` lock, `SUPER+X` power menu, `SUPER+N`
notification panel, `SUPER+SHIFT+arrows` move window.

### Bar — Waybar

Top bar on both monitors, matching the reference pill layout above. Modules:

- custom launcher icon (click → launcher)
- hyprland/workspaces as dots (filled = active)
- cpu, memory, disk
- CPU temperature (builder call: kept from the current bar because of the laptop's
  thermal throttling history; turn it warning-colored above ~85°C)
- clock (click → calendar tooltip)
- mpris (prev/play/next + title, hidden when nothing is playing)
- pulseaudio (scroll to change volume, click → pavucontrol)
- backlight
- network (click → wifi menu)
- bluetooth (click → bluetooth menu)
- battery (hidden when absent)
- power button (click → power menu)

Dropped from the current bar (builder call): `custom/weather` and `custom/powerDraw`,
because their scripts are missing and they're already broken, and `hyprland/window`
(the reference has no window title).

An in-bar volume slider like the reference is optional. Builder decides whether Waybar's
slider module works well enough; otherwise show a percentage.

### Launcher and menus — Rofi

- Use Rofi everywhere. wofi isn't installed, so just drop its binding.
- Launcher theme matching the reference: search field and mode buttons (drun / run /
  filebrowser / window).
- Same theme reused for:
  - wifi menu: `networkmanager-dmenu`, configured to use rofi (config dir already exists)
  - bluetooth menu: a rofi bluetooth script, `rofi-bluetooth` from the AUR or an
    equivalent small script in `~/dotfiles/scripts`
  - power menu (lock / logout / suspend / reboot / shutdown)

### Network cleanup

`iwd` is installed but unused. Remove it only after confirming NetworkManager isn't set to
use the iwd backend, which it isn't today. Keep NetworkManager + wpa_supplicant. Install
`nm-connection-editor` for the right-click "advanced" editor.

### Files and default apps (builder call: switch Dolphin → Thunar)

Thunar is chosen because it's what the reference uses and it takes the GTK theme cleanly.

- Install `thunar`, `thunar-archive-plugin`, `thunar-volman`, `thunar-media-tags-plugin`,
  `gvfs`, `gvfs-mtp`, `gvfs-gphoto2`, `tumbler`, `ffmpegthumbnailer`, `file-roller`,
  `ristretto` (image viewer, GTK3, matches Thunar).
- Install `unrar` (or keep `7zip` for rar) so rar files open.
- mpv gets a modern clickable on-screen control bar (`uosc` or similar, builder decides),
  themed to the palette.
- Set `mimeapps.list` defaults:
  - images → ristretto
  - archives → file-roller
  - video/audio → mpv
  - folders → thunar
  - text → keep current editor if one is set
- Remove `dolphin` and only those KDE packages that nothing else needs.

### Theme for apps

- GTK: `arc-gtk-theme` (Arc-Dark, as in the reference). Builder may tweak colors via
  `gtk.css` overrides to match the palette. Set through `gsettings`, `settings.ini` for
  GTK3/4 and `nwg-look` if needed.
- Icons: Papirus-Dark with gray folders (`papirus-folders -C grey`).
- Qt: `qt6ct` / `qt5ct` + Kvantum with an Arc-Dark Kvantum theme, so Qt apps (Postman,
  qBittorrent, etc.) match.
- Cursor: keep the current size (24). The cursor theme is the builder's choice; keep it
  plain.

### Notifications — SwayNC

Restyle to the palette: rounded, monospace and small. `SUPER+N` and a right-click on the
clock open the panel.

### Lock and idle (builder call)

- `hyprlock`: blurred wallpaper, big clock and password field in the palette.
- `hypridle`:
  - dim after 5 min
  - lock after 10 min
  - screen off after 11 min
  - no auto-suspend while on AC
  - suspend after 30 min on battery, only when a battery exists
- Respect idle inhibitors (video playing, fullscreen games).

### Wallpaper (builder call)

`hyprpaper`, with a grayscale mountain photo under a free license (Unsplash/Pexels) or a
desaturated version of one. Stored in `~/dotfiles/wallpapers/`. One wallpaper on both
monitors.

### Dock (builder call)

`nwg-dock-hyprland`, bottom center, small icons, auto-hide so it doesn't cover tiled
windows. Pinned apps: terminal, files, browser, Steam, Lutris.

### Terminal and prompt

- Kitty: palette colors, JetBrains Mono Nerd Font, padding ~12px, slight background
  opacity is fine.
- Prompt: `starship` with a minimal two-segment prompt similar to the reference
  (`>>> 📁 ~`). Added to `.bashrc` without removing anything else in it.
- fastfetch: icon-list layout like the screenshot, run manually (not on every terminal
  open).

## Rollout (builder call)

Build in stages, reloading Hyprland after each so a mistake shows up immediately:

1. Backups + `RESTORE.md` + dotfiles/stow skeleton
2. Install packages
3. Hyprland split config + keybinds
4. Palette, GTK/Qt/icons/fonts
5. Waybar
6. Rofi + wifi/bluetooth/power menus
7. Thunar + viewers + mime defaults
8. SwayNC, hyprlock/hypridle
9. Wallpaper, dock, kitty, prompt, fastfetch
10. Package cleanup (dolphin, iwd)

After each visual stage, take a screenshot (`grim`) and compare it with the reference.
Mike confirms wifi and bluetooth menus work with real devices at the end.

## Left to the builder

- Exact hex tuning, padding and sizes, as long as it reads like the reference
- Which Nerd Font icons to use per bar module
- mpv OSC choice, cursor theme, exact animation curves
- Script implementation details for the menus
- Whether the volume slider is a real slider or a percentage
