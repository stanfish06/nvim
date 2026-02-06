-- treesitter
-- git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/plugins/start/nvim-treestter
-- require tree-sitter-cli (do npm install -g tree-sitter-cli)

-- this function needs to be updated occasionally, as of 260130, glibc should be at least 2.30
local function get_glibc_version()
	local handle = io.popen("ldd --version 2>&1 | head -n1")
	if not handle then
		return nil
	end
	local result = handle:read("*a")
	handle:close()

	local version = result:match("(%d+%.%d+)%s*$") or result:match("GLIBC (%d+%.%d+)")
	if version then
		return tonumber(version)
	end
	return nil
end

local function has_tree_sitter_cli()
	return vim.fn.executable("tree-sitter") == 1
end

local function can_auto_install_parsers()
	local glibc_version = get_glibc_version()
	local has_cli = has_tree_sitter_cli()

	if glibc_version and glibc_version < 2.30 then
		vim.notify(
			string.format(
				"Tree-sitter parser install skipped: glibc %.2f < 2.30 (e.g. compile parsers manually)",
				glibc_version
			),
			vim.log.levels.WARN
		)
		return false
	end

	if not has_cli then
		vim.notify("Tree-sitter parser install skipped: tree-sitter-cli not found (e.g. use npm)", vim.log.levels.WARN)
		return false
	end

	return true
end

local ts_status, ts = pcall(require, "nvim-treesitter")
if ts_status and can_auto_install_parsers() then
	ts.install({
		"c",
		"python",
		"julia",
		"cpp",
		"bash",
		"lua",
		"vim",
		"vimdoc",
		"javascript",
		"markdown",
		"markdown_inline",
	})
end
local function is_ts_enabled()
	local bufnr = vim.api.nvim_get_current_buf()
	return vim.treesitter.highlighter.active[bufnr] ~= nil
end
function ts_highlight()
	if is_ts_enabled() then
		vim.treesitter.stop()
	else
		vim.treesitter.start()
	end
end
vim.api.nvim_create_user_command("TSBufToggle", ts_highlight, {})
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "*" },
	callback = function()
		local ok, err = pcall(vim.treesitter.start)
		if not ok then
			vim.cmd("syntax on")
		end
	end,
})
