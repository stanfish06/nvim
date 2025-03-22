-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  -- { "EdenEast/nightfox.nvim" },
  -- { "rose-pine/neovim", name = "rose-pine" },
  -- { "catppuccin/nvim", name = "catppuccin" },
  -- {
  --   "LazyVim/LazyVim",
  --   opts = {
  --     colorscheme = "nightfox",
  --   },
  -- },

  {
    "xiyaowong/transparent.nvim",
    lazy = false,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    -- enabled = false,
    opts = {
      ensure_installed = {},
    },
    config = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        opts.ensure_installed = LazyVim.dedup(opts.ensure_installed)
      end
      require("nvim-treesitter.configs").setup(opts)
      require("nvim-treesitter.install").prefer_git = false
      require("nvim-treesitter.install").compilers = { "cl", "gcc" }
    end,
  },

  -- {
  --   "nvim-neorg/neorg",
  --   lazy = false,
  --   version = "*",
  --   run = ":Neorg sync-parsers",
  --   ft = "norg",
  --   opts = {
  --     load = {
  --       ["core.defaults"] = {},
  --       ["core.concealer"] = {},
  --       ["core.dirman"] = {
  --         config = {
  --           workspaces = {
  --             notes = "~/Dropbox (Personal)/PC (2)/Desktop/umich/notes",
  --             notes_idse = "~/Dropbox (Personal)/PC (2)/Desktop/umich/notes_idse",
  --           },
  --         },
  --       },
  --     },
  --   },
  -- },

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },

  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
    },
  },

  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      picker = { enabled = true },
      image = { enabled = true, force = true },
      dashboard = {
        enabled = true,
        sections = {
          {
            section = "terminal",
            align = "center",
            cmd = "wsl --exec colorscript -e dna2",
            height = 8,
            indent = 2,
            padding = 1,
          },
          {
            pane = 2,
            section = "terminal",
            cmd = "wsl --exec colorscript -e square",
            height = 5,
            padding = 1,
          },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = "startup" },
        },
      },
      indent = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },
}
