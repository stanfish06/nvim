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
vim.keymap.set("n", "\\", "<cmd>Sexplore<CR>")
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("n", "H", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "L", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>e", ":edit **/*")
vim.keymap.set("n", "<leader>f", ":find **/*")
vim.cmd.cnoreabbrev("vimgrep", "vimgrep /pattern/gj **/*")
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "[O]pen quickfix list" })
vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "[C]lose quickfix list" })

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
vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "#66EB66", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#AA88DD", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "orange", fg = "black" })
vim.api.nvim_set_hl(0, "CursorInfo", { bg = "#B8C0E0", fg = "black" })
vim.api.nvim_set_hl(0, "File", { bg = "#404040", fg = "#ABEBE2" })

local function current_mode()
	local m = vim.fn.mode()
	local mode_map = {
		n = { text = "[N]", hl = "StatusLineModeNormal" },
		i = { text = "[I]", hl = "StatusLineModeInsert" },
		v = { text = "[V]", hl = "StatusLineModeVisual" },
		V = { text = "[VL]", hl = "StatusLineModeVisual" },
		["\22"] = { text = "[VB]", hl = "StatusLineModeVisual" },
		R = { text = "[R]", hl = "StatusLineModeInsert" },
		c = { text = "[C]", hl = "StatusLineModeNormal" },
		t = { text = "[T]", hl = "StatusLineModeInsert" },
	}
	local mode_info = mode_map[m] or { text = "[?]", hl = "StatusLineModeNormal" }
	return string.format("%%#%s#%s%%*", mode_info.hl, mode_info.text)
end

local function current_file()
	local root_path = vim.loop.cwd()
	local root_dir = root_path:match("[^/]+$")
	local home_path = vim.fn.expand("%:~")
	local overlap, _ = home_path:find(root_dir)
	local color = "%#File# "
	if home_path == "" then
		return color .. root_path:gsub(vim.env.HOME, "~") .. " %*"
	elseif overlap then
		return color .. home_path:sub(overlap) .. " %*"
	else
		return color .. home_path .. " %*"
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
	return "%="
		.. "%#CursorInfo#"
		.. string.format("%.1f", percentage)
		.. "%% "
		.. string.format("%d:%d", linenr, colnr)
end

function StatusLine()
	return current_mode() .. current_file() .. current_cursor_info()
end
vim.opt.statusline = "%!v:lua.StatusLine()"

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
