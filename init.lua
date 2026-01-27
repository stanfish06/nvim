local mod_async = require("lib.async")

-- note: opt is a "smarter" version of o. In simple assignments, they are inter-changeable
-- line number
vim.o.number = true
vim.o.relativenumber = true

-- note
-- gt and gT are used to navigate between tabs
-- keymap
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>d", vim.diagnostic.setloclist, { desc = "[D]iagnostic list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<c-/>", "<cmd>botright 15split | terminal<CR>")
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>")
vim.keymap.set("n", "\\", "<cmd>Explore<CR>")
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("n", "H", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "L", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>e", ":edit **/*")
vim.keymap.set("n", "<leader>f", ":find **/*")
vim.cmd.cnoreabbrev("vimgrep", "vimgrep /pattern/gj **/*")
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "[O]pen quickfix list" })
vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "[C]lose quickfix list" })
-- completeion
-- c-n for keyword completeion
-- c-e to cancel completion
vim.keymap.set("i", "<c-space>", "<c-x><c-o>", { desc = "LSP completion" })
vim.keymap.set("i", "<c-l>", "<c-x><c-l>", { desc = "Line completion" })
vim.keymap.set("i", "<c-f>", "<c-x><c-f>", { desc = "File completion" })
-- lsp
vim.keymap.set("n", "gd", ":lua vim.lsp.buf.definition()<CR>")
vim.keymap.set("n", "gr", ":lua vim.lsp.buf.references()<CR>")

-- misc settings
vim.o.showmode = true
vim.o.autoread = true
vim.o.ignorecase = true
vim.o.expandtab = true
vim.o.smartcase = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.history = 500
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.o.undofile = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.inccommand = "split"
vim.opt.termguicolors = true
vim.g.netrw_keepdir = 0
vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy" }
vim.opt.signcolumn = "yes"
vim.o.scrolloff = 8

-- mouse
vim.o.mousescroll = "ver:25,hor:6"
vim.o.switchbuf = "usetab"
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"

-- wrapped line
vim.o.breakindent = true
vim.o.breakindentopt = "list:-1"
vim.o.linebreak = true

-- ui
vim.o.colorcolumn = "+1"
vim.o.list = true
vim.o.pumheight = 10 -- height limit for completion pop-up, useful for long list
vim.o.splitkeep = "screen"
vim.o.winborder = "single" -- makes hover window like lsp fancier with a border
vim.o.fillchars = "eob: ,fold:╌"
vim.o.listchars = "extends:…,nbsp:␣,precedes:…,tab:> "

-- folding
vim.o.foldlevel = 10
vim.o.foldmethod = "indent"
vim.o.foldnestmax = 10
vim.o.foldtext = ""

-- editing
vim.o.formatoptions = "rqnl1j"
vim.o.infercase = true
vim.o.spelloptions = "camel"
vim.o.virtualedit = "block"
vim.o.iskeyword = "@,48-57,_,192-255,-"
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]

-- clipboard
vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
end)

-- status
-- callback that runs every time after colorscheme changes to make sure statusline stay the same
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "#98C379", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#C678DD", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "#E5C07B", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeNormalAlt", { fg = "#98C379", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "StatusLineModeInsertAlt", { fg = "#C678DD", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "StatusLineModeVisualAlt", { fg = "#E5C07B", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "CursorInfo", { bg = "#B8C0E0", fg = "black" })
        vim.api.nvim_set_hl(0, "CursorInfoAlt", { fg = "#B8C0E0", bg = "#3E8FB0" })
        vim.api.nvim_set_hl(0, "File", { bg = "#3A3A3A", fg = "#ABEBE2" })
        vim.api.nvim_set_hl(0, "FileAlt", { fg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "FileType", { fg = "black", bg = "#3E8FB0" })
        vim.api.nvim_set_hl(0, "FileTypeAlt", { fg = "#3E8FB0" })
        vim.cmd("redrawstatus")
    end,
})

-- cursor
local function set_cursor_color()
    vim.api.nvim_set_hl(0, "myCursor", { fg = "#FFA500", bg = "#FFA500" })
    vim.api.nvim_set_hl(0, "myICursor", { fg = "#FFA500", bg = "#FFA500" })
end
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_cursor_color,
})
set_cursor_color()
vim.opt.guicursor = "n-v-c:block-myCursor,i-ci-ve:ver25-myICursor"
-- local SOLID_LEFT_ARROW = vim.fn.nr2char(0xe0b2)
-- local SOLID_RIGHT_ARROW = vim.fn.nr2char(0xe0b0)
local SOLID_LEFT_ARROW = "░▒▓" -- needs a nerd font
local SOLID_LEFT_ARROW_PART = "▓"
local SOLID_RIGHT_ARROW = "▓▒░"
local SOLID_RIGHT_ARROW_PART = "▓"
local function current_mode()
    local m = vim.fn.mode()
    local mode_map = {
        n = { text = "[N]", hl = "StatusLineModeNormal", hl_alt = "StatusLineModeNormalAlt" },
        i = { text = "[I]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
        v = { text = "[V]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        V = { text = "[VL]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        ["\22"] = { text = "[VB]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        R = { text = "[R]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
        c = { text = "[C]", hl = "StatusLineModeNormal", hl_alt = "StatusLineModeNormalAlt" },
        t = { text = "[T]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
    }
    local mode_info = mode_map[m] or { text = "[?]", hl = "StatusLineModeNormal" }
    return string.format("%%#%s#%s%%*", mode_info.hl_alt, SOLID_LEFT_ARROW_PART)
        .. string.format("%%#%s#%s%%*", mode_info.hl, mode_info.text)
        .. string.format("%%#%s#%s%%*", mode_info.hl_alt, SOLID_RIGHT_ARROW)
end

local filetype_icons = {
    lua = "",
    python = "",
    rust = "󱘗",
    c = "",
    go = "",
    javascript = "",
    typescript = "",
}
-- set to false if no nerd font
vim.g.have_nerd_font = true
local function current_filetype()
    local filetype = vim.bo.filetype
    local color = "%#FileType# "
    local color_alt = "%#FileTypeAlt#"
    if not vim.g.have_nerd_font then
        return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. "  " .. " "
    else
        local icon = filetype_icons[filetype]
        if icon == nil then
            icon = ""
        else
            icon = " " .. icon
        end
        return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. icon .. " "
    end
end

local function current_file()
    local root_path = vim.loop.cwd()
    local root_dir = root_path:match("[^/]+$")
    local home_path = vim.fn.expand("%:~")
    local overlap, _ = home_path:find(root_dir)
    local color = "%#File# "
    local color_alt = "%#FileAlt#"
    if home_path == "" then
        return color .. root_path:gsub(vim.env.HOME, "~") .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    elseif overlap then
        return color .. home_path:sub(overlap) .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    else
        return color .. home_path .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    end
end

local function current_cursor_info()
    local linenr = vim.api.nvim_win_get_cursor(0)[1]
    local colnr = vim.fn.col(".")
    local nlines = vim.api.nvim_buf_line_count(0)
    local percentage = 0
    if nlines > 0 then
        percentage = (linenr / nlines) * 100
    end
    return ""
        .. "%#CursorInfoAlt#"
        .. SOLID_LEFT_ARROW
        .. "%*"
        .. "%#CursorInfo# "
        .. string.format("%.1f", percentage)
        .. "%% "
        .. string.format("%d:%d ", linenr, colnr)
        .. "%#CursorInfoAlt#"
        .. SOLID_RIGHT_ARROW_PART
end

function StatusLine()
    return current_mode() .. current_file() .. current_filetype() .. current_cursor_info()
end
vim.opt.statusline = "%!v:lua.StatusLine()"

-- packages
local package_list = {
    ["fzf-lua"] = "https://github.com/ibhagwan/fzf-lua.git",
    ["nvim-lspconfig"] = "https://github.com/neovim/nvim-lspconfig",
    ["sneaks.vim"] = "https://github.com/justinmk/vim-sneak",
    ["nvim-treesitter"] = "https://github.com/nvim-treesitter/nvim-treesitter.git",
    ["conform.nvim"] = "https://github.com/stevearc/conform.nvim.git",
    ["dark-theme"] = "https://github.com/stanfish06/dark-theme.git",
    ["rose-pine"] = "https://github.com/rose-pine/neovim.git",
    ["tokyonight"] = "https://github.com/folke/tokyonight.nvim.git",
}
function sync_packages()
    mod_async
        .new(function()
            local package_dir = os.getenv("HOME") .. "/.config/nvim/pack/plugins/start/"
            print("Sync packages...")
            local jobs = {}
            for pkg_name, pkg_url in pairs(package_list) do
                local job = mod_async.new(function()
                    local full_path = package_dir .. pkg_name .. "/"
                    if vim.fn.isdirectory(full_path) == 1 then
                        print("Reinstall: " .. pkg_name .. "...")
                        vim.fn.delete(full_path, "rf")
                    else
                        print("Install: " .. pkg_name .. "...")
                    end
                    vim.system({
                        "git",
                        "clone",
                        "--depth",
                        "1",
                        "--quiet",
                        pkg_url,
                        full_path,
                    }):wait()
                    print("Synced: " .. pkg_name)
                end)
                table.insert(jobs, job)
            end
            for _, job in ipairs(jobs) do
                while job:running() do
                    mod_async.yield()
                end
            end
        end)
        :wait()
    print("Done!")
end
vim.api.nvim_create_user_command("SyncPkgs", sync_packages, {})

-- fzf
-- git clone --depth 1 https://github.com/ibhagwan/fzf-lua.git ~/.config/nvim/pack/plugins/start/fzf-lua
local ok, fzf = pcall(require, "fzf-lua")
if ok then
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
vim.lsp.enable("luals")
-- uv tool install pyright
vim.lsp.enable("pyright")
-- install per project
vim.lsp.enable("pyrefly")
-- install using system package manager
vim.lsp.enable("clangd")
-- npm instal -g typescript-language-server
vim.lsp.enable("ts_ls")

-- conform (formatting)
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
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

-- treesitter
-- git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/plugins/start/nvim-treestter
-- require tree-sitter-cli (do npm install -g tree-sitter-cli)
local ts_status, ts = pcall(require, "nvim-treesitter")
if ts_status then
    ts.install({
        "c",
        "python",
        "julia",
        "cpp",
        "bash",
        "lua",
        "vim",
        "vimdoc",
        "javascript",
        "markdown",
        "markdown_inline",
    })
end
local function is_ts_enabled()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr] ~= nil
end
function ts_highlight()
    if is_ts_enabled() then
        vim.treesitter.stop()
    else
        vim.treesitter.start()
    end
end
vim.api.nvim_create_user_command("TSBufToggle", ts_highlight, {})
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "*" },
    callback = function()
        local ok, err = pcall(vim.treesitter.start)
        if not ok then
            vim.cmd("syntax on")
        end
    end,
})

-- Auto-indent when press enter (e.g. if () {<CR>})
vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local col_cursor = vim.api.nvim_win_get_cursor(0)[2]

    local char_prev = line:sub(col_cursor, col_cursor)
    local char_next = line:sub(col_cursor + 1, col_cursor + 1)
    local char_neighbors = char_prev .. char_next
    if char_neighbors == "{}" or char_neighbors == "()" then
        return "<CR><Esc>O"
    end
    return "<CR>"
end, { expr = true, noremap = true })

-- color theme
-- git clone --depth 1 https://github.com/stanfish06/dark-theme.git ~/.config/nvim/pack/plugins/start/dark-theme
-- vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
pcall(vim.cmd.colorscheme, "dark")
