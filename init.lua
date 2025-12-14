
vim.o.relativenumber = true

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4

vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.breakindent = true
vim.o.showmode = false
vim.o.undofile = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<leader>n', '<cmd>Neotree toggle<CR>' )

vim.schedule(function()
    vim.o.clipboard = 'unnamedplus'
end)

vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
	vim.hl.on_yank()
    end,
})

-- Install Lazy --

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
	vim.api.nvim_echo({
	    { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
	    { out, "WarningMsg" },
	    { "\nPress any key to exit..." },
	}, true, {})
	vim.fn.getchar()
	os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{
			'nvim-lualine/lualine.nvim',
			dependencies = { 'nvim-tree/nvim-web-devicons' },
			config = function()
				require('lualine').setup {
					options = {
						icons_enabled = true,
						theme = 'nord',
						component_separators = { left = '', right = ''},
						section_separators = { left = '', right = ''},
						disabled_filetypes = {
							statusline = {},
							winbar = {},
						},
						ignore_focus = {},
						always_divide_middle = true,
						always_show_tabline = true,
						globalstatus = false,
						refresh = {
							statusline = 1000,
							tabline = 1000,
							winbar = 1000,
							refresh_time = 16, -- ~60fps
							events = {
								'WinEnter',
								'BufEnter',
								'BufWritePost',
								'SessionLoadPost',
								'FileChangedShellPost',
								'VimResized',
								'Filetype',
								'CursorMoved',
								'CursorMovedI',
								'ModeChanged',
							},
						}
					},
					sections = {
						lualine_a = {'mode'},
						lualine_b = {'branch', 'diff', 'diagnostics'},
						lualine_c = {'filename'},
						lualine_x = {'encoding', 'fileformat', 'filetype'},
						lualine_y = {'progress'},
						lualine_z = {'location'}
					},
					inactive_sections = {
						lualine_a = {},
						lualine_b = {},
						lualine_c = {'filename'},
						lualine_x = {'location'},
						lualine_y = {},
						lualine_z = {}
					},
					tabline = {},
					winbar = {},
					inactive_winbar = {},
					extensions = {}
				}    end

			},
			{
				"nvim-neo-tree/neo-tree.nvim",
				branch = "v3.x",
				dependencies = {
					"nvim-lua/plenary.nvim",
					"MunifTanjim/nui.nvim",
					"nvim-tree/nvim-web-devicons", -- optional, but recommended
				},
				lazy = false, -- neo-tree will lazily load itself
			},
			{
				'akinsho/toggleterm.nvim', 
				version = "*", 
				config = true , 
				opts = {
					size = 20, -- Default size for splits
					open_mapping = [[<leader>t]], -- Default key to toggle
					direction = "horizontal", -- Default direction
					-- shade_terminals = false, -- Example option
				},
			},
			{
				'nvim-telescope/telescope-fzf-native.nvim', 
				build = 'make'
			},
			{
				'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
				dependencies = { 'nvim-lua/plenary.nvim' },
				config = function() 
					require('telescope').setup{
						pickers = {
							find_files = {
								hidden = true
							}
						}
					}
					local builtin = require('telescope.builtin')

					vim.keymap.set('n', '<leader>fd', 
					function() 
						builtin.find_files({
							cwd = vim.fn.stdpath("config"),
							hidden = true
						})
					end,{ desc = 'Telescope find files' })

					vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
					vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
					vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
					vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
				end
			},
            {
                "mason-org/mason-lspconfig.nvim",
                dependencies = {
                    { "mason-org/mason.nvim", opts = {} },
                    "neovim/nvim-lspconfig",  
                },
                opts = {
                    ensure_installed = { "lua_ls", "rust_analyzer" },
                    automatic_enable = true,
                },
                config = function(_, opts)
                    require("mason").setup()
                    require("mason-lspconfig").setup(opts)
                    vim.diagnostic.config({ virtual_text = true })
                end,
            },
        },
        install = { colorscheme = { "habamax" } },
        checker = { enabled = true },
    })
