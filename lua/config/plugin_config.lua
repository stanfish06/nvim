local is_vscode = vim.g.vscode
-- fzf
-- git clone --depth 1 https://github.com/ibhagwan/fzf-lua.git ~/.config/nvim/pack/plugins/start/fzf-lua
local ok, fzf = pcall(require, "fzf-lua")
if ok and not is_vscode then
    fzf.setup({
        files = {
            rg_opts = [[--color=never --hidden --files -g "!.git" -g "!.jj"]],
            hidden = true,
            actions = {
                ["ctrl-alt-h"] = FzfLua.actions.toggle_hidden,
            },
        },
        grep = {
            rg_opts = table.concat({
                "--hidden",
                "--column",
                "--line-number",
                "--no-heading",
                "--color=always",
                "--smart-case",
                "--max-columns=4096 -e",
            }, " "),
            hidden = true,
            actions = {
                ["ctrl-alt-h"] = FzfLua.actions.toggle_hidden,
            },
        },
    })
    vim.keymap.set("n", "<leader><leader>", fzf.files)
    vim.keymap.set("n", "<leader>/", fzf.live_grep)
    vim.keymap.set("n", "<leader>sl", fzf.lines)
    vim.keymap.set("n", "<leader>sb", fzf.buffers)
end

-- sneaks
-- git clone --depth 1 https://github.com/justinmk/vim-sneak ~/.config/nvim/pack/plugins/start/vim-sneak

-- lsp
-- git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
-- after v12, neovim will have built-in package manager
-- lua
if not is_vscode then
    vim.lsp.config["luals"] = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
        settings = {
            Lua = {
                runtime = {
                    version = "LuaJIT",
                },
            },
        },
    }
    -- brew install lua-language-server
    vim.lsp.enable("luals")
    -- uv tool install pyright
    vim.lsp.enable("pyright")
    -- install per project
    vim.lsp.enable("pyrefly")
    -- install using system package manager
    vim.lsp.enable("clangd")
    -- npm instal -g typescript-language-server
    vim.lsp.enable("ts_ls")
    -- rust
    vim.lsp.enable("rust_analyzer")
    -- swift
    vim.lsp.config["sourcekit"] = {
        cmd = { "sourcekit-lsp" },
        root_markers = { "Package.swift", "compilation_commands.json", ".git" },
    }
    vim.lsp.enable("sourcekit")
end

-- conform (formatting)
local conform_ok, conform = pcall(require, "conform")
if conform_ok and not is_vscode then
    conform.setup({
        default_format_opts = {
            lsp_format = "fallback",
        },
        formatters_by_ft = {
            lua = { "stylua" },
            python = { "ruff_format" },
            javascript = { "prettier" },
            typescript = { "prettier" },
        },
    })
    vim.keymap.set("n", "<leader>lf", function()
        conform.format()
    end, { desc = "Format buffer" })
    vim.keymap.set("v", "<leader>lf", function()
        conform.format()
    end, { desc = "Format selection" })
end

-- fff
vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == 'fff.nvim' and (kind == 'install' or kind == 'update') then
            if not ev.data.active then
                vim.cmd.packadd('fff.nvim')
            end
            require('fff.download').download_or_build_binary()
        end
    end,
})
vim.g.fff = {
    lazy_sync = true,
    debug = {
        enabled = true,
        show_scores = true,
    },
}
vim.keymap.set(
    'n',
    'ff',
    function() require('fff').find_files() end,
    { desc = 'fff files' }
)
-- you can toggle between grep, fuzzy grep, regex grep with shift+tab after launching fff grep
vim.keymap.set(
    'n',
    'fg',
    function() require('fff').live_grep() end,
    { desc = 'fff grep' }
)
