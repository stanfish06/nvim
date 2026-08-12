local M = {}

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "worktree" })
end

-- parses `git worktree list --porcelain`; entries are separated by blank
-- lines but vim.split(trimempty) already drops those, so a fresh "worktree "
-- line is what actually starts a new entry
local function list_worktrees()
    local res = vim.system({ "git", "worktree", "list", "--porcelain" }, { text = true }):wait()
    if res.code ~= 0 then
        local msg = res.stderr and res.stderr ~= "" and res.stderr or "git worktree list failed"
        return nil, vim.trim(msg)
    end

    local worktrees, current = {}, nil
    for _, line in ipairs(vim.split(res.stdout or "", "\n", { trimempty = true })) do
        local path = line:match("^worktree (.+)$")
        if path then
            current = { path = path }
            table.insert(worktrees, current)
        elseif current then
            local branch = line:match("^branch refs/heads/(.+)$")
            if branch then
                current.branch = branch
            elseif line == "detached" then
                current.detached = true
            elseif line == "bare" then
                current.bare = true
            elseif line:match("^locked") then
                current.locked = true
            end
        end
    end
    return worktrees
end

-- best-effort base branch for diffing when none is given: try the common
-- local names first, then fall back to whatever the remote's HEAD points at
local function default_base_branch()
    for _, cand in ipairs({ "master", "main" }) do
        if vim.system({ "git", "rev-parse", "--verify", "--quiet", cand }):wait().code == 0 then
            return cand
        end
    end
    local res = vim.system({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, { text = true }):wait()
    if res.code == 0 then
        return (vim.trim(res.stdout):gsub("^origin/", ""))
    end
    return nil
end

-- switch the running session into a worktree: `opts.tab` opens a fresh tab
-- first, otherwise the current tab's directory is changed in place
function M.switch(path, opts)
    opts = opts or {}
    if opts.tab then
        vim.cmd.tabnew()
    end
    local ok, err = pcall(vim.cmd.tcd, path)
    if not ok then
        notify("cd failed: " .. tostring(err), vim.log.levels.ERROR)
        return
    end
    notify("worktree: " .. vim.fn.fnamemodify(path, ":~"))
end

function M.list()
    local worktrees, err = list_worktrees()
    if not worktrees then
        notify(err, vim.log.levels.ERROR)
        return
    end
    if #worktrees == 0 then
        notify("no worktrees found", vim.log.levels.WARN)
        return
    end

    local entries, lookup = {}, {}
    for _, wt in ipairs(worktrees) do
        local label = wt.branch or (wt.detached and "(detached)") or "(bare)"
        local display = string.format("%-28s %s", label, vim.fn.fnamemodify(wt.path, ":~"))
        table.insert(entries, display)
        lookup[display] = wt
    end

    local function handle(display, switch_opts)
        local wt = lookup[display]
        if wt then
            M.switch(wt.path, switch_opts)
        end
    end

    local fzf_ok, fzf = pcall(require, "fzf-lua")
    if fzf_ok then
        fzf.fzf_exec(entries, {
            prompt = "Worktrees> ",
            actions = {
                ["default"] = function(selected)
                    handle(selected[1], { tab = true })
                end,
                ["ctrl-x"] = function(selected)
                    handle(selected[1], { tab = false })
                end,
                ["ctrl-y"] = function(selected)
                    local wt = lookup[selected[1]]
                    if wt then
                        vim.fn.setreg("+", wt.path)
                        notify("copied: " .. wt.path)
                    end
                end,
            },
        })
    else
        vim.ui.select(entries, { prompt = "Worktree (Enter: new tab)" }, function(choice)
            if choice then
                handle(choice, { tab = true })
            end
        end)
    end
end

-- diff the current worktree's working tree against `base` (default:
-- master/main); this is exactly `git diff base`, just via diffview
function M.diff_base(base)
    base = base and base ~= "" and base or default_base_branch()
    if not base then
        notify("could not detect master/main; pass a ref, e.g. :WorktreeDiff main", vim.log.levels.WARN)
        return
    end
    local ok = pcall(vim.cmd.DiffviewOpen, base)
    if not ok then
        notify("diffview.nvim is not installed", vim.log.levels.WARN)
    end
end

vim.api.nvim_create_user_command("Worktrees", M.list, {
    desc = "List worktrees; <CR> opens in a new tab, <C-x> in the current tab, <C-y> copies the path",
})

vim.api.nvim_create_user_command("WorktreeDiff", function(opts)
    M.diff_base(opts.args)
end, {
    nargs = "?",
    desc = "Diff current worktree against master/main (or the given ref)",
})

vim.keymap.set("n", "<leader>sw", M.list, { desc = "Worktrees (switch)" })
vim.keymap.set("n", "<leader>gm", function()
    M.diff_base()
end, { desc = "Diff vs master/main" })

return M
