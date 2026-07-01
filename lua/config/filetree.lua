local M = {}

local state = {
    buf = nil,
    win = nil,
    cwd = nil,
    entries = {},
    show_hidden = false,
}

local function path_join(...)
    return table.concat(vim.tbl_filter(function(part)
        return part and part ~= ""
    end, { ... }), "/")
end

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "filetree" })
end

local function is_valid_window()
    return state.win and vim.api.nvim_win_is_valid(state.win)
end

local function is_valid_buffer()
    return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function display_width()
    local ui = vim.api.nvim_list_uis()[1]
    if not ui then
        return 48
    end
    return math.min(56, math.max(36, math.floor(ui.width * 0.3)))
end

local function display_height()
    local ui = vim.api.nvim_list_uis()[1]
    if not ui then
        return 20
    end
    return math.min(math.max(10, ui.height - 6), 28)
end

local function entry_icon(entry)
    if entry.is_parent then
        return "󰁞", "Comment"
    end
    if entry.is_dir then
        return "", "Directory"
    end

    local ok, devicons = pcall(require, "nvim-web-devicons")
    if ok then
        local icon, highlight = devicons.get_icon(entry.name, vim.fs.ext(entry.name), { default = true })
        return icon or "󰈙", highlight or "Normal"
    end

    return "󰈙", "Normal"
end

local function should_show(name)
    return state.show_hidden or name:sub(1, 1) ~= "."
end

local function scan_dir(path)
    local ok, names = pcall(vim.fn.readdir, path)
    if not ok then
        notify("Cannot read " .. path, vim.log.levels.ERROR)
        return {}, {}
    end

    local dirs, files = {}, {}
    for _, name in ipairs(names) do
        if should_show(name) then
            local full_path = path_join(path, name)
            if vim.fn.isdirectory(full_path) == 1 then
                table.insert(dirs, { name = name, path = full_path, is_dir = true })
            else
                table.insert(files, { name = name, path = full_path, is_dir = false })
            end
        end
    end

    table.sort(dirs, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    table.sort(files, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    local entries = {}
    if vim.fn.fnamemodify(path, ":h") ~= path then
        table.insert(entries, { name = "..", path = vim.fn.fnamemodify(path, ":h"), is_dir = true, is_parent = true })
    end
    vim.list_extend(entries, dirs)
    vim.list_extend(entries, files)

    local lines = {}
    for _, entry in ipairs(entries) do
        local icon = entry_icon(entry)
        local suffix = entry.is_dir and "/" or ""
        table.insert(lines, string.format(" %s  %s%s", icon, entry.name, suffix))
    end

    if #lines == 0 then
        table.insert(lines, " 󰇘  empty")
    end

    return entries, lines
end

local function set_highlights(entries)
    if not is_valid_buffer() then
        return
    end

    local namespace = vim.api.nvim_create_namespace("config.filetree")
    vim.api.nvim_buf_clear_namespace(state.buf, namespace, 0, -1)

    for row, entry in ipairs(entries) do
        local icon, highlight = entry_icon(entry)
        local icon_end = #(" " .. icon)
        local name_start = #(" " .. icon .. "  ")
        local name_end = name_start + #entry.name + (entry.is_dir and 1 or 0)
        vim.api.nvim_buf_set_extmark(state.buf, namespace, row - 1, 1, {
            end_col = icon_end,
            hl_group = highlight,
            priority = 100,
        })
        if entry.is_dir then
            vim.api.nvim_buf_set_extmark(state.buf, namespace, row - 1, name_start, {
                end_col = name_end,
                hl_group = "Directory",
                priority = 80,
            })
        end
    end
end

local function title()
    local hidden = state.show_hidden and " all" or " visible"
    return " " .. vim.fn.fnamemodify(state.cwd, ":~") .. hidden .. " "
end

local function footer()
    return " ↵ open  h parent  l expand  . hidden  r refresh  q quit "
end

function M.refresh(keep_row)
    if not is_valid_window() or not is_valid_buffer() then
        return
    end

    local row = keep_row and vim.api.nvim_win_get_cursor(state.win)[1] or 1
    local entries, lines = scan_dir(state.cwd)
    state.entries = entries

    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    vim.bo[state.buf].modifiable = false
    set_highlights(entries)
    vim.api.nvim_win_set_config(state.win, { title = title(), footer = footer() })
    vim.api.nvim_win_set_cursor(state.win, { math.min(row, #lines), 0 })
end

function M.close()
    if is_valid_window() then
        vim.api.nvim_win_close(state.win, true)
    end
    state.buf = nil
    state.win = nil
end

local function selected_entry()
    if not is_valid_window() then
        return nil
    end
    local row = vim.api.nvim_win_get_cursor(state.win)[1]
    return state.entries[row]
end

function M.parent()
    local parent = vim.fn.fnamemodify(state.cwd, ":h")
    if parent == state.cwd then
        return
    end
    state.cwd = parent
    M.refresh(false)
end

function M.open_entry(mode)
    local entry = selected_entry()
    if not entry then
        return
    end

    if entry.is_dir then
        state.cwd = entry.path
        M.refresh(false)
        return
    end

    M.close()
    local command = mode == "split" and "split" or mode == "vsplit" and "vsplit" or mode == "tab" and "tabedit" or "edit"
    vim.cmd(command .. " " .. vim.fn.fnameescape(entry.path))
end

function M.toggle_hidden()
    state.show_hidden = not state.show_hidden
    M.refresh(true)
end

function M.copy_path()
    local entry = selected_entry()
    if not entry then
        return
    end
    vim.fn.setreg("+", entry.path)
    notify("Copied: " .. vim.fn.fnamemodify(entry.path, ":~"))
end

local function starting_dir(opts)
    if opts and opts.args and opts.args ~= "" then
        local path = vim.fn.fnamemodify(opts.args, ":p")
        if vim.fn.isdirectory(path) == 1 then
            return path:gsub("/$", "")
        end
        return vim.fn.fnamemodify(path, ":h")
    end

    local current = vim.api.nvim_buf_get_name(0)
    if current ~= "" and vim.fn.filereadable(current) == 1 then
        return vim.fn.fnamemodify(current, ":p:h")
    end

    return vim.fn.getcwd()
end

local function create_buffer()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].filetype = "filetree"
    vim.bo[buf].modifiable = false
    vim.bo[buf].swapfile = false
    return buf
end

local function set_window_options(win)
    vim.wo[win].cursorline = true
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].statuscolumn = ""
    vim.wo[win].winfixbuf = true
end

local function set_keymaps(buf)
    local opts = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set("n", "<CR>", function()
        M.open_entry()
    end, opts)
    vim.keymap.set("n", "l", function()
        M.open_entry()
    end, opts)
    vim.keymap.set("n", "s", function()
        M.open_entry("split")
    end, opts)
    vim.keymap.set("n", "v", function()
        M.open_entry("vsplit")
    end, opts)
    vim.keymap.set("n", "t", function()
        M.open_entry("tab")
    end, opts)
    vim.keymap.set("n", "h", M.parent, opts)
    vim.keymap.set("n", "<BS>", M.parent, opts)
    vim.keymap.set("n", ".", M.toggle_hidden, opts)
    vim.keymap.set("n", "r", function()
        M.refresh(true)
    end, opts)
    vim.keymap.set("n", "y", M.copy_path, opts)
    vim.keymap.set("n", "q", M.close, opts)
    vim.keymap.set("n", "<Esc>", M.close, opts)
end

function M.open(opts)
    if is_valid_window() then
        vim.api.nvim_set_current_win(state.win)
        return
    end

    state.cwd = starting_dir(opts)
    state.buf = create_buffer()

    local ui = vim.api.nvim_list_uis()[1]
    local width = display_width()
    local height = display_height()
    local row = ui and math.floor((ui.height - height) / 2) or 1
    local col = ui and math.max(0, math.floor(ui.width * 0.05)) or 1

    state.win = vim.api.nvim_open_win(state.buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "single",
        style = "minimal",
        title = title(),
        footer = footer(),
    })

    set_window_options(state.win)
    set_keymaps(state.buf)
    M.refresh(false)
end

function M.toggle(opts)
    if is_valid_window() then
        M.close()
    else
        M.open(opts)
    end
end

vim.api.nvim_create_user_command("FileTree", function(opts)
    M.toggle(opts)
end, { nargs = "?", complete = "dir" })

vim.keymap.set("n", "-", M.toggle, { desc = "Toggle file tree" })

return M
