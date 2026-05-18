require("config.plugins")
require("config.options")
require("config.statusline")
require("config.plugin_config")
require("config.treesitter")
require("config.scopeline")
require("config.image")

-- color theme
-- git clone --depth 1 https://github.com/stanfish06/dark-theme.git ~/.config/nvim/pack/plugins/start/dark-theme
-- vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
pcall(vim.cmd.colorscheme, "dark")

-- usage tips
    -- when navigating large code base, prefer built-in vim search instead of fuzzy finders
        -- use <C-d> when you do :b (for navigating buffers) or :e (for navigating files) to get a preview of available options
        -- you can do something like :e *EA* then press <C-d>, which will filter the preview list using the regex to get you for instance just README.md
        -- you can also do recursive preview, for instance in this repo, you can do :e lua/**/ then <C-d> you can see files under subdirectories
        -- prefer git grep over regular grep when working in large code base
    -- gx is useful to open the buf under cursor using default program (e.g. open web link)
    -- gf opens file under current cursor
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
