-- scope line
local valid_scopes = {
    -- C / C++ / Go / JS / TS
    ["function_declaration"] = true,
    ["function_definition"] = true,
    ["method_declaration"] = true,
    ["if_statement"] = true,
    ["for_statement"] = true,
    ["while_statement"] = true,
    -- Rust
    ["function_item"] = true,
    ["impl_item"] = true,
    ["match_expression"] = true,
    ["closure_expression"] = true,
    ["if_expression"] = true,
    ["for_expression"] = true,
    ["while_expression"] = true,
    ["loop_expression"] = true,
    -- TypeScript / JavaScript
    ["arrow_function"] = true,
    ["method_definition"] = true,
    ["class_declaration"] = true,
    -- Python
    ["with_statement"] = true,
    ["try_statement"] = true,
    ["match_statement"] = true,
    -- Lua
    ["do_statement"] = true,
    -- Shared
    ["type_declaration"] = true,
}
local ns_scope_line = vim.api.nvim_create_namespace("scope_line")
function char_at(row, col)
    -- row is 1-based, col is 1-based
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
    return string.sub(line, col, col)
end
local function draw_scope_lines()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, ns_scope_line, 0, -1)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local ts_node = vim.treesitter.get_node({ pos = { cursor[1] - 1, cursor[2] } })
    while ts_node do
        if valid_scopes[ts_node:type()] then
            local start_row, start_col, end_row, end_col = ts_node:range()
            for i = start_row + 1, end_row do
                local char = char_at(i + 1, start_col + 1) -- treesitter is 0 based
                if char == " " or char == "" then
                    local scope_char = "│"
                    if i == start_row + 1 and (end_row - start_row) > 1 then
                        scope_char = "┌"
                    end
                    if i == end_row and (end_row - start_row) > 1 then
                        scope_char = "└"
                    end
                    pcall(
                        vim.api.nvim_buf_set_extmark,
                        buf,
                        ns_scope_line,
                        i,
                        0,
                        { virt_text = { { scope_char, "ScopeLine" } }, virt_text_pos = "overlay", virt_text_win_col = start_col } -- color group ScopeLine is defined in statusline.lua
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
