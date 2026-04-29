local M = {}
local Window = {}
function Window.create_tmp_float_window()
    -- create a scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = "win",
        width = 20, -- this depends on font and terminal i suppose, put magic number here for now
        height = 10,
        row = 0,
        col = 0,
        anchor = "NW",
        style = "minimal"
    }
    vim.api.nvim_open_win(buf, 0, opts)
end
M.Window = Window
return M
