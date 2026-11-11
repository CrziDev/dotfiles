local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("user-config", { clear = true })

autocmd("TextYankPost", {
    group = group,
    desc = "Highlight when yanking (copying) text",
    callback = function()
        vim.hl.on_yank()
    end,
})

-- Format Go files on save with gopls. Skipped when gopls isn't attached, and a
-- syntax error just leaves the buffer as it is.
autocmd("BufWritePre", {
    group = group,
    pattern = "*.go",
    callback = function(args)
        if #vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/formatting" }) > 0 then
            vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 2000 })
        end
    end,
})

autocmd("LspAttach", {
    group = group,
    callback = function(args)
        vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
        end, { buffer = args.buf, desc = "Hover" })
    end,
})
