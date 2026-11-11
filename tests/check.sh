#!/usr/bin/env bash
# Rice checks. Usage: tests/check.sh <area>... | all
# Prints PASS:/FAIL: lines; exits non-zero if any assertion failed.
set -u
DOT="$HOME/dotfiles"
TMP="$DOT/tests/tmp"
FAILS=0
mkdir -p "$TMP"

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }
assert_eq() { if [ "$1" == "$2" ]; then pass "$3"; else fail "$3 (got '$1', want '$2')"; fi; }
assert_ok() { local l=$1; shift; if "$@" >/dev/null 2>&1; then pass "$l"; else fail "$l"; fi; }
assert_fail() { local l=$1; shift; if "$@" >/dev/null 2>&1; then fail "$l"; else pass "$l"; fi; }
assert_link() {
  if [ -L "$1" ] && [[ "$(readlink -f "$1")" == "$DOT"/* ]]; then pass "$1 links into dotfiles"
  else fail "$1 links into dotfiles"; fi
}
# hypr_bind <modmask> <key> -> "dispatcher arg" for each matching bind (SUPER=64, SHIFT=1)
hypr_bind() {
  hyprctl binds -j | jq -r --argjson m "$1" --arg k "$2" \
    '.[] | select(.modmask == $m and .key == $k) | "\(.dispatcher) \(.arg)"'
}
# layer_on <monitor> <namespace>: that layer surface is mapped on that monitor.
layer_on() { hyprctl layers -j | jq -e --arg m "$1" --arg n "$2" '.[$m].levels[]?[]? | select(.namespace==$n)' >/dev/null; }
# open_window <class> <command> [fullscreen]: runs the command, waits for its window, prints its address.
open_window() {
  local a=""
  hyprctl dispatch "hl.dsp.exec_cmd(\"$2\")" >/dev/null
  for _ in $(seq 1 30); do
    a=$(hyprctl clients -j | jq -r --arg c "$1" '[.[] | select(.class==$c)][0].address // empty')
    [ -n "$a" ] && break; timeout 0.2 tail -f /dev/null
  done
  [ "${3:-}" = fullscreen ] && hyprctl dispatch "hl.dsp.window.fullscreen({ window = \"address:$a\" })" >/dev/null
  timeout 0.6 tail -f /dev/null
  echo "$a"
}
# test_window <class> [fullscreen]: a kitty window with that class.
test_window() { open_window "$1" "kitty --class $1" "${2:-}"; }
client_get() { hyprctl clients -j | jq -r --arg a "$1" ".[] | select(.address==\$a) | $2"; }
client_monitor() { hyprctl monitors -j | jq -r --argjson id "$(client_get "$1" .monitor)" '.[] | select(.id==$id) | .name'; }
close_window() { hyprctl dispatch "hl.dsp.window.close({ window = \"address:$1\" })" >/dev/null; timeout 0.4 tail -f /dev/null; }
# hold_cursor_on_dock_strip <monitor>: keeps the cursor on the dock's hover strip for ~1s,
# then puts it back. (Warps don't reliably open the dock itself, so tests never rely on that.)
hold_cursor_on_dock_strip() {
  local orig hx hy
  orig=$(hyprctl cursorpos)
  read -r hx hy < <(hyprctl layers -j | jq -r --arg m "$1" \
    '.[$m].levels[]?[]? | select(.namespace=="hotspot") | "\(.x + (.w/2|floor)) \(.y + (.h/2|floor))"')
  for _ in $(seq 1 15); do
    hyprctl dispatch "hl.dsp.cursor.move({ x = $hx, y = $hy })" >/dev/null; timeout 0.07 tail -f /dev/null
  done
  hyprctl dispatch "hl.dsp.cursor.move({ x = ${orig%%,*}, y = ${orig##*, } })" >/dev/null
}

# --- protected paths (games, Lutris, CPU cap) ---
LUTRIS_HOOK_YML="$HOME/.local/share/lutris/games/pathfinder-kingmaker-1794217238.yml"
protected_fingerprint() {
  {
    find "$HOME/Games" "$HOME/.local/share/Steam" "$HOME/.steam" "$HOME/.local/share/lutris" \
      -maxdepth 2 -printf '%p\n' 2>/dev/null | sort
    sha256sum /usr/local/bin/game-cpu-cap "$LUTRIS_HOOK_YML"
  } | sha256sum | cut -d' ' -f1
}
check_protected() {
  assert_eq "$(protected_fingerprint)" "$(cat "$DOT/tests/protected.baseline" 2>/dev/null)" "protected paths unchanged"
  assert_ok "lutris cpu-cap hook present" grep -q 'game-cpu-cap on' "$LUTRIS_HOOK_YML"
  assert_ok "cpu-cap sudoers rule intact" sudo -n -l /usr/local/bin/game-cpu-cap on
}

check_backup() {
  local p
  for p in .config/hypr/hyprland.conf .config/waybar/config.jsonc .config/waybar/style.css \
           .config/rofi/config.rasi .config/kitty .config/networkmanager-dmenu/config.ini \
           .config/mimeapps.list .config/dolphinrc .config/mpv .bashrc; do
    assert_ok "backup has $p" test -e "$HOME/Documents/Backups/config-backup-2026-11-11/$p"
  done
  assert_ok "dotfiles is a git repo" git -C "$DOT" rev-parse
  assert_ok "RESTORE.md exists" test -s "$DOT/RESTORE.md"
}

REPO_PKGS=(stow hyprpaper hypridle hyprlock hyprpolkitagent kvantum qt5ct qt6ct papirus-icon-theme
  nwg-look noto-fonts thunar thunar-archive-plugin thunar-volman thunar-media-tags-plugin gvfs gvfs-mtp
  gvfs-gphoto2 tumbler ffmpegthumbnailer file-roller ristretto unrar nm-connection-editor
  nwg-dock-hyprland starship fastfetch jq pavucontrol shellcheck ttf-montserrat ttf-nerd-fonts-symbols-mono)
AUR_PKGS=(arc-gtk-theme papirus-folders mpv-uosc rofi-bluetooth-git networkmanager-dmenu)
check_packages() {
  local p
  for p in "${REPO_PKGS[@]}" "${AUR_PKGS[@]}"; do assert_ok "installed: $p" pacman -Q "$p"; done
}

PALETTE=(1F232A 262B33 2E343E 4B5263 8B92A0 C8CCD4 E6E9EF 61AFEF E06C75 98C379 E5C07B D19A66 56B6C2 C678DD)
PALETTE_FILES=(hypr/.config/hypr/colors.lua hypr/.config/hypr/colors.conf waybar/.config/waybar/colors.css
  swaync/.config/swaync/colors.css rofi/.config/rofi/colors.rasi kitty/.config/kitty/colors.conf)
check_palette() {
  local f h extra
  for f in "${PALETTE_FILES[@]}"; do
    if [ ! -f "$DOT/$f" ]; then fail "palette file exists: $f"; continue; fi
    for h in "${PALETTE[@]}"; do
      [ "$f" == "${PALETTE_FILES[5]}" ] && continue  # kitty maps a subset; checked below
      assert_ok "$f has $h" grep -qi "$h" "$DOT/$f"
    done
    extra=$(grep -oiE '[0-9a-f]{6}' "$DOT/$f" | tr a-f A-F | sort -u | grep -vxF -f <(printf '%s\n' "${PALETTE[@]}"))
    assert_eq "$extra" "" "$f uses only palette colors"
  done
}

HYPR_DIR="$HOME/.config/hypr"
# Static checks: work before the reboot into Hyprland 0.57 (Lua config).
check_hypr() {
  local out f
  assert_link "$HYPR_DIR"
  out=$(Hyprland --verify-config -c "$HYPR_DIR/hyprland.lua" 2>&1 | sed -n '/Config parsing result/,$p' | tail -n +2 | tr -d '\n ')
  assert_eq "$out" "configok" "hyprland.lua verifies clean"
  assert_fail "no legacy hyprland.conf left" test -e "$HYPR_DIR/hyprland.conf"
  for f in env monitors input look rules keybinds autostart; do
    assert_ok "hyprland.lua requires $f" grep -qE "^require\(\"$f\"\)" "$HYPR_DIR/hyprland.lua"
  done
  # Keybind table: each SUPER combo bound exactly once (duplicate-bind guard).
  out=$(grep -oE 'mainMod \.\. " \+ [A-Za-z0-9_:]+"' "$HYPR_DIR/keybinds.lua" | sort | uniq -d)
  assert_eq "$out" "" "no SUPER combo bound twice"
  for k in Q C M E V B R SPACE J S P L X N; do
    assert_ok "SUPER+$k is bound" grep -qE "mainMod \.\. \" \+ $k\"" "$HYPR_DIR/keybinds.lua"
  done
  assert_ok "SUPER+S is special workspace" grep -qE '" \+ S",.*toggle_special' "$HYPR_DIR/keybinds.lua"
  assert_ok "SUPER+P is screenshot" grep -qE '" \+ P",.*hyprshot -m output' "$HYPR_DIR/keybinds.lua"
  assert_ok "workspace 3 -> HDMI-A-1" grep -qE 'HDMI-A-1' "$HYPR_DIR/monitors.lua"
}
# Live checks: need the running compositor to be 0.57 with this config (after reboot).
check_hyprlive() {
  assert_ok "running Hyprland is 0.57+" bash -c 'hyprctl version | grep -qE "Hyprland 0\.(5[7-9]|[6-9][0-9])"'
  assert_eq "$(hyprctl configerrors | tr -d '[:space:]')" "" "no live config errors"
  assert_eq "$(hyprctl workspacerules -j | jq -r '[.[]|select(.workspaceString=="3")][0].monitor')" "HDMI-A-1" "ws3 on HDMI"
  assert_eq "$(hyprctl getoption general:gaps_out -j | jq -r '.css // .custom // .str // .int' | tr -d ' ')" "10101010" "gaps_out 10"
  # 0.57 binds -j shows only an opaque handle in .arg; command text is checked statically in check_hypr.
  assert_eq "$(hyprctl binds -j | jq -r '[.[] | select(.modmask==64 and .key=="Q")] | map(.dispatcher) | join(",")')" "HL.Dispatcher(exec_cmd)" "SUPER+Q bound once to exec_cmd"
  assert_eq "$(hyprctl binds -j | jq -r '[.[] | select(.modmask==64) | .key] | group_by(.) | map(select(length>1)[0]) | join(",")')" "" "no live SUPER combo bound twice"
}

gs() { gsettings get org.gnome.desktop.interface "$1"; }
check_theme() {
  assert_eq "$(gs gtk-theme)" "'Arc-Dark'" "gtk-theme Arc-Dark"
  assert_eq "$(gs icon-theme)" "'Papirus-Dark'" "icon-theme Papirus-Dark"
  assert_eq "$(gs font-name)" "'Noto Sans 10'" "font Noto Sans 10"
  assert_eq "$(gs monospace-font-name)" "'JetBrainsMono Nerd Font 10'" "mono font"
  assert_eq "$(gs color-scheme)" "'prefer-dark'" "color-scheme dark"
  assert_eq "$(gs cursor-size)" "24" "cursor size 24"
  assert_link "$HOME/.config/gtk-3.0/settings.ini"
  assert_link "$HOME/.config/gtk-4.0/settings.ini"
  assert_fail "gtk-3.0 dir itself not folded into repo" test -L "$HOME/.config/gtk-3.0"
  assert_ok "gtk3 settings.ini Arc-Dark" grep -qx 'gtk-theme-name=Arc-Dark' "$HOME/.config/gtk-3.0/settings.ini"
  assert_ok "kvantum theme KvArcDark" grep -qx 'theme=KvArcDark' "$HOME/.config/Kvantum/kvantum.kvconfig"
  assert_ok "qt6ct style kvantum" grep -qx 'style=kvantum' "$HOME/.config/qt6ct/qt6ct.conf"
  assert_ok "qt5ct style kvantum" grep -qx 'style=kvantum' "$HOME/.config/qt5ct/qt5ct.conf"
  assert_ok "papirus folders grey" bash -c "papirus-folders -l --theme Papirus-Dark 2>/dev/null | grep -E '^\\s*>\\s*grey\\b'"
  assert_ok "rice-apply-theme is executable" test -x "$HOME/.local/bin/rice-apply-theme"
}

WB_CFG="$HOME/.config/waybar/config.jsonc"
# Flatten modules-<pos>, expanding group/* into their member modules.
wb_modules() {
  jq -r --arg pos "modules-$1" '. as $c | [ .[$pos][] | if startswith("group/") then $c[.].modules[] else . end ] | join(",")' "$WB_CFG"
}
wb_restart() {
  pkill -x waybar; timeout 1 tail -f /dev/null
  hyprctl dispatch "hl.dsp.exec_cmd(\"waybar > $TMP/waybar.log 2>&1\")" >/dev/null
  timeout 4 tail -f /dev/null
}
wb_layer_on() { layer_on "$1" waybar; }
check_waybar() {
  assert_link "$HOME/.config/waybar"
  if ! jq -e . "$WB_CFG" >/dev/null 2>&1; then fail "config parses as JSON (skipping live checks)"; return; fi
  pass "config parses as JSON"
  assert_eq "$(wb_modules left)" "hyprland/workspaces,cpu,memory,temperature" "left modules"
  assert_eq "$(wb_modules center)" "clock" "center modules"
  assert_eq "$(wb_modules right)" "custom/notification,pulseaudio,backlight,bluetooth,network,battery,custom/power" "right modules"
  assert_eq "$(jq -r '[keys[] | select(test("launcher|mpris|media"))] | join(",")' "$WB_CFG")" "" "no launcher or media modules"
  assert_ok "bar background is transparent" grep -qzP 'window#waybar \{[^}]*background: transparent;' "$HOME/.config/waybar/style.css"
  assert_eq "$(jq -r '.pulseaudio."on-click"' "$WB_CFG")" "swaync-client -t -sw" "volume click opens the quick panel"
  assert_ok "notification module follows swaync" bash -c "jq -r '.\"custom/notification\".exec' '$WB_CFG' | grep -q 'swaync-client -swb'"
  assert_eq "$(jq -r 'has("output")' "$WB_CFG")" "false" "bar on every monitor (no output key)"
  assert_eq "$(jq -r '.temperature["hwmon-path-abs"]' "$WB_CFG")" "/sys/devices/pci0000:00/0000:00:18.3/hwmon" "temp uses k10temp path"
  assert_eq "$(jq -r '.temperature["critical-threshold"]' "$WB_CFG")" "85" "temp critical at 85"
  wb_restart
  assert_ok "waybar running" pgrep -x waybar
  # A missing battery is reported once by waybar; every other [error] is a real problem.
  assert_eq "$(grep '\[error\]' "$TMP/waybar.log" | grep -viE 'batter' | head -3)" "" "no waybar errors"
  assert_ok "waybar layer on eDP-1" wb_layer_on eDP-1
  if hyprctl monitors -j | jq -e '.[]|select(.name=="HDMI-A-1")' >/dev/null; then
    assert_ok "waybar layer on HDMI-A-1" wb_layer_on HDMI-A-1
  fi
  # Unplug simulation blinks the external monitor; opt-in with RICE_UNPLUG_TEST=1.
  if [ "${RICE_UNPLUG_TEST:-0}" = 1 ] && hyprctl monitors -j | jq -e '.[]|select(.name=="HDMI-A-1")' >/dev/null; then
    # Review focus 3: external monitor unplugged.
    hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })' >/dev/null
    timeout 3 tail -f /dev/null
    assert_ok "unplugged: waybar still on eDP-1" wb_layer_on eDP-1
    assert_ok "unplugged: wallpaper still on eDP-1" bash -c "hyprctl hyprpaper listactive | grep -q '^eDP-1: '"
    assert_ok "unplugged: dock strip still on eDP-1" layer_on eDP-1 hotspot
    hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })' >/dev/null
    assert_eq "$(hyprctl activeworkspace -j | jq -r .monitor)" "eDP-1" "unplugged: workspace 3 falls back to eDP-1"
    hyprctl reload >/dev/null; timeout 4 tail -f /dev/null
    assert_ok "replugged: HDMI-A-1 back" bash -c "hyprctl monitors -j | jq -e '.[]|select(.name==\"HDMI-A-1\")' >/dev/null"
    assert_ok "replugged: wallpaper on HDMI-A-1" bash -c "hyprctl hyprpaper listactive | grep -q '^HDMI-A-1: '"
    assert_ok "replugged: waybar on HDMI-A-1" wb_layer_on HDMI-A-1
    # The dock is restarted on monitor.added (after a 1s settle), so give it a few seconds.
    for _ in $(seq 1 20); do layer_on HDMI-A-1 hotspot && break; timeout 0.3 tail -f /dev/null; done
    assert_ok "replugged: dock strip on HDMI-A-1" layer_on HDMI-A-1 hotspot
    assert_eq "$(pgrep -cx nwg-dock-hyprla)" "1" "replugged: exactly one dock running"
  fi
  # Review focus 5: no battery -> no battery pill rendered.
  if ! ls /sys/class/power_supply/ | grep -q '^BAT'; then
    assert_ok "no battery: battery module not shown" grep -qiE 'batter' "$TMP/waybar.log"
  fi
}

BIN="$HOME/.local/bin"
POWER_TABLE=$'Lock\thyprlock\nLogout\thyprctl dispatch \'hl.dsp.exit()\'\nSuspend\tsystemctl suspend\nReboot\tsystemctl reboot\nShutdown\tsystemctl poweroff'
check_menus() {
  local f st bt_was bt_blocked fb="$TMP/fakebin"
  assert_link "$HOME/.config/rofi"
  assert_ok "launcher theme is ours (620px)" bash -c "rofi -theme launcher -dump-theme | grep -q 620px"
  assert_ok "launcher theme parses" rofi -theme launcher -dump-theme
  assert_ok "menu theme parses" rofi -theme menu -dump-theme
  assert_ok "default theme is menu" bash -c "rofi -dump-config | grep -q 'menu'"
  assert_ok "nm-dmenu uses rofi" grep -qE '^dmenu_command = rofi' "$HOME/.config/networkmanager-dmenu/config.ini"
  for f in rice-wifi-menu rice-bt-menu rice-powermenu; do
    assert_ok "$f executable" test -x "$BIN/$f"
    assert_ok "$f shellcheck clean" shellcheck "$BIN/$f"
  done
  assert_eq "$("$BIN/rice-powermenu" --print-actions)" "$POWER_TABLE" "power menu actions"
  # Review focus 4: opening a menu never turns a radio on by itself (an "off" sticks);
  # each menu has its own entry that turns the radio back on.
  rm -rf "$fb"; mkdir -p "$fb"
  ln -s "$DOT/tests/fixtures/fake-nmcli" "$fb/nmcli"
  ln -s "$DOT/tests/fixtures/fake-rofi" "$fb/rofi"
  printf '#!/bin/sh\necho opened >> "$FAKE_MENU_LOG"\n' > "$fb/networkmanager_dmenu"; chmod +x "$fb/networkmanager_dmenu"
  # Wifi: fake nmcli and menu, so the real connection (and this session) never drops.
  st="$TMP/nmcli-state"; rm -f "$st" "$st.log" "$TMP/menu.log"; echo disabled > "$st"
  PATH="$fb:$PATH" FAKE_NMCLI_STATE="$st" FAKE_MENU_LOG="$TMP/menu.log" "$BIN/rice-wifi-menu"
  assert_eq "$(cat "$st")" "disabled" "wifi off: opening the menu leaves it off"
  assert_ok "wifi off: menu still opens" grep -q opened "$TMP/menu.log"
  # The real wifi menu, with our config but a fake rofi, offers the on/off entry.
  sed "s|^dmenu_command = .*|dmenu_command = $fb/rofi|" "$HOME/.config/networkmanager-dmenu/config.ini" > "$TMP/nm-dmenu.ini"
  rm -f "$TMP/rofi.log"
  NM_DMENU_CONFIG="$TMP/nm-dmenu.ini" FAKE_ROFI_LOG="$TMP/rofi.log" timeout 15 networkmanager_dmenu >/dev/null 2>&1
  assert_ok "wifi menu has its own WiFi on/off entry" grep -qxE '(Enable|Disable) WiFi' "$TMP/rofi.log"
  # Bluetooth: real radio, fake rofi.
  if [ ! -x "$BIN/rice-bt-menu" ]; then fail "bt test skipped: rice-bt-menu missing"; return; fi
  bt_was=$(bluetoothctl show | awk '/Powered:/ {print $2}')
  bt_blocked=$(rfkill list bluetooth | grep -c 'Soft blocked: yes')
  rfkill block bluetooth; timeout 1 tail -f /dev/null
  rm -f "$TMP/rofi.log"
  PATH="$fb:$PATH" FAKE_ROFI_LOG="$TMP/rofi.log" "$BIN/rice-bt-menu" >/dev/null 2>&1
  assert_ok "bt blocked: opening the menu leaves it blocked" bash -c "rfkill list bluetooth | grep -q 'Soft blocked: yes'"
  assert_ok "bt blocked: menu offers 'Power: off'" grep -qx 'Power: off' "$TMP/rofi.log"
  rm -f "$TMP/rofi.log"
  PATH="$fb:$PATH" FAKE_ROFI_LOG="$TMP/rofi.log" FAKE_ROFI_PICK="Power: off" "$BIN/rice-bt-menu" >/dev/null 2>&1
  for _ in $(seq 1 10); do bluetoothctl show | grep -q 'Powered: yes' && break; timeout 0.5 tail -f /dev/null; done
  assert_eq "$(rfkill list bluetooth | grep -c 'Soft blocked: yes')" "0" "bt: picking 'Power: off' unblocks"
  assert_eq "$(bluetoothctl show | awk '/Powered:/ {print $2}')" "yes" "bt: picking 'Power: off' powers on"
  [ "$bt_was" = "no" ] && bluetoothctl power off >/dev/null
  [ "$bt_blocked" != 0 ] && rfkill block bluetooth
  return 0
}

check_files() {
  local mt id d fx
  while IFS=$'\t' read -r mt id; do
    assert_eq "$(xdg-mime query default "$mt")" "$id" "default for $mt"
  done < "$DOT/mime/defaults.tsv"
  fx="$TMP/files"; rm -rf "$fx"; mkdir -p "$fx"
  ffmpeg -loglevel error -f lavfi -i testsrc=d=2:s=320x240 -pix_fmt yuv420p -y "$fx/a.mp4"
  ffmpeg -loglevel error -f lavfi -i testsrc=s=320x240 -frames:v 1 -y "$fx/a b.png"
  (cd "$fx" && 7z a -bso0 -bsp0 a.zip "a b.png" && tar czf a.tar.gz "a b.png")
  assert_ok "video thumbnail generates" ffmpegthumbnailer -i "$fx/a.mp4" -o "$fx/t.png"
  assert_ok "ffmpegthumbnailer registered" test -f /usr/share/thumbnailers/ffmpegthumbnailer.thumbnailer
  for f in "a b.png:org.xfce.ristretto.desktop" "a.zip:org.gnome.FileRoller.desktop" \
           "a.tar.gz:org.gnome.FileRoller.desktop" "a.mp4:mpv.desktop"; do
    mt=$(xdg-mime query filetype "$fx/${f%%:*}")
    assert_eq "$(xdg-mime query default "$mt")" "${f#*:}" "opens ${f%%:*} ($mt)"
  done
  assert_ok "gvfs running (gio mount -l)" gio mount -l
  assert_eq "$(xfconf-query -c thunar -p /misc-thumbnail-mode 2>/dev/null)" "THUNAR_THUMBNAIL_MODE_ALWAYS" "thunar thumbnails always"
  assert_eq "$(xfconf-query -c thunar -p /misc-single-click 2>/dev/null)" "false" "thunar double-click"
  assert_link "$HOME/.config/mpv"
  assert_ok "mpv osc off" grep -qx 'osc=no' "$HOME/.config/mpv/mpv.conf"
  timeout 8 mpv --keep-open=no --idle=no --vo=null --ao=null --msg-level=all=v --frames=1 "$fx/a.mp4" > "$TMP/mpv.log" 2>&1
  assert_ok "mpv loads uosc with our config" grep -q '^\[uosc\] Opened config file' "$TMP/mpv.log"
}

check_idle() {
  local c p a
  for c in "ps-ac-only:skip" "ps-bat-discharging:suspend" "ps-bat-charging:skip"; do
    assert_eq "$(RICE_PS_ROOT="$DOT/tests/fixtures/${c%%:*}" "$BIN/rice-idle-suspend" --dry-run 2>&1)" "${c#*:}" "idle-suspend ${c%%:*} -> ${c#*:}"
  done
  assert_eq "$("$BIN/rice-idle-suspend" --dry-run 2>&1)" "skip" "idle-suspend on this machine (no battery) -> skip"
  assert_eq "$(grep -oE '^\s*timeout\s*=\s*[0-9]+' "$HYPR_DIR/hypridle.conf" | grep -oE '[0-9]+' | tr '\n' ' ')" "300 600 660 1800 " "hypridle timeouts"
  assert_ok "hyprlock.conf sources colors" grep -qE '^source\s*=.*colors\.conf' "$HYPR_DIR/hyprlock.conf"
  for p in $(grep -oE '^\s*path\s*=\s*\S+' "$HYPR_DIR/hyprlock.conf" | awk -F= '{gsub(/ /,"",$2); print $2}'); do
    [ "$p" = screenshot ] && continue
    assert_ok "hyprlock image exists: $p" test -f "${p/#\~/$HOME}"
  done
  assert_ok "hypridle running" pgrep -x hypridle
  assert_ok "swaync running" pgrep -x swaync
  assert_ok "swaync reloads config + css" bash -c "swaync-client -R && swaync-client -rs"
  assert_link "$HOME/.config/swaync"
  assert_eq "$(jq -r '.widgets[:2] | join(",")' "$HOME/.config/swaync/config.json")" "volume,backlight" "panel starts with volume + brightness sliders"
  assert_eq "$(jq -r '."layer-shell-cover-screen"' "$HOME/.config/swaync/config.json")" "true" "panel closes on click outside"
  # Review focus 2: our window rules (not the app) keep a fullscreen window or a focused
  # game from dimming/locking. kitty never inhibits idle by itself, which the first check proves.
  a=$(test_window rice-test-plain)
  assert_eq "$(client_get "$a" .inhibitingIdle)" "false" "plain window doesn't inhibit idle"; close_window "$a"
  a=$(test_window rice-test-fs fullscreen)
  assert_eq "$(client_get "$a" .inhibitingIdle)" "true" "fullscreen window inhibits idle"; close_window "$a"
  a=$(test_window rice-test.exe)
  assert_eq "$(client_get "$a" .inhibitingIdle)" "true" "focused game window (.exe) inhibits idle"; close_window "$a"
}

WALL="$DOT/wallpapers/mountains-dusk.jpg"
check_desktop() {
  local m sat sky a top bot
  for m in $(hyprctl monitors -j | jq -r '.[].name'); do
    assert_ok "wallpaper on $m" bash -c "hyprctl hyprpaper listactive | grep -qx '$m: $WALL'"
  done
  sat=$(ffprobe -v error -f lavfi "movie=$WALL,signalstats" -show_entries frame_tags=lavfi.signalstats.SATAVG -of csv=p=0 | head -1)
  assert_ok "wallpaper is grayscale (SATAVG=$sat)" awk -v s="$sat" 'BEGIN { exit !(s < 1) }'
  # The bar is transparent, so the sky behind it must stay dark enough for its white text.
  sky=$(ffprobe -v error -f lavfi "movie=$WALL,crop=iw:ih*0.04:0:0,signalstats" -show_entries frame_tags=lavfi.signalstats.YAVG -of csv=p=0 | head -1 | tr -d ,)
  assert_ok "sky behind the bar is dark (YAVG=$sky)" awk -v t="$sky" 'BEGIN { exit !(t <= 85) }'
  assert_ok "wallpaper source recorded" grep -q 'unsplash' "$DOT/wallpapers/SOURCE.md"
  assert_ok "hyprlock uses the wallpaper" grep -qE "^\s*path\s*=\s*~/dotfiles/wallpapers/mountains-dusk.jpg" "$HYPR_DIR/hyprlock.conf"
  assert_eq "$(pgrep -cx nwg-dock-hyprla)" "1" "exactly one dock running"
  assert_ok "rice-dock shellcheck clean" shellcheck "$BIN/rice-dock"
  assert_ok "autostart starts the dock via rice-dock" \
    bash -c "grep -qE '^local dock = .*rice-dock\"' '$HYPR_DIR/autostart.lua' && grep -qE '^\s+hl\.exec_cmd\(dock\)' '$HYPR_DIR/autostart.lua'"
  assert_ok "dock restarts when a monitor is plugged in" grep -qE 'hl\.on\("monitor\.added"' "$HYPR_DIR/autostart.lua"
  assert_eq "$(wc -l < "$HOME/.cache/nwg-dock-pinned")" "5" "dock has 5 pins"
  while read -r app; do
    assert_ok "pin $app has a desktop file" test -f "/usr/share/applications/$app.desktop"
  done < "$HOME/.cache/nwg-dock-pinned"
  assert_link "$HOME/.config/nwg-dock-hyprland"
  # Games: the dock's hover strip must stay below fullscreen windows. On the overlay layer
  # it takes the pointer, so clicks there never reach the game. wev logs the pointer
  # events it gets; a fullscreen wev must see motion on the strip's rows.
  assert_eq "$(hyprctl layers -j | jq '[.[].levels["3"][]? | select(.namespace=="hotspot" or .namespace=="nwg-dock")] | length')" "0" "dock not on the overlay layer"
  rm -f "$TMP/wev.log"
  a=$(open_window wev "wev -f wl_pointer > $TMP/wev.log 2>&1" fullscreen); m=$(client_monitor "$a")
  read -r top bot < <(hyprctl layers -j | jq -r --arg m "$m" --argjson wy "$(client_get "$a" '.at[1]')" \
    '.[$m].levels[]?[]? | select(.namespace=="hotspot") | "\(.y - $wy) \(.y - $wy + .h)"')
  hold_cursor_on_dock_strip "$m"
  close_window "$a"
  assert_ok "fullscreen: pointer on the dock strip still reaches the window" \
    awk -v t="$top" -v b="$bot" '/motion:/ { if ($NF >= t && $NF <= b) f = 1 } END { exit !f }' "$TMP/wev.log"
  for m in $(hyprctl monitors -j | jq -r '.[].name'); do
    assert_ok "dock hover strip on $m" layer_on "$m" hotspot
  done
  assert_ok "autostart starts hyprpaper via systemd after env import" grep -qE 'dbus-update-activation-environment.*' "$HYPR_DIR/autostart.lua"
  assert_ok "  ...in the same chain" grep -qE 'systemctl --user start [a-z ]*hyprpaper' "$HYPR_DIR/autostart.lua"
}

check_terminal() {
  local err
  assert_link "$HOME/.config/kitty"
  err=$(kitty +runpy 'import os,sys; from kitty.config import load_config; load_config(os.path.expanduser("~/.config/kitty/kitty.conf"))' 2>&1 >/dev/null)
  assert_eq "$err" "" "kitty.conf loads without warnings"
  assert_ok "kitty keeps remote control" grep -qx 'allow_remote_control yes' "$HOME/.config/kitty/kitty.conf"
  assert_ok "kitty includes palette" grep -qx 'include colors.conf' "$HOME/.config/kitty/kitty.conf"
  assert_link "$HOME/.config/starship.toml"
  err=$(STARSHIP_SHELL=bash starship prompt 2>&1 >/dev/null)
  assert_eq "$err" "" "starship renders without warnings"
  assert_link "$HOME/.config/fastfetch"
  assert_ok "fastfetch runs with config" bash -c "fastfetch -c '$HOME/.config/fastfetch/config.jsonc' --pipe 2>&1 | grep -q Hyprland"
  assert_eq "$(grep -c '^# >>> rice >>>' "$HOME/.bashrc")" "1" "bashrc has one rice block"
  assert_fail "bashrc has no inline secrets" grep -qE '^export [A-Z_]*(KEY|PASSWORD|_URL)=' "$HOME/.bashrc"
  assert_ok "bashrc sources secrets.env" grep -qF '.config/secrets.env' "$HOME/.bashrc"
  assert_eq "$(bash -ic 'type -t starship_precmd' 2>/dev/null)" "function" "interactive bash loads starship"
}

check_cleanup() {
  local p
  assert_fail "dolphin removed" pacman -Q dolphin
  assert_fail "iwd removed" pacman -Q iwd
  for p in steam lutris wine-staging mangohud networkmanager nvidia-utils thunar; do
    assert_ok "still installed: $p" pacman -Q "$p"
  done
  assert_eq "$(systemctl is-active NetworkManager bluetooth | tr '\n' ' ')" "active active " "NetworkManager + bluetooth active"
  assert_eq "$(nmcli -t -f STATE general)" "connected" "network connected"
}

# --- runner ---
if [ $# -eq 0 ]; then echo "usage: $0 <area>... | all" >&2; exit 2; fi
areas=("$@")
if [ "$1" == "all" ]; then
  mapfile -t areas < <(declare -F | awk '$3 ~ /^check_/ {sub(/^check_/, "", $3); print $3}')
fi
for a in "${areas[@]}"; do
  if declare -F "check_$a" >/dev/null; then echo "== $a"; "check_$a"
  else fail "no such area: $a"; fi
done
echo "RESULT: $FAILS failure(s)"
[ "$FAILS" -eq 0 ]
