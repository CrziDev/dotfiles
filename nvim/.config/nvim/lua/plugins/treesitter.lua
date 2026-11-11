-- nvim-treesitter `main`: it installs parsers, Neovim does the highlighting.
-- Installing parsers needs tree-sitter-cli (pacman -S tree-sitter-cli).
local parsers = {
    "bash", "css", "diff", "gitcommit", "go", "gomod", "html", "javascript",
    "json", "lua", "markdown", "markdown_inline", "php", "php_only", "python",
    "query", "rust", "sql", "tsx", "typescript", "vim", "vimdoc", "vue", "yaml",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        if vim.fn.executable("tree-sitter") == 1 then
            require("nvim-treesitter").install(parsers)
        end
        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
            callback = function(args)
                pcall(vim.treesitter.start, args.buf)
            end,
        })
    end,
}
