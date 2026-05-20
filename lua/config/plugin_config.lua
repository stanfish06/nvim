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
                ["ctrl-alt-h"] = fzf.actions.toggle_hidden,
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
                ["ctrl-alt-h"] = fzf.actions.toggle_hidden,
            },
        },
    })
    vim.keymap.set("n", "<leader><leader>", fzf.files)
    vim.keymap.set("n", "<leader>/", fzf.live_grep)
    vim.keymap.set("n", "<leader>sl", fzf.lines)
    vim.keymap.set("n", "<leader>sb", fzf.buffers)
    vim.keymap.set("n", "<leader>sm", fzf.marks)
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
    -- install via uv: uv tool install pyrefly, then pyrefly init inside project folder (will transfer configs from pyright if available)
    -- pyrefly seems capable of showing more type issues as far as I can tell
    vim.lsp.enable("pyrefly")
    -- install using system package manager
    vim.lsp.enable("clangd")
    -- npm instal -g typescript-language-server
    vim.lsp.enable("ts_ls")
    -- rust
    vim.lsp.enable("rust_analyzer")
    -- go
    vim.lsp.enable("gopls")
    -- swift
    vim.lsp.config["sourcekit"] = {
        cmd = { "sourcekit-lsp" },
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_markers = { "Package.swift", "compile_commands.json", ".git" },
    }
    vim.lsp.enable("sourcekit")
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method("textDocument/completion") then
                pcall(function()
                    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
                end)
            end
            local opts = { buffer = ev.buf }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        end,
    })
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
local fff_ok, _ = pcall(function()
    vim.api.nvim_create_autocmd("PackChanged", {
        callback = function(ev)
            local name, kind = ev.data.spec.name, ev.data.kind
            if name == "fff.nvim" and (kind == "install" or kind == "update") then
                if not ev.data.active then
                    vim.cmd.packadd("fff.nvim")
                end
                require("fff.download").download_or_build_binary()
            end
        end,
    })
end)
if fff_ok then
    vim.g.fff = {
        lazy_sync = true,
        debug = {
            enabled = true,
            show_scores = true,
        },
    }
    if not is_vscode then
        vim.keymap.set("n", "ff", function()
            require("fff").find_files()
        end, { desc = "fff files" })
        -- you can toggle between grep, fuzzy grep, regex grep with shift+tab after launching fff grep
        vim.keymap.set("n", "fg", function()
            require("fff").live_grep()
        end, { desc = "fff grep" })
    end
end

-- gitsigns
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
if gitsigns_ok and not is_vscode then
    gitsigns.setup()
end

-- treesitter textobjects (move keymaps for function/class navigation)
local tso_ok, tso = pcall(require, "nvim-treesitter-textobjects")
if tso_ok and not is_vscode then
    tso.setup({
        move = {
            set_jumps = true,
        },
    })
    local move = require("nvim-treesitter-textobjects.move")
    vim.keymap.set({ "n", "x", "o" }, "]f", function()
        move.goto_next_start("@function.outer", "textobjects")
    end, { desc = "Next function start" })
    vim.keymap.set({ "n", "x", "o" }, "[f", function()
        move.goto_previous_start("@function.outer", "textobjects")
    end, { desc = "Prev function start" })
    vim.keymap.set({ "n", "x", "o" }, "]c", function()
        move.goto_next_start("@class.outer", "textobjects")
    end, { desc = "Next class start" })
    vim.keymap.set({ "n", "x", "o" }, "[c", function()
        move.goto_previous_start("@class.outer", "textobjects")
    end, { desc = "Prev class start" })
    vim.keymap.set({ "n", "x", "o" }, "]F", function()
        move.goto_next_end("@function.outer", "textobjects")
    end, { desc = "Next function end" })
    vim.keymap.set({ "n", "x", "o" }, "[F", function()
        move.goto_previous_end("@function.outer", "textobjects")
    end, { desc = "Prev function end" })
    vim.keymap.set({ "n", "x", "o" }, "]C", function()
        move.goto_next_end("@class.outer", "textobjects")
    end, { desc = "Next class end" })
    vim.keymap.set({ "n", "x", "o" }, "[C", function()
        move.goto_previous_end("@class.outer", "textobjects")
    end, { desc = "Prev class end" })
end

-- obsidian
local obsidian_ok, obsidian = pcall(require, "obsidian")
if obsidian_ok then
    obsidian.setup({
        workspaces = {
            {
                name = "notes",
                path = "~/Git/notes",
            },
        },
        daily_notes = {
            folder = "journal",
        },
    })
end
