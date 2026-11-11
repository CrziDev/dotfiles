return {
    { "lewis6991/gitsigns.nvim" },
    { "tpope/vim-fugitive" },
    {
        "kdheepak/lazygit.nvim",
        cmd = { "LazyGit" },
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
        },
    },
}
