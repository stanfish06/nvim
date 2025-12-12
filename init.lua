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

-- clipboard
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- status
-- callback that runs every time after colorscheme changes to make sure statusline stay the same
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "#66EB66", fg = "black" })
		vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#AA88DD", fg = "black" })
		vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "orange", fg = "black" })
		vim.api.nvim_set_hl(0, "StatusLineModeNormalAlt", { fg = "#66EB66", bg = "#404040" })
		vim.api.nvim_set_hl(0, "StatusLineModeInsertAlt", { fg = "#AA88DD", bg = "#404040" })
		vim.api.nvim_set_hl(0, "StatusLineModeVisualAlt", { fg = "orange", bg = "#404040" })
		vim.api.nvim_set_hl(0, "CursorInfo", { bg = "#B8C0E0", fg = "black" })
		vim.api.nvim_set_hl(0, "CursorInfoAlt", { fg = "#B8C0E0", bg = "#3E8FB0" })
		vim.api.nvim_set_hl(0, "File", { bg = "#404040", fg = "#ABEBE2" })
		vim.api.nvim_set_hl(0, "FileAlt", { fg = "#404040" })
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
	local SOLID_LEFT_ARROW = vim.fn.nr2char(0xe0b2)
	local filetype = vim.bo.filetype
	local color = "%#FileType#"
	local color_alt = "%#FileTypeAlt#"
	if not vim.g.have_nerd_font then
		return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. "  " .. " "
	else
		local icon = filetype_icons[filetype]
		if icon == nil then
			icon = " "
		end
		return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. " " .. icon .. " "
	end
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
	return ""
		.. "%#CursorInfoAlt#"
		.. SOLID_LEFT_ARROW
		.. "%*"
		.. "%#CursorInfo#"
		.. string.format("%.1f", percentage)
		.. "%% "
		.. string.format("%d:%d", linenr, colnr)
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
	["dark-theme"] = "https://github.com/stanfish06/dark-theme.git",
	["rose-pine"] = "https://github.com/rose-pine/neovim.git",
	["tokyonight"] = "https://github.com/folke/tokyonight.nvim.git",
}
function sync_packages()
	local package_dir = os.getenv("HOME") .. "/.config/nvim/pack/plugins/start/"
	print("Sync packages...")
	for pkg_name, pkg_url in pairs(package_list) do
		local full_path = package_dir .. pkg_name .. "/"
		if vim.fn.isdirectory(full_path) == 1 then
			print("Reinstalling " .. pkg_name .. "...")
			vim.fn.delete(full_path, "rf")
		else
			print("Installing " .. pkg_name .. "...")
		end
		os.execute("git clone --depth 1 --quiet " .. pkg_url .. " " .. full_path .. " > /dev/null 2>&1")
	end
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

-- treesitter
-- git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/plugins/start/nvim-treestter
local ts_status, ts_configs = pcall(require, "nvim-treesitter.configs")
if ts_status then
	ts_configs.setup({
		ensure_installed = {
			"c",
			"cpp",
			"bash",
			"lua",
			"vim",
			"vimdoc",
			"javascript",
			"markdown",
			"markdown_inline",
		},
		auto_install = true,
		highlight = { enable = true },
		indent = { enable = true },
	})
end

-- color theme
-- git clone --depth 1 https://github.com/stanfish06/dark-theme.git ~/.config/nvim/pack/plugins/start/dark-theme
-- vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
pcall(vim.cmd.colorscheme, "dark")
