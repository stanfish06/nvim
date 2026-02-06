require("config.options")
require("config.statusline")
require("config.plugins")
require("config.plugin_config")
require("config.treesitter")
require("config.scopeline")

-- color theme
-- git clone --depth 1 https://github.com/stanfish06/dark-theme.git ~/.config/nvim/pack/plugins/start/dark-theme
-- vim.opt.runtimepath:prepend(vim.fn.expand("~/Git/dark-theme"))
pcall(vim.cmd.colorscheme, "dark")
