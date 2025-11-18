-- note: opt is a "smarter" version of o. In simple assignments, they are inter-changeable
-- color theme
vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
vim.cmd.colorscheme("dark")

-- line number
vim.o.number = true
vim.o.relativenumber = true

-- misc settings
vim.o.showmode = true
vim.o.autoread = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.shiftwidth = 4
vim.o.history = 500
vim.o.cursorline = true
vim.o.cursorlineopt = 'number'

-- status
vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "yellow", fg = "black" })
vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "gray", fg = "black" })
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
function status_line()
	return current_mode() .. " " .. current_file()
end
vim.opt.statusline = "%!v:lua.status_line()"
