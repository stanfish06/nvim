-- scope line
local valid_scopes = {
	["function_declaration"] = true,
	["function_definition"] = true,
	["if_statement"] = true,
	["for_statement"] = true,
	["while_statement"] = true,
}
local ns_scope_line = vim.api.nvim_create_namespace("scope_line")
function char_at(row, col)
	-- row is 1-based, col is 1-based
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
	return string.sub(line, col, col)
end
function draw_scope_lines()
	local buf = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(buf, ns_scope_line, 0, -1)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local ts_node = vim.treesitter.get_node({ pos = { cursor[1], cursor[2] } })
	while ts_node do
		if valid_scopes[ts_node:type()] then
			local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(ts_node)
			for i = start_row + 1, end_row - 1 do
				local char = char_at(i + 1, start_col + 1) -- treesitter is 0 based
				if char == " " then
					pcall(
						vim.api.nvim_buf_set_extmark,
						buf,
						ns_scope_line,
						i,
						start_col,
						{ virt_text = { { "|", {} } }, virt_text_pos = "overlay" }
					)
				end
			end
			break
		end
		ts_node = ts_node:parent()
	end
end
vim.api.nvim_create_augroup("ScopeLines", { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
	group = "ScopeLines",
	callback = draw_scope_lines,
})
