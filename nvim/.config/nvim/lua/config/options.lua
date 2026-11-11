local o = vim.o

o.number = true
o.relativenumber = true

o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4

o.cursorline = true
o.ignorecase = true
o.smartcase = true
o.breakindent = true
o.showmode = false -- lualine shows the mode
o.undofile = true
o.signcolumn = "yes"
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.scrolloff = 10
o.confirm = true
o.laststatus = 3 -- one statusline for all windows
o.ruler = false -- lualine shows the position
o.fillchars = "eob: " -- no ~ after the end of the buffer

vim.opt.diffopt:remove("linematch:40")

-- Deferred: the clipboard provider is slow to start.
vim.schedule(function()
    o.clipboard = "unnamedplus"
end)

vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = { border = "rounded" },
})
