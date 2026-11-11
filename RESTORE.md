# Restore the old desktop

The configs from before the rice are in `~/config-backup-2026-11-11/`, with the same
paths as under `$HOME`.

If Hyprland won't start or something looks broken:

1. Switch to a TTY with **Ctrl+Alt+F3** and log in.
2. Unlink the new configs:

   ```bash
   cd ~/dotfiles && stow -D -t ~ */
   ```

3. Put the old ones back:

   ```bash
   cp -a ~/config-backup-2026-11-11/. ~/
   ```

4. Start Hyprland the way you usually do.

The `cp` restores `.bashrc` too. The only change made to it was a starship block marked
`# >>> rice >>>` … `# <<< rice <<<`.
