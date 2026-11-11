return {
    "saghen/blink.cmp",
    version = "1.*", -- release tag = prebuilt fuzzy-matcher binary
    dependencies = { "rafamadriz/friendly-snippets" },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        -- C-y accept, C-space menu/docs, C-n/C-p select, C-e hide, C-k signature
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        completion = {
            menu = { border = "rounded" },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 300,
                window = { border = "rounded" },
            },
        },
        signature = { enabled = true, window = { border = "rounded" } },
        sources = {
            default = { "lazydev", "lsp", "path", "snippets", "buffer" },
            providers = {
                lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
            },
        },
        fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
}
