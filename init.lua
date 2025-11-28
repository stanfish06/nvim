-- color theme
vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
vim.cmd.colorscheme("dark")

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
vim.keymap.set('i', '<c-space>', '<c-x><c-o>', { desc = 'LSP completion' })
vim.keymap.set('i', '<c-l>', '<c-x><c-l>', { desc = 'Line completion' })
vim.keymap.set('i', '<c-f>', '<c-x><c-f>', { desc = 'File completion' })

-- misc settings
vim.o.showmode = true
vim.o.autoread = true
vim.o.ignorecase = true
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

-- clipboard
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- status
-- ISSUE: does not work after theme switch
vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "#66EB66", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#AA88DD", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "orange", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeNormalAlt", { fg = "#66EB66", bg = "#404040" })
vim.api.nvim_set_hl(0, "StatusLineModeInsertAlt", { fg = "#AA88DD", bg = "#404040" })
vim.api.nvim_set_hl(0, "StatusLineModeVisualAlt", { fg = "orange", bg = "#404040" })
vim.api.nvim_set_hl(0, "CursorInfo", { bg = "#B8C0E0", fg = "black" })
vim.api.nvim_set_hl(0, "CursorInfoAlt", { fg = "#B8C0E0" })
vim.api.nvim_set_hl(0, "File", { bg = "#404040", fg = "#ABEBE2" })
vim.api.nvim_set_hl(0, "FileAlt", { fg = "#404040" })

local function current_mode()
	local m = vim.fn.mode()
	local SOLID_RIGHT_ARROW = vim.fn.nr2char(0xe0b0)
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
	return string.format("%%#%s#%s%%*", mode_info.hl, mode_info.text)
		.. string.format("%%#%s#%s%%*", mode_info.hl_alt, SOLID_RIGHT_ARROW)
end

local function current_file()
	local SOLID_RIGHT_ARROW = vim.fn.nr2char(0xe0b0)
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
	local SOLID_LEFT_ARROW = vim.fn.nr2char(0xe0b2)
	local linenr = vim.api.nvim_win_get_cursor(0)[1]
	local colnr = vim.fn.col(".")
	local nlines = vim.api.nvim_buf_line_count(0)
	local percentage = 0
	if nlines > 0 then
		percentage = (linenr / nlines) * 100
	end
	return "%="
		.. "%#CursorInfoAlt#"
		.. SOLID_LEFT_ARROW
		.. "%*"
		.. "%#CursorInfo#"
		.. string.format("%.1f", percentage)
		.. "%% "
		.. string.format("%d:%d", linenr, colnr)
end

function StatusLine()
	return current_mode() .. current_file() .. current_cursor_info()
end
vim.opt.statusline = "%!v:lua.StatusLine()"

-- fzf
-- git clone --depth 1 https://github.com/ibhagwan/fzf-lua.git ~/.config/nvim/pack/plugins/start/fzf-lua
vim.keymap.set("n", "<leader><leader>", ":FzfLua files<CR>")
vim.keymap.set("n", "<leader>/", ":FzfLua live_grep<CR>")
vim.keymap.set("n", "<leader>sl", ":FzfLua lines<CR>")
vim.keymap.set("n", "<leader>sb", ":FzfLua buffers<CR>")

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
