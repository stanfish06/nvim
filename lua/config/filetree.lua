local buf, win, cwd, entries

local function list_dir(path)
	local raw = vim.fn.readdir(path)
	local dirs, files = {}, {}
	for _, name in ipairs(raw) do
		if vim.fn.isdirectory(path .. "/" .. name) == 1 then
			table.insert(dirs, name .. "/")
		else
			table.insert(files, name)
		end
	end
	table.sort(dirs)
	table.sort(files)
	local lines = {}
	entries = {}
	for _, d in ipairs(dirs) do
		table.insert(lines, d)
		table.insert(entries, { name = d:sub(1, -2), is_dir = true })
	end
	for _, f in ipairs(files) do
		table.insert(lines, f)
		table.insert(entries, { name = f, is_dir = false })
	end
	return lines
end

local function refresh()
	local lines = list_dir(cwd)
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	local title = vim.fn.fnamemodify(cwd, ":~")
	vim.api.nvim_win_set_config(win, { title = " " .. title .. " " })
end

local function close()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	buf, win = nil, nil
end

local function open_entry()
	local row = vim.api.nvim_win_get_cursor(win)[1]
	local entry = entries[row]
	if not entry then
		return
	end
	if entry.is_dir then
		cwd = cwd .. "/" .. entry.name
		refresh()
		vim.api.nvim_win_set_cursor(win, { 1, 0 })
	else
		close()
		vim.cmd.edit(cwd .. "/" .. entry.name)
	end
end

local function go_parent()
	local parent = vim.fn.fnamemodify(cwd, ":h")
	if parent == cwd then
		return
	end
	cwd = parent
	refresh()
	vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

local function open()
	cwd = vim.fn.getcwd()
	buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"

	local ui = vim.api.nvim_list_uis()[1]
	local width = math.min(60, math.max(40, math.floor(ui.width * 0.4)))
	local height = math.min(20, ui.height - 4)
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "single",
		style = "minimal",
		title = " " .. vim.fn.fnamemodify(cwd, ":~") .. " ",
	})
	vim.wo[win].cursorline = true

	refresh()

	local opts = { buffer = buf, nowait = true }
	vim.keymap.set("n", "<CR>", open_entry, opts)
	vim.keymap.set("n", "h", go_parent, opts)
	vim.keymap.set("n", "<BS>", go_parent, opts)
	vim.keymap.set("n", "q", close, opts)
	vim.keymap.set("n", "<Esc>", close, opts)
end

vim.keymap.set("n", "-", open)
