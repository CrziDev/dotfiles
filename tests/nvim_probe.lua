-- Used by `tests/check.sh nvim`: starts the real config headless and prints key=value facts.
vim.defer_fn(function()
    local facts = {}
    local function add(k, v) table.insert(facts, k .. "=" .. tostring(v)) end
    local ok, err = pcall(function()
        require("lazy").load({ plugins = { "toggleterm.nvim", "telescope.nvim" } })
        add("colors", vim.g.colors_name)
        add("normal_bg", vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
        for _, lang in ipairs({ "lua", "go", "php" }) do
            add("parser_" .. lang, vim.treesitter.language.add(lang) == true)
        end
        add("insert_leader_t", vim.fn.maparg(" t", "i") == "" and "unmapped" or "mapped")
        add("fzf", package.loaded.fzf_lib ~= nil)
    end)
    if not ok then add("probe_error", err) end
    local msgs = vim.api.nvim_exec2("messages", { output = true }).output
    add("errors", msgs:find("E%d+:") ~= nil or msgs:find("[Ee]rror") ~= nil)
    io.stdout:write(table.concat(facts, "\n") .. "\n")
    vim.cmd("qa!")
end, 1500)
