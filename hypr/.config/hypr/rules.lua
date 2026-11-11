-- Small utility windows float, centered.
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol|nm-connection-editor|blueman-manager|\\.blueman-manager-wrapped|org\\.xfce\\.ristretto|org\\.gnome\\.FileRoller|file-roller)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "float-file-dialogs",
    match = { title = "^(Open|Save|Select|Choose).*" },
    float  = true,
    center = true,
})

-- Any fullscreen window (games, video): no blur/shadow, and the screen never dims or locks.
hl.window_rule({
    name  = "fullscreen-clean",
    match = { fullscreen = true },
    no_blur      = true,
    no_shadow    = true,
    idle_inhibit = "fullscreen",
})

-- Steam games and Wine/Lutris games, even when windowed.
hl.window_rule({
    name  = "games",
    match = { class = "^(steam_app_.*|.*\\.exe)$" },
    no_blur      = true,
    no_shadow    = true,
    idle_inhibit = "focus",
})

-- Defaults worth keeping.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Blur behind the bar, launcher and notifications.
for _, ns in ipairs({ "waybar", "rofi", "swaync-control-center", "swaync-notification-window" }) do
    hl.layer_rule({
        name  = "blur-" .. ns,
        match = { namespace = "^" .. ns .. "$" },
        blur         = true,
        ignore_alpha = 0.2,
    })
end
