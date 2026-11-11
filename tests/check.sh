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
    assert_ok "backup has $p" test -e "$HOME/config-backup-2026-11-11/$p"
  done
  assert_ok "dotfiles is a git repo" git -C "$DOT" rev-parse
  assert_ok "RESTORE.md exists" test -s "$DOT/RESTORE.md"
}

REPO_PKGS=(stow hyprpaper hypridle hyprlock hyprpolkitagent kvantum qt5ct qt6ct papirus-icon-theme
  nwg-look noto-fonts thunar thunar-archive-plugin thunar-volman thunar-media-tags-plugin gvfs gvfs-mtp
  gvfs-gphoto2 tumbler ffmpegthumbnailer file-roller ristretto unrar nm-connection-editor
  nwg-dock-hyprland starship fastfetch jq pavucontrol shellcheck)
AUR_PKGS=(arc-gtk-theme papirus-folders mpv-uosc rofi-bluetooth-git networkmanager-dmenu)
check_packages() {
  local p
  for p in "${REPO_PKGS[@]}" "${AUR_PKGS[@]}"; do assert_ok "installed: $p" pacman -Q "$p"; done
}

PALETTE=(1F232A 262B33 2E343E 4B5263 8B92A0 C8CCD4 61AFEF E06C75 98C379 E5C07B D19A66 56B6C2 C678DD)
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
