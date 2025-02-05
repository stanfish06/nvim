-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- for clipboard in vscode
if vim.g.vscode then
  -- https://github.com/vscode-neovim/vscode-neovim/issues/298
  vim.opt.clipboard:append("unnamedplus")
end
