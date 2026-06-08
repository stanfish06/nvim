local buf, win, nvim_servers
-- TODO: implement function to rename current server and save in nvim_servers (this would make server searching easier)

local function close_hover()
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    buf, win = nil, nil
end

local function connect_server()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local server_entry = nvim_servers[row]
    if not server_entry then
        return
    end
    vim.cmd("connect " .. server_entry.path)
end

-- probe the sockets to check if they are alive or not
local function socket_is_live(path)
    local ok, chan = pcall(vim.fn.sockconnect, "pipe", path, { rpc = true })
    if ok and type(chan) == "number" and chan > 0 then
        pcall(vim.fn.chanclose, chan)
        return true
    end
    return false
end

--   Linux:  $XDG_RUNTIME_DIR/nvim.<user>/.../nvim.<pid>.0
--   macOS:  $TMPDIR/nvim.<user>/<rand>/nvim.<pid>.0
local function list_nvim_sockets()
    local run = vim.fn.stdpath("run")
    -- Without XDG_RUNTIME_DIR (e.g. macOS) stdpath("run") is this process's own
    -- temp dir, so step up to the shared `nvim.<user>` dir that holds them all.
    if not vim.fn.fnamemodify(run, ":t"):match("^nvim%.") then
        run = vim.fn.fnamemodify(run, ":h")
    end
    local sockets = {}
    for _, path in ipairs(vim.fn.glob(run .. "/**/nvim.*", true, true)) do
        if vim.fn.getftype(path) == "socket" and socket_is_live(path) then
            table.insert(sockets, path)
        end
    end
    return sockets
end

local function refresh_server_list()
    nvim_servers = {}
    local lines_display = {}
    for i, path in ipairs(list_nvim_sockets()) do
        local name = path:match("[^/]+$") or ""
        local marker = path == vim.v.servername and "  (current)" or ""
        table.insert(nvim_servers, { id = i, name = name, path = path })
        table.insert(lines_display, "[" .. i .. "] " .. name .. marker)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines_display)
    vim.bo[buf].modifiable = false
end

local function open_hover()
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"

    local ui = vim.api.nvim_list_uis()[1]
    local width = math.min(60, math.max(40, math.floor(ui.width * 0.25)))
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
        title = "Available servers",
    })
    vim.wo[win].cursorline = true
    refresh_server_list()

    local opts = { buffer = buf, nowait = true }
    vim.keymap.set("n", "<CR>", connect_server, opts)
    -- TODO: vim.keymap.set("n", "...", kill_server, opts)
    vim.keymap.set("n", "q", close_hover, opts)
    vim.keymap.set("n", "<leader>r", refresh_server_list, opts)
    vim.keymap.set("n", "<Esc>", close_hover, opts)
end

-- show available servers in a hover buffer
vim.api.nvim_create_user_command("ShowNvimServers", function()
    open_hover()
end, {
    nargs = 0,
    desc = "Show all available neovim servers on system in a hovering buffer",
})
