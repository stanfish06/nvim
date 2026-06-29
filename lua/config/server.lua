local buf, win, nvim_servers
local SERVER_LABEL_VAR = "nvim_server_label"

local function close_hover()
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    buf, win = nil, nil
end

local function selected_server()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    return nvim_servers[row]
end

local function connect_server()
    local server_entry = selected_server()
    if not server_entry then
        return
    end
    vim.cmd("connect " .. server_entry.path)
end

local function with_rpc_channel(path, callback)
    local connected, chan = pcall(vim.fn.sockconnect, "pipe", path, { rpc = true })
    if not connected or type(chan) ~= "number" or chan <= 0 then
        return false, false, chan
    end
    local ok, result = pcall(callback, chan)
    pcall(vim.fn.chanclose, chan)
    return true, ok, result
end

local function server_display_name(server)
    if server.label and server.label ~= "" then
        return server.label .. " │ " .. server.name
    end
    return server.name
end

local function inspect_server(path)
    if path == vim.v.servername then
        local label = vim.g[SERVER_LABEL_VAR]
        return true, type(label) == "string" and label or nil
    end
    local connected, read, label = with_rpc_channel(path, function(chan)
        return vim.fn.rpcrequest(
            chan,
            "nvim_exec_lua",
            "local name = ...; return vim.g[name]",
            { SERVER_LABEL_VAR }
        )
    end)
    if not connected then
        return false
    end
    if not read then
        return true, nil, label
    end
    return true, type(label) == "string" and label or nil
end

--   Linux:  $XDG_RUNTIME_DIR/nvim.<user>/.../nvim.<pid>.0
--   macOS:  $TMPDIR/nvim.<user>/<rand>/nvim.<pid>.0
local function list_nvim_servers()
    local run = vim.fn.stdpath("run")
    -- Without XDG_RUNTIME_DIR (e.g. macOS) stdpath("run") is this process's own
    -- temp dir, so step up to the shared `nvim.<user>` dir that holds them all.
    if not vim.fn.fnamemodify(run, ":t"):match("^nvim%.") then
        run = vim.fn.fnamemodify(run, ":h")
    end
    local servers = {}
    for _, path in ipairs(vim.fn.glob(run .. "/**/nvim.*", true, true)) do
        if vim.fn.getftype(path) == "socket" then
            local live, label, err = inspect_server(path)
            if live then
                local name = path:match("[^/]+$") or ""
                if err then
                    vim.notify("Failed to read label from " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
                end
                table.insert(servers, { name = name, path = path, label = label })
            end
        end
    end
    return servers
end

local function refresh_server_list()
    nvim_servers = list_nvim_servers()
    local lines_display = {}
    for i, server in ipairs(nvim_servers) do
        local marker = server.path == vim.v.servername and "  (current)" or ""
        table.insert(lines_display, "[" .. i .. "] " .. server_display_name(server) .. marker)
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines_display)
    vim.bo[buf].modifiable = false
end

local function rename_server()
    local server = selected_server()
    if not server then
        return
    end
    vim.ui.input({
        prompt = "Server label: ",
        default = server.label or "",
    }, function(label)
        if label == nil then
            return
        end
        if server.path == vim.v.servername then
            vim.g[SERVER_LABEL_VAR] = label ~= "" and label or nil
            if buf and vim.api.nvim_buf_is_valid(buf) then
                refresh_server_list()
            end
            return
        end
        local connected, renamed, err = with_rpc_channel(server.path, function(chan)
            return vim.fn.rpcrequest(
                chan,
                "nvim_exec_lua",
                "local name, value = ...; vim.g[name] = value ~= '' and value or nil",
                { SERVER_LABEL_VAR, label }
            )
        end)
        if not connected or not renamed then
            vim.notify("Failed to rename " .. server.name .. ": " .. tostring(err), vim.log.levels.ERROR)
        elseif buf and vim.api.nvim_buf_is_valid(buf) then
            refresh_server_list()
        end
    end)
end

local function kill_server()
    local server = selected_server()
    if not server then
        return
    end
    local target = server_display_name(server)
    local choice = vim.fn.confirm(
        "Close " .. target .. "?\nUnsaved changes will be lost.",
        "&Yes\n&No",
        2
    )
    if choice ~= 1 then
        return
    end

    if server.path == vim.v.servername then
        vim.cmd("qa!")
        return
    end

    local connected, chan = pcall(vim.fn.sockconnect, "pipe", server.path, { rpc = true })
    if not connected or type(chan) ~= "number" or chan <= 0 then
        vim.notify("Failed to connect to " .. target .. ": " .. tostring(chan), vim.log.levels.ERROR)
        return
    end

    local sent, result = pcall(vim.fn.rpcnotify, chan, "nvim_command", "qa!")
    if not sent or result ~= 1 then
        pcall(vim.fn.chanclose, chan)
        vim.notify("Failed to close " .. target .. ": " .. tostring(result), vim.log.levels.ERROR)
        return
    end

    vim.defer_fn(function()
        pcall(vim.fn.chanclose, chan)
        if buf and vim.api.nvim_buf_is_valid(buf) then
            refresh_server_list()
            for _, entry in ipairs(nvim_servers) do
                if entry.path == server.path then
                    vim.notify("Server did not close: " .. target, vim.log.levels.ERROR)
                    break
                end
            end
        end
    end, 200)
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
    vim.keymap.set("n", "R", rename_server, opts)
    vim.keymap.set("n", "d", kill_server, opts)
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
