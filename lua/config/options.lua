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
vim.keymap.set("n", "<c/>", "<cmd>botright 15split | terminal<CR>")
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
