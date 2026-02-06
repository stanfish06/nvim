-- fzf
-- git clone --depth 1 https://github.com/ibhagwan/fzf-lua.git ~/.config/nvim/pack/plugins/start/fzf-lua
local ok, fzf = pcall(require, "fzf-lua")
if ok then
	vim.keymap.set("n", "<leader><leader>", fzf.files)
	vim.keymap.set("n", "<leader>/", fzf.live_grep)
	vim.keymap.set("n", "<leader>sl", fzf.lines)
	vim.keymap.set("n", "<leader>sb", fzf.buffers)
end

-- sneaks
-- git clone --depth 1 https://github.com/justinmk/vim-sneak ~/.config/nvim/pack/plugins/start/vim-sneak

-- lsp
-- git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
-- after v12, neovim will have built-in package manager
-- lua
vim.lsp.config["luals"] = {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
		},
	},
}
vim.lsp.enable("luals")
-- uv tool install pyright
vim.lsp.enable("pyright")
-- install per project
vim.lsp.enable("pyrefly")
-- install using system package manager
vim.lsp.enable("clangd")
-- npm instal -g typescript-language-server
vim.lsp.enable("ts_ls")

-- gitsigns
local gs_ok, gitsigns = pcall(require, "gitsigns")
if gs_ok then
	gitsigns.setup({
		on_attach = function(bufnr)
			local gs = require("gitsigns")
			local function map(mode, l, r, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end
			map("n", "]c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end)
			map("n", "[c", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end)
			map("n", "<leader>hs", gs.stage_hunk)
			map("n", "<leader>hr", gs.reset_hunk)
			map("n", "<leader>hp", gs.preview_hunk)
			map("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end)
			map("n", "<leader>hd", gs.diffthis)
			map("n", "<leader>tb", gs.toggle_current_line_blame)
		end,
	})
end

-- conform (formatting)
local conform_ok, conform = pcall(require, "conform")
if conform_ok then
	conform.setup({
		default_format_opts = {
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format" },
			javascript = { "prettier" },
			typescript = { "prettier" },
		},
	})
	vim.keymap.set("n", "<leader>lf", function()
		conform.format()
	end, { desc = "Format buffer" })
	vim.keymap.set("v", "<leader>lf", function()
		conform.format()
	end, { desc = "Format selection" })
end
