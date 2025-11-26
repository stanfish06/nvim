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
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "[Q]uickfix list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<c-/>", "<cmd>terminal<CR>")
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>")
vim.keymap.set("n", "\\", "<cmd>Sexplore<CR>")
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("n", "H", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "L", ":bnext<CR>", { noremap = true, silent = true })

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

-- clipboard
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- status
vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "white", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#AA88DD", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "orange", fg = "black" })
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
	if home_path == "" then
		return root_path:gsub(vim.env.HOME, "~")
	elseif overlap then
		return home_path:sub(overlap)
	else
		return home_path
	end
end
function StatusLine()
	return current_mode() .. " " .. current_file()
end
vim.opt.statusline = "%!v:lua.StatusLine()"

-- lsp
-- git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
-- after v12, neovim will have built-in package manager
-- lua
vim.lsp.config["luals"] = {
	-- Command and arguments to start the server.
	-- see https://github.com/LuaLS/lua-language-server for installation instruction
	cmd = { "lua-language-server" },

	-- Filetypes to automatically attach to.
	filetypes = { "lua" },

	-- Sets the "root directory" to the parent directory of the file in the
	-- current buffer that contains either a ".luarc.json" or a
	-- ".luarc.jsonc" file. Files that share a root directory will reuse
	-- the connection to the same LSP server.
	-- Nested lists indicate equal priority, see |vim.lsp.Config|.
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },

	-- Specific settings to send to the server. The schema for this is
	-- defined by the server. For example the schema for lua-language-server
	-- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
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
