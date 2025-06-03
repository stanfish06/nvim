-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
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

  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      lspFeatures = {
        enabled = true,
        languages = { "r", "python", "julia", "bash", "html" },
        chunks = "curly",
        completion = {
          enabled = true,
        },
      },
      codeRunner = {
        enabled = true,
        default_method = "slime",
        ft_runners = {
          python = "molten",
        },
      },
    },
  },

  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    dependencies = "willothy/wezterm.nvim",
    init = function()
      vim.g.molten_auto_open_output = false -- cannot be true if molten_image_provider = "wezterm"
      vim.g.molten_output_show_more = true
      vim.g.molten_image_provider = "wezterm"
      vim.g.molten_output_virt_lines = true
      vim.g.molten_split_direction = "right" --direction of the output window, options are "right", "left", "top", "bottom"
      vim.g.molten_split_size = 40 --(0-100) % size of the screen dedicated to the output window
      vim.g.molten_virt_text_output = true
      vim.g.molten_use_border_highlights = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_auto_image_popup = false
      vim.g.python3_host_prog =
        vim.fn.expand("C:/Users/zhiyu/Dropbox (Personal)/PC (2)/Desktop/Git/neovim-py/.venv/Scripts/python.exe")
    end,
  },

  {
    "nvim-neorg/neorg",
    lazy = false,
    version = "*",
    run = ":Neorg sync-parsers",
    ft = "norg",
    opts = {
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              notes = "~/Dropbox (Personal)/PC (2)/Desktop/umich/notes",
            },
          },
        },
      },
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
      lazygit = {},
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
    keys = {
      {
        "<leader>fz",
        function()
          Snacks.picker.zoxide({
            finder = "files_zoxide",
            format = "file",
            confirm = "load_session",
            win = {
              preview = {
                minimal = true,
              },
            },
          })
        end,
        desc = "zoxide",
      },
    },
  },

  -- formatter
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
        qmd = { "pyright" },
      },
    },
  },

  {
    -- directly open ipynb files as quarto docuements
    -- and convert back behind the scenes
    -- make sure you have jupytext python package installed
    "GCBallesteros/jupytext.nvim",
    opts = {
      custom_language_formatting = {
        python = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
        r = {
          extension = "qmd",
          style = "quarto",
          force_ft = "quarto",
        },
      },
    },
  },

  {
    "saghen/blink.cmp",
    keys = {
      {
        "<C-e>",
        function()
          require("blink.cmp").show()
        end,
        mode = { "i" },
      },
    },
  },
}
