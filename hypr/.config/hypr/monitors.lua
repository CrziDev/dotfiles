hl.monitor({ output = "eDP-1",    mode = "preferred", position = "0x0",        scale = "auto" })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto-right", scale = "auto" })
hl.monitor({ output = "",         mode = "preferred", position = "auto",       scale = "auto" })

-- Workspaces 1-5 on the external screen, 6-9 on the laptop (as before).
-- If HDMI-A-1 is unplugged, Hyprland puts 1-5 on eDP-1.
for i = 1, 5 do hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" }) end
for i = 6, 9 do hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" }) end
