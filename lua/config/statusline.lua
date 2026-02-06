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
	lua = "",
	python = "",
	rust = "󱘗",
	c = "",
	go = "",
	javascript = "",
	typescript = "",
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
