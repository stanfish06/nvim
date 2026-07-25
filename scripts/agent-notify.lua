-- Dispatcher behind agent-notify.sh; runs in a throwaway headless nvim:
--   nvim -u NONE -l scripts/agent-notify.lua <agent> <event> [json]
--
-- One notification, in the window you are looking at. Several nvim servers can
-- be live at once (separate windows, plus the headless ones spawned by
-- lua/config/server.lua), and hopping means the server owning the agent's
-- terminal is often not the one on screen, so the target is picked in this
-- order:
--   0. $NVIM if it reports focus        -- early exit: rule 1 already won
--   1. servers reporting terminal focus -- your eyes are there
--   2. $NVIM, the agent's own server    -- when nothing reported focus
--   3. every server with a UI           -- owner is headless, focus unknown
--   4. $NVIM regardless                 -- nobody is watching; land in history
--
-- Rule 0 is only an optimisation: it can fire only when it agrees with rule 1,
-- and any other answer sweeps every live socket exactly as before.
--
-- Event JSON is read from argv (Codex) or stdin (Claude Code hooks) and every
-- field is optional; the payload is passed as an RPC argument, never
-- interpolated into code, so agent output cannot escape into Lua.
--
-- Rendering happens in lua/config/agent_notify.lua on the receiving side.
-- Deliveries are logged to stdpath("state") .. "/agent-notify.log".

local agent = arg[1] or "agent"
local event = arg[2] or "stop"

local EVENTS = {
    stop = { headline = "finished", level = "info" },
    attention = { headline = "needs you", level = "warn" },
}
local meta = EVENTS[event] or EVENTS.stop

-- Codex hands its JSON over as an argv element, Claude Code pipes it on stdin
local raw = arg[3]
if not raw or vim.trim(raw) == "" then
    raw = vim.uv.guess_handle(0) ~= "tty" and io.read("*a") or nil
end

local hook = {}
if raw and vim.trim(raw) ~= "" then
    local ok, decoded = pcall(vim.json.decode, raw)
    if ok and type(decoded) == "table" then
        hook = decoded
    end
end

local function field(...)
    for _, key in ipairs({ ... }) do
        local value = hook[key]
        if type(value) == "string" and vim.trim(value) ~= "" then
            return value
        end
    end
end

local payload = {
    agent = agent,
    headline = meta.headline,
    level = meta.level,
    -- Codex uses "cwd"; Claude hooks may use "workspace"; then fall back locally
    cwd = field("cwd", "workspace") or vim.uv.cwd(),
    detail = field("message", "last_assistant_message", "last-assistant-message"),
}

--   Linux:  $XDG_RUNTIME_DIR/nvim.<user>/.../nvim.<pid>.0
--   macOS:  $TMPDIR/nvim.<user>/<rand>/nvim.<pid>.0
-- Kept in sync with run_root() in lua/config/server.lua: without
-- XDG_RUNTIME_DIR, stdpath("run") is this process's own temp dir, so step up to
-- the shared `nvim.<user>` dir holding every socket.
local function run_root()
    local run = vim.fn.stdpath("run")
    local xdg = vim.env.XDG_RUNTIME_DIR
    if (xdg == nil or xdg == "") and not vim.fn.fnamemodify(run, ":t"):match("^nvim%.") then
        run = vim.fn.fnamemodify(run, ":h")
    end
    return run
end

local function sockets()
    local seen, found = {}, {}
    local function add(path)
        if path and path ~= "" and not seen[path] and vim.fn.getftype(path) == "socket" then
            seen[path] = true
            table.insert(found, path)
        end
    end
    for _, path in ipairs(vim.fn.glob(run_root() .. "/**/nvim.*", true, true)) do
        add(path)
    end
    add(vim.env.NVIM) -- a forwarded socket can live outside run_root
    return found
end

-- vim.g.agent_notify_focused is set by lua/config/agent_notify.lua, and is nil
-- on a server that has never seen a focus event
local PROBE = [[
return { ui = #vim.api.nvim_list_uis() > 0, focused = vim.g.agent_notify_focused }
]]

local DELIVER = [[
local payload = ...
local ok, mod = pcall(require, "config.agent_notify")
if ok and type(mod) == "table" and type(mod.handle) == "function" then
    mod.handle(payload)
else
    -- a server running some other config still deserves the message
    vim.schedule(function()
        vim.notify(payload.headline or "finished", vim.log.levels.INFO, { title = payload.agent })
    end)
end
return true
]]

local function request(path, code, args)
    local connected, chan = pcall(vim.fn.sockconnect, "pipe", path, { rpc = true })
    if not connected or type(chan) ~= "number" or chan <= 0 then
        return nil
    end
    local sent, result = pcall(vim.fn.rpcrequest, chan, "nvim_exec_lua", code, args)
    pcall(vim.fn.chanclose, chan)
    return sent and result or nil
end

local owner = vim.env.NVIM
local focused, with_ui, owner_has_ui = {}, {}, false
local targets, reason

-- Ask the agent's own server first. If it is the focused one, rule 1 below has
-- already won and sweeping the rest cannot change the verdict, so don't pay for
-- it: two round trips instead of one per live socket, and no chance of stalling
-- on some unrelated server stuck in synchronous code. Every other answer --
-- unfocused, headless, dead, or no owner at all (an agent outside nvim) -- falls
-- through to the full sweep unchanged, which is what finds the window you hopped
-- to. The counts logged for this path cover only the server we asked.
local probed = {}
if owner then
    probed[owner] = request(owner, PROBE, {})
    local state = probed[owner]
    if type(state) == "table" and state.ui and state.focused then
        focused, with_ui = { owner }, { owner }
        targets, reason = { owner }, "owner-focused"
    end
end

if not targets then
    for _, path in ipairs(sockets()) do
        local state = probed[path] or request(path, PROBE, {})
        if type(state) == "table" and state.ui then
            table.insert(with_ui, path)
            if state.focused then
                table.insert(focused, path)
            end
            owner_has_ui = owner_has_ui or path == owner
        end
    end

    if #focused > 0 then
        targets, reason = focused, "focused"
    elseif owner_has_ui then
        targets, reason = { owner }, "owner"
    elseif #with_ui > 0 then
        targets, reason = with_ui, "any-ui"
    else
        -- nobody is watching: leave it in the owning server's message history
        targets, reason = owner and { owner } or {}, "history"
    end
end

local delivered = {}
for _, path in ipairs(targets) do
    if request(path, DELIVER, { payload }) == true then
        table.insert(delivered, vim.fn.fnamemodify(path, ":t"))
    end
end

local function log(line)
    local path = vim.fn.stdpath("state") .. "/agent-notify.log"
    local ok, lines = pcall(vim.fn.readfile, path)
    lines = (ok and type(lines) == "table") and lines or {}
    table.insert(lines, line)
    if #lines > 200 then
        lines = vim.list_slice(lines, #lines - 199, #lines)
    end
    pcall(vim.fn.writefile, lines, path)
end

log(
    ("%s %s/%s cwd=%s ui=%d focused=%d via=%s sent=%d%s"):format(
        os.date("%Y-%m-%d %H:%M:%S"),
        agent,
        event,
        payload.cwd or "?",
        #with_ui,
        #focused,
        reason,
        #delivered,
        #delivered > 0 and (" [" .. table.concat(delivered, " ") .. "]") or ""
    )
)

os.exit(0)
