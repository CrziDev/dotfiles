local c = require("colors")
local function rgb(hex) return "rgb(" .. hex .. ")" end

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 0,  -- no window borders (mono look); set 2 to bring the accent border back
        col = {
            active_border   = rgb(c.accent),
            inactive_border = rgb(c.muted),
        },
        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 8,
        rounding_power = 2,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = "rgba(00000066)",
        },
        -- Blur only matters for layers with the blur rule (bar, launcher, notifications).
        blur = {
            enabled = true,
            size    = 4,
            passes  = 2,
        },
    },

    -- Animations were off in Mike's previous config; kept off.
    animations = { enabled = false },

    dwindle = { preserve_split = true },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})
