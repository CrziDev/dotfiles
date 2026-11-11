-- Catppuccin recolored with the slate palette, transparent so kitty's own
-- background (and its 0.95 opacity) shows through like in the shell.
return {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = function()
        local c = require("config.colors")
        return {
            flavour = "mocha",
            transparent_background = true,
            float = { transparent = true, solid = false },
            term_colors = true,
            auto_integrations = true,
            color_overrides = {
                mocha = {
                    base = c.bg,
                    mantle = c.bg,
                    crust = c.bg,
                    surface0 = c.surface,
                    surface1 = c.raised,
                    surface2 = c.muted,
                    overlay0 = c.muted,
                    overlay1 = c.subtext,
                    overlay2 = c.subtext,
                    subtext0 = c.subtext,
                    subtext1 = c.fg,
                    text = c.fg,
                    rosewater = c.accent,
                    flamingo = c.accent,
                    lavender = c.accent,
                    pink = c.magenta,
                    mauve = c.magenta,
                    red = c.red,
                    maroon = c.red,
                    peach = c.orange,
                    yellow = c.yellow,
                    green = c.green,
                    teal = c.teal,
                    sky = c.teal,
                    sapphire = c.teal,
                    blue = c.blue,
                },
            },
            custom_highlights = function()
                local bold = { "bold" }
                return {
                    CursorLine = { bg = c.surface },
                    CursorLineNr = { fg = c.accent, style = bold },
                    LineNr = { fg = c.muted },
                    WinSeparator = { fg = c.muted },
                    FloatBorder = { fg = c.muted },
                    FloatTitle = { fg = c.accent, style = bold },
                    Pmenu = { bg = c.surface, fg = c.fg },
                    PmenuSel = { bg = c.raised, fg = c.accent, style = bold },

                    TelescopeBorder = { fg = c.muted },
                    TelescopePromptBorder = { fg = c.muted },
                    TelescopeResultsBorder = { fg = c.muted },
                    TelescopePreviewBorder = { fg = c.muted },
                    TelescopeTitle = { fg = c.accent, style = bold },
                    TelescopePromptTitle = { fg = c.accent, style = bold },
                    TelescopeResultsTitle = { fg = c.accent, style = bold },
                    TelescopePreviewTitle = { fg = c.accent, style = bold },
                    TelescopePromptPrefix = { fg = c.accent },
                    TelescopeSelection = { bg = c.surface, fg = c.accent, style = bold },
                    TelescopeSelectionCaret = { bg = c.surface, fg = c.accent },
                    TelescopeMatching = { fg = c.blue, style = bold },

                    -- Grey folders, like the Papirus folders in Thunar.
                    NeoTreeDirectoryIcon = { fg = c.subtext },
                    NeoTreeDirectoryName = { fg = c.fg },
                    NeoTreeRootName = { fg = c.accent, style = bold },
                    NeoTreeWinSeparator = { fg = c.muted },
                    NeoTreeIndentMarker = { fg = c.raised },

                    SnacksDashboardHeader = { fg = c.accent },
                    SnacksDashboardIcon = { fg = c.subtext },
                    SnacksDashboardKey = { fg = c.accent, style = bold },
                    SnacksDashboardDesc = { fg = c.fg },
                    SnacksDashboardFooter = { fg = c.muted },
                    SnacksDashboardSpecial = { fg = c.subtext },

                    BlinkCmpMenu = { bg = "NONE" },
                    BlinkCmpMenuBorder = { fg = c.muted },
                    BlinkCmpDocBorder = { fg = c.muted },
                    BlinkCmpSignatureHelpBorder = { fg = c.muted },
                }
            end,
        }
    end,
    config = function(_, opts)
        require("catppuccin").setup(opts)
        vim.cmd.colorscheme("catppuccin")
    end,
}
