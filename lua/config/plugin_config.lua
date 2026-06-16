local is_vscode = vim.g.vscode
-- fzf
-- git clone --depth 1 https://github.com/ibhagwan/fzf-lua.git ~/.config/nvim/pack/plugins/start/fzf-lua
local ok, fzf = pcall(require, "fzf-lua")
if ok and not is_vscode then
    -- fzf picker for vim.ui.select
    fzf.register_ui_select()
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
    vim.keymap.set("n", "<leader>st", fzf.tabs)
    vim.keymap.set("n", "<leader>sm", fzf.marks)
    vim.keymap.set("n", "<leader>gc", fzf.git_commits, { desc = "Git commits (repo)" })
    vim.keymap.set("n", "<leader>gb", fzf.git_bcommits, { desc = "Git commits (buffer)" })
    vim.keymap.set("n", "<leader>gB", fzf.git_branches, { desc = "Git branches" })
    vim.keymap.set("n", "<leader>gs", fzf.git_status, { desc = "Git status" })
    vim.keymap.set("n", "<leader>lr", fzf.lsp_references, { desc = "LSP references (fzf)" })
    vim.keymap.set("n", "<leader>ls", fzf.lsp_document_symbols, { desc = "LSP document symbols" })
    vim.keymap.set("n", "<leader>lS", fzf.lsp_live_workspace_symbols, { desc = "LSP workspace symbols" })
end

-- sneaks — intentionally remaps s/S to 2-char forward/backward seek motion
-- git clone --depth 1 https://github.com/justinmk/vim-sneak ~/.config/nvim/pack/plugins/start/vim-sneak
-- vim-sneak is a Vimscript plugin: plugin/sneak.vim sets g:loaded_sneak_plugin at startup. local sneaks_ok = vim.g.loaded_sneak_plugin ~= nil
if sneaks_ok then
    vim.g["sneak#label"] = 1 -- label mode: shows jump targets (EasyMotion-style)
    vim.g["sneak#use_ic_scs"] = 1 -- respect smartcase (so type P will specifically match P)
    -- these have match highlight
    vim.keymap.set({ "n", "x", "o" }, "f", "<Plug>Sneak_f")
    vim.keymap.set({ "n", "x", "o" }, "F", "<Plug>Sneak_F")
    -- t means stop 1 char before match
    vim.keymap.set({ "n", "x", "o" }, "t", "<Plug>Sneak_t")
    vim.keymap.set({ "n", "x", "o" }, "T", "<Plug>Sneak_T")
end

-- lsp
-- git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
-- after v12, neovim will have built-in package manager
-- lua
if not is_vscode then
    vim.lsp.config("luals", {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
        settings = {
            Lua = {
                runtime = {
                    version = "LuaJIT",
                },
            },
        },
    })
    -- brew install lua-language-server
    vim.lsp.enable("luals")
    -- uv tool install pyright
    vim.lsp.config("pyright", {
        settings = {
            python = {
                analysis = {
                    diagnosticMode = "workspace",
                },
            },
        },
    })
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
    vim.lsp.config("sourcekit", {
        cmd = { "sourcekit-lsp" },
        filetypes = { "swift", "objective-c", "objective-cpp" },
        root_markers = { "Package.swift", "compile_commands.json", ".git" },
    })
    vim.lsp.enable("sourcekit")
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method("textDocument/completion") then
                pcall(function()
                    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
                end)
            end
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf })
            vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "LSP code action" })
        end,
    })
    vim.api.nvim_create_user_command("LspToggle", function(opts)
        local name = opts.args
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = name })) do
            if vim.fn.has("nvim-0.12") == 1 then
                client:stop()
            else
                vim.lsp.stop_client(client.id)
            end
            return
        end
        vim.lsp.enable(name)
    end, {
        nargs = 1,
        complete = function()
            return vim.tbl_map(function(c)
                return c.name
            end, vim.lsp.get_clients({ bufnr = 0 }))
        end,
        desc = "Stop or re-enable a named LSP client for the current buffer",
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
            javascriptreact = { "prettier" },
            typescript = { "prettier" },
            typescriptreact = { "prettier" },
        },
    })
    -- conform derives the range from the live selection in visual mode;
    -- the '< '> marks are stale until visual mode is left, so don't use them here
    vim.keymap.set({ "n", "v" }, "<leader>lf", function()
        conform.format()
    end, { desc = "Format buffer or selection" })
end

-- nvim-lint (async linting: ruff for Python, luacheck for Lua, shellcheck for Shell)
local lint_ok, lint = pcall(require, "lint")
if lint_ok and not is_vscode then
    lint.linters_by_ft = {
        python = { "ruff" },
        lua = { "luacheck" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
    }
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufWritePost", "InsertLeave" }, {
        callback = function()
            lint.try_lint()
        end,
    })
end

-- fff
-- rebuild the rust binary whenever vim.pack installs/updates fff.nvim
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
vim.g.fff = {
    lazy_sync = true,
}
if not is_vscode then
    local function fff_call(fn)
        return function()
            local fff_ok, fff = pcall(require, "fff")
            if not fff_ok then
                vim.notify("fff.nvim is not installed (run :SyncPkgs)", vim.log.levels.WARN)
                return
            end
            fff[fn]()
        end
    end
    vim.keymap.set("n", "<leader>ff", fff_call("find_files"), { desc = "fff files" })
    -- you can toggle between grep, fuzzy grep, regex grep with shift+tab after launching fff grep
    vim.keymap.set("n", "<leader>fg", fff_call("live_grep"), { desc = "fff grep" })
end

-- diffview
local diffview_ok, diffview = pcall(require, "diffview")
if diffview_ok and not is_vscode then
    diffview.setup({
        use_icons = false,
    })
    vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Git diff (working tree)" })
    vim.keymap.set("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "Git file history" })
end

-- gitsigns
local gitsigns_ok, gitsigns = pcall(require, "gitsigns")
if gitsigns_ok and not is_vscode then
    gitsigns.setup()
end

-- git change navigation (]g / [g)
-- use native diff/hunk jump in diff view
-- use gitsigns diff/hunk jump in regular view
if not is_vscode then
    vim.keymap.set("n", "]g", function()
        if vim.wo.diff then
            vim.cmd("normal! " .. vim.v.count1 .. "]c")
        elseif gitsigns_ok then
            gitsigns.nav_hunk("next")
        end
    end, { desc = "Next git change (hunk / diff)" })
    vim.keymap.set("n", "[g", function()
        if vim.wo.diff then
            vim.cmd("normal! " .. vim.v.count1 .. "[c")
        elseif gitsigns_ok then
            gitsigns.nav_hunk("prev")
        end
    end, { desc = "Prev git change (hunk / diff)" })
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
        legacy_commands = false, -- use :Obsidian <subcommand>; legacy :Obsidian* commands warn at startup
        workspaces = {
            {
                name = "notes",
                path = "~/Git/notes",
            },
            -- NOTE: do not add a "~" catch-all workspace. obsidian.nvim roots its
            -- ripgrep backlink/reference scans at the matched vault, so a home-dir
            -- vault makes rg crawl all of ~/Library/Containers on macOS, spamming
            -- EINTR (os error 4) errors. Markdown outside a vault falls back to the
            -- first workspace (notes) instead.
        },
        daily_notes = {
            folder = "journal",
        },
    })
end

-- snacks
local snacks_ok, snacks = pcall(require, "snacks")
if snacks_ok and not is_vscode then
    snacks.setup({
        scroll = { enabled = true },
        indent = {
            enabled = true,
            scope = {
                enabled = true,
            },
            chunk = {
                enabled = true, -- scope as chunk
                char = {
                    arrow = "➤",
                },
            },
        },
        notifier = {
            enabled = true,
            timeout = 3000,
        },
    })
end

-- noice (better ui)
local noice_ok, noice = pcall(require, "noice")
-- experimental options
-- BUG: restart drops ui2
-- noice does not work well with neovim ui2 2026-06-15
-- this file got loaded after options.lua so this should disable ui2
if not vim.g.vscode then
    local ui2_ok, ui2 = pcall(require, "vim._core.ui2")
    if not noice_ok then
        if ui2_ok then
            -- {} required: calling enable() without args is a documented Neovim bug (neovim/neovim#38594)
            pcall(ui2.enable, {})
            vim.notify("nvim ui2 enabled", vim.log.levels.INFO)
        else
            vim.notify("nvim ui2 disabled (could be old nvim or api shift, check options.lua)", vim.log.levels.WARN)
        end
    else
        vim.notify("use noice/nui ui layer", vim.log.levels.INFO)
    end
end
if noice_ok and not is_vscode then
    noice.setup({
        presets = {
            bottom_search = true, -- use a classic bottom cmdline for search
            lsp_doc_border = false, -- add a border to hover docs and signature help
        },
        cmdline = {
            enabled = true,
            view = "cmdline_popup",
            format = {
                cmdline = { title = "  " },
            },
        },
        popupmenu = {
            enabled = true,
            backend = "nui",
            view = "popupmenu",
        },
        views = {
            cmdline_popup = {
                position = {
                    row = 5,
                    col = "50%",
                },
                size = {
                    width = 30,
                    height = "auto",
                },
                border = {
                    style = "single",
                },
            },
            popupmenu = {
                relative = "editor",
                position = {
                    row = 8,
                    col = "50%",
                },
                size = {
                    width = 30,
                    height = 5,
                },
                border = {
                    style = "single",
                },
            },
        },
    })
end
