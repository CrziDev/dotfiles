-- Mono statusline in the style of the waybar: no pills, no separators,
-- the mode in bold text colored per mode.
local function slate_theme()
    local c = require("config.colors")
    local function mode(color)
        return {
            a = { fg = color, bg = "NONE", gui = "bold" },
            b = { fg = c.fg, bg = "NONE" },
            c = { fg = c.subtext, bg = "NONE" },
        }
    end
    return {
        normal = mode(c.accent),
        insert = mode(c.green),
        visual = mode(c.magenta),
        replace = mode(c.red),
        command = mode(c.yellow),
        terminal = mode(c.teal),
        inactive = mode(c.muted),
    }
end

return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = function()
            local lazy_status = require("lazy.status")
            return {
                options = {
                    theme = slate_theme(),
                    globalstatus = true,
                    component_separators = "",
                    section_separators = "",
                    disabled_filetypes = { statusline = { "snacks_dashboard" } },
                    -- Keep showing the file while a picker or the tree has focus.
                    ignore_focus = { "TelescopePrompt", "neo-tree" },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff" },
                    lualine_c = {
                        { "filename", path = 1, symbols = { modified = " ●", readonly = " ", unnamed = "[No Name]" } },
                        "diagnostics",
                    },
                    lualine_x = {
                        {
                            lazy_status.updates,
                            cond = lazy_status.has_updates,
                            color = { fg = require("config.colors").yellow },
                        },
                        "filetype",
                    },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            }
        end,
    },
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            dashboard = { enabled = true },
        },
    },
}
