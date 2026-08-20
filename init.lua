local STABLE = false
vim.g.stable_mode = STABLE

-- "core" will be installed in stable mode, "extra" does not.
local modules = {
    { "config.plugins",       tier = "core" },
    { "config.options",       tier = "core" },
    { "config.statusline",    tier = "extra" },
    { "config.statuscolumn",  tier = "extra" },
    { "config.plugin_config", tier = "extra" },
    { "config.lsp",           tier = "core" },
    { "config.treesitter",    tier = "core" },
    { "config.scopeline",     tier = "extra" },
    { "config.orgview",       tier = "extra" },
    { "config.filetree",      tier = "extra" },
    { "config.image",         tier = "extra", min = "0.13" },
    { "config.server",        tier = "extra" },
    { "config.worktree",      tier = "extra" },
    { "config.agent_notify",  tier = "extra" },
}

local failures, skipped = {}, {}

for _, mod in ipairs(modules) do
    local name = mod[1]
    if STABLE and mod.tier ~= "core" then
        skipped[#skipped + 1] = { name = name, why = "stable mode" }
    elseif mod.min and vim.fn.has("nvim-" .. mod.min) == 0 then
        skipped[#skipped + 1] = { name = name, why = "needs nvim " .. mod.min }
    else
        local ok, err = pcall(require, name)
        if not ok then
            package.loaded[name] = nil
            failures[#failures + 1] = { name = name, err = tostring(err) }
        end
    end
end

if #failures > 0 then
    vim.schedule(function()
        vim.notify(
            ("config: %d module(s) failed to load - :ConfigHealth"):format(#failures),
            vim.log.levels.ERROR
        )
    end)
end

vim.api.nvim_create_user_command("ConfigHealth", function()
    local lines = {
        "profile : " .. (STABLE and "STABLE (core tier only)" or "full"),
        "nvim    : " .. tostring(vim.version()),
        "modules : " .. (#modules - #failures - #skipped) .. " loaded, "
            .. #failures .. " failed, " .. #skipped .. " skipped",
        "",
    }
    if #failures == 0 then
        lines[#lines + 1] = "failed  : none"
    else
        lines[#lines + 1] = "FAILED:"
        for _, f in ipairs(failures) do
            lines[#lines + 1] = "  " .. f.name
            for _, l in ipairs(vim.split(f.err, "\n", { trimempty = true })) do
                lines[#lines + 1] = "      " .. l
            end
        end
    end
    if #skipped > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "skipped:"
        for _, s in ipairs(skipped) do
            lines[#lines + 1] = string.format("  %-24s %s", s.name, s.why)
        end
    end
    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.buftype = "nofile"
    vim.bo.modifiable = false
end, { desc = "Config profile, load failures and skipped modules" })

-- color theme
-- git clone --depth 1 https://github.com/stanfish06/dark-theme.git ~/.config/nvim/pack/plugins/start/dark-theme
-- vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
pcall(vim.cmd.colorscheme, "dark")

-- usage tips
    -- check path of current file
        -- :lua print(vim.api.nvim_buf_get_name(0))
        -- <C-g> shows relative path
        -- 1 + <C-g> shows full path
    -- when navigating large code base, prefer built-in vim search instead of fuzzy finders
        -- use <C-d> when you do :b (for navigating buffers) or :e (for navigating files) to get a preview of available options
        -- you can do something like :e *EA* then press <C-d>, which will filter the preview list using the regex to get you for instance just README.md
        -- you can also do recursive preview, for instance in this repo, you can do :e lua/**/ then <C-d> you can see files under subdirectories
        -- prefer git grep over regular grep when working in large code base
    -- gx is useful to open the buf under cursor using default program (e.g. open web link)
    -- gf opens file under current cursor
    -- bd to kill buffer
    -- read !cmd to read shell command to current buffer
    -- use marks
        -- m<latter> to mark file&line
        -- `<letter> to jump
        -- :marks to check marks
        -- marks work in terminal too, very useful to mark for instance ai chat and jump from place to place
        -- a-z marks are restrict per-buffer
        -- A-Z/0-9 marks persist across tabs too
    -- lcd allows you to set root directory for current window, which might be useful in some cases
    -- <C-w o> or :only allows you to close all window except the current one, useful in case you have splits and you want to keep and maximize the current one only
    -- <C-c> allows you to change from insert/command mode to normal, maybe useful if you find esc annoying
    -- :set readonly and :set noreadonly to toggle read-only mode
    -- navigate across tabs
        -- gt and gT to move back and forth
        -- g<tab> to go back to last tab
    -- use terminal
        -- :te to open terminal
        -- tabe | te program open terminal and launch program in a new tab (preferred way)
    -- code fold
        -- zo/zO to open (recursively) the folds
        -- zc/zC to close (recursively) the folds
        -- za toggles fold
        -- zR/zM open/close all
    -- lsp
      -- :lsp restart [client_name]   " restart named client (or all attached to current buf)
      -- :lsp stop    [client_name]   " stop
      -- :lsp enable  [config_name]   " activate for current + future buffers
      -- :lsp disable [config_name]   " disable and stop
    -- useful vim motions:
        -- textobjects:
            -- inside
                -- change/visual/yank/delete inside: c/v/y/d + i + delimiter (e.g. foo "bar" -> ci" -> foo "│")
            -- across
                -- same as inside, you just swap i with a, then delimiter will be included too
            -- can use treesitter to have more advanced textobjects such as function, etc
        -- ]/[ (read :help ] or [ for full manual)
            -- ]/[ + space: add blank lines below or above
            -- ]/[ + m/M: jump below or above to method start(m)/end(M) (limited to some languages, treesitter-textobjects has ]\[ + f/c for function and class)
                -- for now, I enabled ]\[ + f/F and ]\[ + c/C with treesitter-textobjects
            -- ]/[ + b: jump buffers
            -- ]/[ + (/)/{/}: jump to prev/next unmatched (/)/{/} (work if you are inside balanced parans/curly brackets)

-- cool features potentially to try
    -- terminal events (check help terminal)
        -- OSC 7 you can make neovim change working directory by letting shell emit this code

-- by default, makeprg is make, so :make uses make, but you can set it to empty string that allows you to run anything and pop output in a buf
    -- you can now do ls, grep, make, etc (e.g. :make ls, :make grep, :make make)
-- you can set anything you want, such as gmake, latex, etc
-- to check make output, you can use :copen
vim.opt.makeprg = ""
