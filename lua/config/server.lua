-- Nvim server hopping (tmux+sesh replacement)
--
-- Commands / keymaps:
--   :ShowNvimServers      management hover (connect/rename/kill/refresh)
--   :NvimHop [host]       fuzzy picker over live servers + zoxide dirs; <CR>
--                         connects (or spawns a server at the dir), ctrl-x kills
--                         (<leader>ss local, <leader>sr picks an ssh host first)
--   :NvimRemote {host}    spawn a plain nvim server on {host} (at ssh landing
--                         dir) and connect to it through a forwarded socket
--
-- Hopping away from the start instance auto-quits it once its UI detaches (
-- e.g. launch nvim without path input). Launching nvim with no args pops the 
-- hop picker when other servers exist.
-- disable with vim.g.nvim_server_autopick = false
--
-- Remote servers need key/agent auth (ssh runs with BatchMode=yes). All ssh
-- calls share a ControlMaster connection (persists 10 min), so the first
-- connection is the only slow one; you can also pre-open it manually with:
--   ssh -o ControlMaster=auto -o ControlPath=~/.ssh/nvim-hop-%C {host}

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

--   Linux:  $XDG_RUNTIME_DIR/nvim.<user>/.../nvim.<pid>.0
--   macOS:  $TMPDIR/nvim.<user>/<rand>/nvim.<pid>.0
local function run_root()
    local run = vim.fn.stdpath("run")
    -- With XDG_RUNTIME_DIR set (Linux) stdpath("run") is the shared, user-owned
    -- runtime dir that already holds every nvim.<pid> socket (either bare, e.g.
    -- /run/user/1000, or as .../nvim.<user>), so use it as-is. Stepping up here
    -- would land in root-owned /run/user. Without XDG_RUNTIME_DIR (e.g. macOS)
    -- stdpath("run") is this process's own temp dir, so step up to the shared
    -- `nvim.<user>` dir that holds them all.
    local xdg = vim.env.XDG_RUNTIME_DIR
    if (xdg == nil or xdg == "") and not vim.fn.fnamemodify(run, ":t"):match("^nvim%.") then
        run = vim.fn.fnamemodify(run, ":h")
    end
    return run
end

-- sockets we create (spawned sessions, ssh forwards) live here; names must
-- start with "nvim." so the listing glob below picks them up
local function hop_dir()
    local dir = run_root() .. "/hop"
    vim.fn.mkdir(dir, "p")
    return dir
end

local spawn_counter = 0
local function unique_sock(tag)
    spawn_counter = spawn_counter + 1
    return ("%s/nvim.%s.%d.%d"):format(hop_dir(), tag, vim.uv.os_getpid(), spawn_counter)
end

local function read_meta(path)
    local fd = io.open(path .. ".meta", "r")
    if not fd then
        return nil
    end
    local ok, data = pcall(vim.json.decode, fd:read("*a"))
    fd:close()
    return ok and type(data) == "table" and data or nil
end

-- tear down the ssh forward (and its socket/meta files) behind a dead or
-- killed remote server
local function cleanup_forward(path, meta)
    if meta and meta.fwd_pid then
        pcall(vim.uv.kill, meta.fwd_pid, "sigterm")
    end
    os.remove(path)
    os.remove(path .. ".meta")
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
    local where
    if server.meta and server.meta.host then
        where = server.meta.host .. ":" .. (server.cwd or "?")
    else
        where = server.cwd and vim.fn.fnamemodify(server.cwd, ":~") or server.name
    end
    if server.label and server.label ~= "" then
        return server.label .. " │ " .. where
    end
    return where
end

-- returns: live, label, cwd, err
local function inspect_server(path)
    if path == vim.v.servername then
        local label = vim.g[SERVER_LABEL_VAR]
        return true, type(label) == "string" and label or nil, vim.fn.getcwd()
    end
    local connected, read, result = with_rpc_channel(path, function(chan)
        return vim.fn.rpcrequest(
            chan,
            "nvim_exec_lua",
            "local name = ...; return { vim.g[name] or false, vim.fn.getcwd() }",
            { SERVER_LABEL_VAR }
        )
    end)
    if not connected then
        return false
    end
    if not read then
        return true, nil, nil, result
    end
    local label = type(result) == "table" and result[1] or nil
    local cwd = type(result) == "table" and result[2] or nil
    return true, type(label) == "string" and label or nil, type(cwd) == "string" and cwd or nil
end

local function list_nvim_servers()
    local root = run_root()
    local hop_prefix = root .. "/hop/"
    local servers = {}
    for _, path in ipairs(vim.fn.glob(root .. "/**/nvim.*", true, true)) do
        if vim.fn.getftype(path) == "socket" then
            local live, label, cwd, err = inspect_server(path)
            local meta = read_meta(path)
            local ours = path:sub(1, #hop_prefix) == hop_prefix
            -- a forwarded socket accepts connections even when the remote
            -- server behind it is gone; the failed rpc exposes that
            if (not live or err) and meta then
                cleanup_forward(path, meta)
            elseif not live and ours then
                os.remove(path)
            elseif live then
                local name = path:match("[^/]+$") or ""
                if err then
                    vim.notify("Failed to read label from " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
                end
                table.insert(servers, { name = name, path = path, label = label, cwd = cwd, meta = meta })
            end
        end
    end
    return servers
end

-- an instance nobody would miss: only empty unnamed buffers, no terminals,
-- no label, and not a deliberately spawned session (NVIM_SERVER_KEEP)
local function is_disposable()
    if os.getenv("NVIM_SERVER_KEEP") ~= nil then
        return false
    end
    local label = vim.g[SERVER_LABEL_VAR]
    if type(label) == "string" and label ~= "" then
        return false
    end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) then
            -- fzf-lua (and similar pickers) leave their own finder behind as a
            -- hidden, unlisted terminal buffer for window reuse; 
            -- Conditions here ensure that a terminal that's actually visible or listed counts as "in use"
            if vim.bo[b].buftype == "terminal" and (vim.bo[b].buflisted or #vim.fn.win_findbuf(b) > 0) then
                return false
            end
            if vim.bo[b].buflisted then
                if vim.api.nvim_buf_get_name(b) ~= "" or vim.bo[b].modified then
                    return false
                end
                if
                    vim.api.nvim_buf_line_count(b) > 1
                    or (vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] or "") ~= ""
                then
                    return false
                end
            end
        end
    end
    return true
end

-- true only inside a server spawned on a remote host (tagged at spawn with
-- NVIM_HOP_REMOTE). :connect/:restart only work when the UI and server share a
-- machine, so re-hopping is blocked from remote sessions. 
local function ui_is_cross_machine()
    return vim.env.NVIM_HOP_REMOTE ~= nil
end

local function connect_to(path)
    if not path or path == "" or path == vim.v.servername then
        return
    end
    if ui_is_cross_machine() then
        vim.notify(
            "Can't hop again from inside a remote session. Disconnect back to your local instance first.",
            vim.log.levels.WARN
        )
        return
    end
    -- if this instance is just an empty launch dummy, let it quit itself once
    -- the UI has moved on (checked again in the timer: by then pickers are
    -- closed and, on a failed connect, the UI is still attached here)
    vim.defer_fn(function()
        if #vim.api.nvim_list_uis() == 0 and is_disposable() then
            vim.cmd("qa!")
        end
    end, 1500)
    local ok, err = pcall(vim.cmd, "connect " .. vim.fn.fnameescape(path))
    if not ok then
        vim.notify("Failed to connect to " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
    end
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

local function kill_entry(server, on_done)
    local target = server_display_name(server)
    local choice = vim.fn.confirm("Close " .. target .. "?\nUnsaved changes will be lost.", "&Yes\n&No", 2)
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
        local live, _, _, err = inspect_server(server.path)
        if live and not err then
            vim.notify("Server did not close: " .. target, vim.log.levels.ERROR)
        elseif server.meta then
            cleanup_forward(server.path, server.meta)
        end
        if on_done then
            on_done()
        end
    end, 500)
end

local function kill_server()
    local server = selected_server()
    if not server then
        return
    end
    kill_entry(server, function()
        if buf and vim.api.nvim_buf_is_valid(buf) then
            refresh_server_list()
        end
    end)
end

local function connect_server()
    local server_entry = selected_server()
    if not server_entry then
        return
    end
    close_hover()
    connect_to(server_entry.path)
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

-- ---------------------------------------------------------------------------
-- spawning sessions (local zoxide dirs and ssh remotes)
-- ---------------------------------------------------------------------------

local function ssh_cmd()
    return {
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "ControlMaster=auto",
        "-o",
        "ControlPath=" .. vim.fn.expand("~/.ssh") .. "/nvim-hop-%C",
        "-o",
        "ControlPersist=600",
    }
end

local function ssh_hosts()
    local hosts, seen = {}, {}
    local cfg = vim.fn.expand("~/.ssh/config")
    if vim.fn.filereadable(cfg) == 1 then
        for _, line in ipairs(vim.fn.readfile(cfg)) do
            local names = line:match("^%s*[Hh][Oo][Ss][Tt]%s+(.+)")
            if names then
                for h in names:gmatch("%S+") do
                    if not h:find("[*?!]") and not seen[h] then
                        seen[h] = true
                        table.insert(hosts, h)
                    end
                end
            end
        end
    end
    return hosts
end

local function complete_ssh_hosts(arglead)
    return vim.tbl_filter(function(h)
        return h:sub(1, #arglead) == arglead
    end, ssh_hosts())
end

local function zoxide_dirs(host)
    local cmd
    if host then
        cmd = vim.list_extend(ssh_cmd(), { "-T", host, "zoxide query -l" })
    else
        if vim.fn.executable("zoxide") == 0 then
            vim.notify("zoxide not found in PATH", vim.log.levels.WARN)
            return {}
        end
        cmd = { "zoxide", "query", "-l" }
    end
    local ok, proc = pcall(vim.system, cmd, { text = true })
    if not ok then
        return {}
    end
    local res = proc:wait(10000)
    if res.code ~= 0 then
        vim.notify(
            "zoxide query failed" .. (host and (" on " .. host) or "") .. ": " .. vim.trim(res.stderr or ""),
            vim.log.levels.WARN
        )
        return {}
    end
    return vim.split(res.stdout or "", "\n", { trimempty = true })
end

local function spawn_local_server(dir)
    dir = vim.fn.fnamemodify(dir, ":p")
    if vim.fn.isdirectory(dir) == 0 then
        vim.notify("Not a directory: " .. dir, vim.log.levels.ERROR)
        return nil
    end
    local sock = unique_sock("hop")
    os.remove(sock)
    local job = vim.fn.jobstart({ vim.v.progpath, "--headless", "--listen", sock }, {
        cwd = dir,
        detach = true,
        env = { NVIM_SERVER_KEEP = "1" },
    })
    if job <= 0 then
        vim.notify("Failed to spawn server at " .. dir, vim.log.levels.ERROR)
        return nil
    end
    if vim.fn.executable("zoxide") == 1 then
        pcall(vim.system, { "zoxide", "add", dir })
    end
    if not vim.wait(5000, function()
        return vim.fn.getftype(sock) == "socket"
    end, 50) then
        vim.notify("Server at " .. dir .. " did not start", vim.log.levels.ERROR)
        return nil
    end
    return sock
end

local function remote_spawn_script(dir)
    local lines = {}
    if dir then
        table.insert(lines, "cd " .. vim.fn.shellescape(dir) .. " || exit 9")
        table.insert(lines, 'command -v zoxide >/dev/null 2>&1 && zoxide add "$PWD" >/dev/null 2>&1')
    end
    vim.list_extend(lines, {
        "command -v nvim >/dev/null 2>&1 || exit 7",
        'd="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"',
        's="$d/nvim.hop.$$.$(date +%s)"',
        -- NVIM_HOP_REMOTE marks this as a genuine remote session (see ui_is_cross_machine)
        'NVIM_HOP_REMOTE=1 NVIM_SERVER_KEEP=1 nohup nvim --headless --listen "$s" </dev/null >/dev/null 2>&1 &',
        'i=0; while [ $i -lt 50 ]; do [ -S "$s" ] && break; sleep 0.1; i=$((i+1)); done',
        '[ -S "$s" ] || exit 8',
        'echo "$s"',
    })
    return table.concat(lines, "\n")
end

-- keeps the remote server reachable as a local socket; the ssh -N process is
-- the tunnel and is reaped when the server behind it dies (see list/kill)
local function forward_remote(host, remote_sock)
    local localsock = unique_sock("ssh." .. host:gsub("[^%w%-_.]", "_"))
    os.remove(localsock)
    local cmd = vim.list_extend(ssh_cmd(), {
        "-N",
        "-o",
        "ExitOnForwardFailure=yes",
        "-o",
        "StreamLocalBindUnlink=yes",
        "-L",
        localsock .. ":" .. remote_sock,
        host,
    })
    local job = vim.fn.jobstart(cmd, { detach = true })
    if job <= 0 then
        vim.notify("Failed to start ssh forward to " .. host, vim.log.levels.ERROR)
        return nil
    end
    if not vim.wait(10000, function()
        return vim.fn.getftype(localsock) == "socket"
    end, 100) then
        pcall(vim.fn.jobstop, job)
        vim.notify("ssh forward to " .. host .. " did not come up", vim.log.levels.ERROR)
        return nil
    end
    vim.fn.writefile(
        { vim.json.encode({
            host = host,
            remote_sock = remote_sock,
            fwd_pid = vim.fn.jobpid(job),
        }) },
        localsock .. ".meta"
    )
    return localsock
end

local function remote_session(host, dir)
    vim.notify("Spawning nvim on " .. host .. (dir and (" at " .. dir) or "") .. " ...")
    local cmd = vim.list_extend(ssh_cmd(), { "-T", host, remote_spawn_script(dir) })
    vim.system(cmd, { text = true }, function(res)
        vim.schedule(function()
            if res.code ~= 0 then
                local why = "ssh failed (" .. res.code .. ")"
                if res.code == 9 then
                    why = "no such directory on " .. host .. ": " .. tostring(dir)
                elseif res.code == 8 then
                    why = "nvim did not start on " .. host
                elseif res.code == 7 then
                    why = "nvim not found on " .. host .. " (not in non-interactive ssh PATH)"
                elseif res.code == 255 then
                    why = "ssh connection to " .. host .. " failed (BatchMode: needs key/agent auth)"
                end
                vim.notify(why .. "\n" .. vim.trim(res.stderr or ""), vim.log.levels.ERROR)
                return
            end
            local out = vim.split(res.stdout or "", "\n", { trimempty = true })
            local remote_sock = out[#out]
            if not remote_sock or remote_sock == "" then
                vim.notify("Could not determine remote socket on " .. host, vim.log.levels.ERROR)
                return
            end
            local localsock = forward_remote(host, remote_sock)
            if localsock then
                connect_to(localsock)
            end
        end)
    end)
end

-- ---------------------------------------------------------------------------
-- hop picker (fuzzy: live servers + zoxide dirs, local or per ssh host)
-- ---------------------------------------------------------------------------

local open_hop_picker

local function hop_entries(host)
    local entries, lookup = {}, {}
    local function add(text, item)
        if not lookup[text] then
            lookup[text] = item
            table.insert(entries, text)
        end
    end
    local served = {}
    for _, s in ipairs(list_nvim_servers()) do
        local remote = s.meta and s.meta.host or nil
        if remote == host or (not remote and not host) then
            if s.cwd then
                served[s.cwd] = true
            end
            local marker = s.path == vim.v.servername and "  (current)" or ""
            add("● " .. server_display_name(s) .. marker .. "  │ " .. s.name, { kind = "server", server = s })
        end
    end
    if host then
        add("+ ~ (ssh landing)", { kind = "dir", host = host })
    end
    for _, dir in ipairs(zoxide_dirs(host)) do
        if not served[dir] then
            local short = host and dir or vim.fn.fnamemodify(dir, ":~")
            add("+ " .. short, { kind = "dir", dir = dir, host = host })
        end
    end
    return entries, lookup
end

open_hop_picker = function(host)
    local entries, lookup = hop_entries(host)
    if #entries == 0 then
        vim.notify("No servers or zoxide dirs to hop to", vim.log.levels.INFO)
        return
    end
    local function handle(text)
        local item = lookup[text]
        if not item then
            return
        end
        if item.kind == "server" then
            connect_to(item.server.path)
        elseif item.host then
            remote_session(item.host, item.dir)
        else
            connect_to(spawn_local_server(item.dir))
        end
    end
    local fzf_ok, fzf = pcall(require, "fzf-lua")
    if fzf_ok then
        fzf.fzf_exec(entries, {
            prompt = (host and (host .. " ") or "") .. "hop> ",
            actions = {
                ["default"] = function(selected)
                    if selected and selected[1] then
                        handle(selected[1])
                    end
                end,
                ["ctrl-x"] = function(selected)
                    local item = selected and selected[1] and lookup[selected[1]]
                    if item and item.kind == "server" then
                        kill_entry(item.server, function()
                            open_hop_picker(host)
                        end)
                    else
                        open_hop_picker(host)
                    end
                end,
            },
        })
    else
        vim.ui.select(entries, { prompt = "Nvim hop" }, function(choice)
            if choice then
                handle(choice)
            end
        end)
    end
end

-- ---------------------------------------------------------------------------
-- commands, keymaps, launch behavior
-- ---------------------------------------------------------------------------

-- show available servers in a hover buffer
vim.api.nvim_create_user_command("ShowNvimServers", function()
    open_hover()
end, {
    nargs = 0,
    desc = "Show all available neovim servers on system in a hovering buffer",
})

vim.api.nvim_create_user_command("NvimHop", function(o)
    open_hop_picker(o.args ~= "" and o.args or nil)
end, {
    nargs = "?",
    complete = complete_ssh_hosts,
    desc = "Fuzzy-hop across nvim servers and zoxide dirs (optionally on an ssh host)",
})

vim.api.nvim_create_user_command("NvimRemote", function(o)
    remote_session(o.args, nil)
end, {
    nargs = 1,
    complete = complete_ssh_hosts,
    desc = "Spawn a nvim server on an ssh host and connect to it",
})

vim.keymap.set("n", "<leader>ss", function()
    open_hop_picker(nil)
end, { desc = "Hop nvim servers / zoxide dirs" })

vim.keymap.set("n", "<leader>sr", function()
    local hosts = ssh_hosts()
    if #hosts == 0 then
        vim.notify("No hosts found in ~/.ssh/config", vim.log.levels.WARN)
        return
    end
    vim.ui.select(hosts, { prompt = "SSH host" }, function(h)
        if h then
            open_hop_picker(h)
        end
    end)
end, { desc = "Hop nvim servers on an ssh host" })

-- plain `nvim` launch: offer to hop to existing servers right away instead of
-- leaving this fresh instance around as yet another dummy
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        if vim.g.nvim_server_autopick == false then
            return
        end
        if vim.fn.argc(-1) > 0 or #vim.api.nvim_list_uis() == 0 or not is_disposable() then
            return
        end
        vim.schedule(function()
            for _, s in ipairs(list_nvim_servers()) do
                if s.path ~= vim.v.servername then
                    open_hop_picker(nil)
                    return
                end
            end
        end)
    end,
})
