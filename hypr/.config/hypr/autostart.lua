hl.on("hyprland.start", function()
    -- One chain: the systemd services need WAYLAND_DISPLAY imported first.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME"
        .. " && systemctl --user start hyprpolkitagent swaync hyprpaper hypridle")
    hl.exec_cmd("waybar")
    hl.exec_cmd("nwg-dock-hyprland -d -i 32 -mb 8 -hd 0 -nolauncher")
end)
