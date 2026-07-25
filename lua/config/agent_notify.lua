-- In-editor notifications for terminal coding agents (Claude Code, Codex).
--
-- An agent runs in a :terminal buffer, so "is it done yet?" becomes invisible
-- the moment you move to another window, tab or server. The agents' finish
-- hooks call scripts/agent-notify.sh, which RPCs into the live server(s) and
-- lands here, turning the event into a plain vim.notify.
--
-- Wiring lives outside this repo (see scripts/agent-notify.lua for the
-- delivery rules):
--   ~/.claude/settings.json   Stop + Notification hooks
--   ~/.codex/config.toml      notify -> ~/.codex/notify-dispatch.sh
--
-- :AgentNotifyTest [agent]   fake a delivery to check the plumbing still works
-- M.last[agent]              most recent event, for statusline use
-- Missed one? snacks notifier keeps history: :lua Snacks.notifier.show_history()
--
-- This module must be loaded in every server (init.lua) for the focus tracking
-- below to work — that is how the dispatcher finds the window you are watching.

local M = {}

local AGENTS = {
    claude = "Claude Code",
    codex = "Codex",
}

local LEVELS = {
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
}

M.last = {}

local function shorten(text, limit)
    text = vim.trim((text or ""):gsub("%s+", " "))
    if text == "" then
        return nil
    end
    if vim.fn.strchars(text) > limit then
        return vim.fn.strcharpart(text, 0, limit - 1) .. "…"
    end
    return text
end

-- payload arrives over RPC from scripts/agent-notify.lua; every field is
-- optional because hook JSON shapes differ per agent and per event
function M.handle(payload)
    payload = type(payload) == "table" and payload or {}
    local agent = tostring(payload.agent or "agent")
    local headline = payload.headline or "finished"
    local where = payload.cwd and vim.fn.fnamemodify(payload.cwd, ":~") or nil
    local detail = shorten(payload.detail, 200)

    M.last[agent] = { at = os.time(), headline = headline, cwd = payload.cwd, detail = detail }

    local lines = { where and (headline .. " · " .. where) or headline }
    if detail then
        table.insert(lines, detail)
    end

    -- an RPC request runs on the main loop, but vim.notify may open a float
    -- (snacks notifier), so let the scheduler pick a safe moment
    vim.schedule(function()
        vim.notify(
            table.concat(lines, "\n"),
            LEVELS[payload.level or "info"] or LEVELS.info,
            { title = AGENTS[agent] or agent }
        )
    end)
end

-- With several nvim windows open, several servers have a UI attached but only
-- one is on screen. Terminal focus reporting (ghostty supports it) is the only
-- signal that says which -- and Nvim keeps no readable copy of it: focus
-- arrives as an event and is gone, there is no getter (only the UI-side
-- nvim_ui_set_focus() push). So latch it into a global the dispatcher can read
-- over RPC. Three states matter: true (told it gained focus), false (told it
-- lost it), nil (never told anything).
--
-- UIEnter/UILeave close the case that would otherwise sit at nil: a server that
-- just received a UI by hopping (lua/config/server.lua) has never seen a focus
-- event, so it reads as "unknown" and the dispatcher falls back to notifying
-- every window at once. A UI attaching means the terminal that attached it is
-- the one in use; a UI leaving means nothing is on screen here.
vim.api.nvim_create_autocmd({ "FocusGained", "FocusLost", "UIEnter", "UILeave" }, {
    group = vim.api.nvim_create_augroup("agent_notify_focus", { clear = true }),
    desc = "Track terminal focus so agent notifications land on screen",
    callback = function(ev)
        vim.g.agent_notify_focused = ev.event == "FocusGained" or ev.event == "UIEnter"
    end,
})

vim.api.nvim_create_user_command("AgentNotifyTest", function(o)
    M.handle({
        agent = o.args ~= "" and o.args or "claude",
        headline = "finished",
        cwd = vim.fn.getcwd(),
        detail = "test delivery from :AgentNotifyTest",
    })
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_keys(AGENTS)
    end,
    desc = "Fake an agent finish notification",
})

return M
