local dock = os.getenv("HOME") .. "/.local/bin/rice-dock"

hl.on("hyprland.start", function()
    -- One chain: the systemd services need WAYLAND_DISPLAY imported first.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME GSK_RENDERER"
        .. " && systemctl --user start hyprpolkitagent swaync hyprpaper hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd(dock)
end)

-- The dock only covers monitors it saw at start, so restart it when one is plugged in.
hl.on("monitor.added", function()
    hl.exec_cmd("sleep 1 && " .. dock)
end)
