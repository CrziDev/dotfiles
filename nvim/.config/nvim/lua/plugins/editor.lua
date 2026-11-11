return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        lazy = false, -- neo-tree lazy-loads itself
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        keys = {
            { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "File tree" },
        },
        opts = {
            close_if_last_window = true,
            popup_border_style = "rounded",
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        tag = "v0.2.0",
        cmd = "Telescope",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
            {
                "<leader>fd",
                function()
                    require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
                end,
                desc = "Find config files",
            },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    prompt_prefix = " ❯ ",
                    selection_caret = "  ",
                    entry_prefix = "  ",
                    sorting_strategy = "ascending",
                    layout_config = { prompt_position = "top" },
                    file_ignore_patterns = { "^%.git/", "/%.git/" },
                },
                pickers = {
                    find_files = { hidden = true },
                },
            })
            pcall(telescope.load_extension, "fzf")
        end,
    },
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<leader>t", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
            { [[<C-\>]], desc = "Toggle terminal" },
        },
        opts = {
            size = 20,
            -- <C-\> works from any mode. <leader>t (above) is normal mode only,
            -- so typing " t" in insert mode doesn't open a terminal.
            open_mapping = [[<C-\>]],
            direction = "horizontal",
            shade_terminals = false, -- keep the transparent background
        },
    },
}
