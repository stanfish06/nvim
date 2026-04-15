require("config.plugins")
require("config.options")
require("config.statusline")
require("config.plugin_config")
require("config.treesitter")
require("config.scopeline")

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
    -- read !cmd to read shell command to current buffer
    -- use marks
        -- m<latter> to mark file&line
        -- `<letter> to jump
        -- :marks to check marks
    -- lcd allows you to set root directory for current window, which might be useful in some cases
    -- <C-w o> or :only allows you to close all window except the current one, useful in case you have splits and you want to keep and maximize the current one only
    -- <C-c> allows you to change from insert/command mode to normal, maybe useful if you find esc annoying

-- by default, makeprg is make, so :make uses make, but you can set it to empty string that allows you to run anything and pop output in a buf
    -- you can now do ls, grep, make, etc (e.g. :make ls, :make grep, :make make)
-- you can set anything you want, such as gmake, latex, etc
-- to check make output, you can use :copen 
vim.opt.makeprg = ""
