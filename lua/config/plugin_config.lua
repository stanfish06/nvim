local is_vscode = vim.g.vscode

-- mini.icons (icon provider; mocks nvim-web-devicons so filetree.lua/statuscolumn.lua
-- keep working against the devicons API without changes)
local mini_icons_ok, mini_icons = pcall(require, "mini.icons")
if mini_icons_ok then
    mini_icons.setup()
    mini_icons.mock_nvim_web_devicons()
end

-- mini.pairs (auto-close brackets/quotes; complements the <CR> auto-indent
-- keymap in options.lua which handles the reactive side of bracket editing)
local mini_pairs_ok, mini_pairs = pcall(require, "mini.pairs")
if mini_pairs_ok and not is_vscode then
    mini_pairs.setup()
end

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
-- vim-sneak is a Vimscript plugin: plugin/sneak.vim sets g:loaded_sneak_plugin at startup
local sneaks_ok = vim.g.loaded_sneak_plugin ~= nil
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

-- cmp (blink.cmp v2: native fuzzy matcher via build/download; see :h blink-cmp-installation)
local blink_ok, blink = pcall(require, "blink.cmp")
if blink_ok and not is_vscode then
    -- Build once when the rust lib is missing (no-op once target/lib is present).
    -- Prefer cargo build for unreleased main; download needs a release tag.
    if not blink.library_available() then
        local build_ok, build_err = pcall(function()
            blink.build():pwait()
        end)
        if not build_ok then
            vim.notify(
                "blink.cmp: failed to build fuzzy matcher (install rustc/cargo?): " .. tostring(build_err),
                vim.log.levels.WARN
            )
        end
    end
    blink.setup({
        keymap = { preset = "default" },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
        },
    })
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
            if vim.fn.has("nvim-0.11") == 1 then
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
            go = { "gofmt" },
        },
    })
    local auto_format = false

    vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(ev)
            if auto_format then
                conform.format({ bufnr = ev.buf })
            end
        end,
    })

    -- conform derives the range from the live selection in visual mode;
    -- the '< '> marks are stale until visual mode is left, so don't use them here
    vim.keymap.set({ "n", "v" }, "<leader>lf", function()
        conform.format()
    end, { desc = "Format buffer or selection" })

    vim.keymap.set("n", "<leader>lF", function()
        auto_format = not auto_format
        vim.notify("Auto-format: " .. (auto_format and "ON" or "OFF"), vim.log.levels.INFO)
    end, { desc = "Toggle auto-format on save" })
end

-- nvim-lint (async linting: ruff for Python, luacheck for Lua, shellcheck for Shell)
local lint_ok, lint = pcall(require, "lint")
if lint_ok and not is_vscode then
    lint.linters_by_ft = {
        python = { "ruff" },
        -- lua = { "luacheck" }, luacheck looks pretty old
        sh = { "shellcheck" },
        bash = { "shellcheck" },
    }
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufWritePost", "InsertLeave" }, {
        callback = function()
            lint.try_lint()
        end,
    })
end

-- rebuild native binaries whenever vim.pack installs/updates rust-backed plugins
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if kind ~= "install" and kind ~= "update" then
            return
        end
        if name == "fff.nvim" then
            if not ev.data.active then
                vim.cmd.packadd("fff.nvim")
            end
            require("fff.download").download_or_build_binary()
        elseif name == "blink.cmp" then
            if not ev.data.active then
                vim.cmd.packadd("blink.cmp")
            end
            -- force rebuild on update so the fuzzy lib matches the new revision
            local ok, err = pcall(function()
                require("blink.cmp").build({ force = kind == "update" }):pwait()
            end)
            if not ok then
                vim.notify("blink.cmp: native build failed: " .. tostring(err), vim.log.levels.WARN)
            end
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

-- tiny-inline-diagnostic (compact inline diagnostics)
local tiny_diag_ok, tiny_diag = pcall(require, "tiny-inline-diagnostic")
if tiny_diag_ok and not is_vscode then
    tiny_diag.setup({
        preset = "modern",
        options = {
            multilines = true,
            show_source = {
                enabled = true,
                if_many = true,
            },
        },
    })
    vim.diagnostic.config({ virtual_text = false })
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

-- refactoring.nvim (treesitter-driven extract/inline helpers)
local refactoring_ok, refactoring = pcall(require, "refactoring")
if refactoring_ok and not is_vscode then
    refactoring.setup({})
    vim.keymap.set("x", "<leader>re", function()
        refactoring.refactor("Extract Function")
    end, { desc = "Refactor extract function" })
    vim.keymap.set("x", "<leader>rf", function()
        refactoring.refactor("Extract Function To File")
    end, { desc = "Refactor extract function to file" })
    vim.keymap.set("x", "<leader>rv", function()
        refactoring.refactor("Extract Variable")
    end, { desc = "Refactor extract variable" })
    vim.keymap.set({ "n", "x" }, "<leader>ri", function()
        refactoring.refactor("Inline Variable")
    end, { desc = "Refactor inline variable" })
    vim.keymap.set("n", "<leader>rI", function()
        refactoring.refactor("Inline Function")
    end, { desc = "Refactor inline function" })
    vim.keymap.set("n", "<leader>rb", function()
        refactoring.refactor("Extract Block")
    end, { desc = "Refactor extract block" })
    vim.keymap.set("n", "<leader>rB", function()
        refactoring.refactor("Extract Block To File")
    end, { desc = "Refactor extract block to file" })
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

-- render-markdown (in-buffer markdown rendering)
local render_markdown_ok, render_markdown = pcall(require, "render-markdown")
if render_markdown_ok and not is_vscode then
    render_markdown.setup({
        file_types = { "markdown" },
        completions = { lsp = { enabled = true } },
        latex = {
            enabled = true,
            converter = { "utftex", "latex2text" },
            inline = true,
            block = true,
            position = "center",
        },
    })
    vim.keymap.set("n", "<leader>mr", "<cmd>RenderMarkdown toggle<CR>", { desc = "Toggle markdown rendering" })
end

-- obsidian
local obsidian_ok, obsidian = pcall(require, "obsidian")
if obsidian_ok then
    -- obsidian.nvim needs at least one existing vault; create the notes folder if missing
    local notes_path = vim.fn.expand("~/Git/notes")
    if vim.fn.isdirectory(notes_path) == 0 then
        vim.fn.mkdir(notes_path, "p")
    end
    obsidian.setup({
        legacy_commands = false, -- use :Obsidian <subcommand>; legacy :Obsidian* commands warn at startup
        ui = { enable = false },
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

-- quicker (improve quickfix ui)
local quicker_ok, quicker = pcall(require, "quicker")
if quicker_ok then
    quicker.setup()
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
                -- solid arrow may cause overlap in some terminals
                -- char = {
                --     arrow = "➤",
                -- },
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
