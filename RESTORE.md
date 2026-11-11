# Restore the old desktop

The configs from before the rice are in `~/Documents/Backups/config-backup-2026-11-11/`, with the same
paths as under `$HOME`.

If something looks broken:

1. Switch to a TTY with **Ctrl+Alt+F3** and log in.
2. Unlink everything except the Hyprland config:

   ```bash
   cd ~/dotfiles
   stow -D -t ~ waybar swaync rofi kitty mpv networkmanager-dmenu nwg-dock starship fastfetch gtk qt scripts
   ```

3. Put the old configs back (skipping `hypr`):

   ```bash
   cd ~/Documents/Backups/config-backup-2026-11-11
   cp -a .bashrc ~/
   for d in .config/*; do [ "$d" = .config/hypr ] || cp -a "$d" ~/.config/; done
   ```

4. Start Hyprland the way you usually do.

Keep `hypr` stowed. Hyprland 0.57 only reads `hyprland.lua`, so the backed-up
`hyprland.conf` no longer works; without the Lua config you get stock Hyprland.
If Hyprland itself won't start, run `Hyprland --verify-config` from the TTY to see the error.

The restored `.bashrc` drops the starship block (`# >>> rice >>>` … `# <<< rice <<<`),
which was the only change to it.
