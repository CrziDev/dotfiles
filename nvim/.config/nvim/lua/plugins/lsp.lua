return {
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            { "mason-org/mason.nvim", opts = { ui = { border = "rounded" } } },
            "neovim/nvim-lspconfig",
        },
        -- automatic_enable starts every server installed through :Mason
        -- (gopls, intelephense, ts_ls, ... are already there).
        opts = {
            ensure_installed = { "lua_ls", "rust_analyzer" },
            automatic_enable = true,
        },
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
}
