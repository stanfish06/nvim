-- note for potential retard agents: do not fucking delete nerd font symbols
-- status
-- callback that runs every time after colorscheme changes to make sure statusline stay the same
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        vim.api.nvim_set_hl(0, "StatusLineModeNormal", { bg = "#98C379", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeInsert", { bg = "#C678DD", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeVisual", { bg = "#E5C07B", fg = "black" })
        vim.api.nvim_set_hl(0, "StatusLineModeNormalAlt", { fg = "#98C379", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "StatusLineModeInsertAlt", { fg = "#C678DD", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "StatusLineModeVisualAlt", { fg = "#E5C07B", bg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "CursorInfo", { bg = "#B8C0E0", fg = "black" })
        vim.api.nvim_set_hl(0, "CursorInfoAlt", { fg = "#B8C0E0", bg = "#3E8FB0" })
        vim.api.nvim_set_hl(0, "Git", { bg = "#3A3A3A", fg = "#E5C07B" })
        vim.api.nvim_set_hl(0, "LspClients", { bg = "#3A3A3A", fg = "#719E07" })
        vim.api.nvim_set_hl(0, "File", { bg = "#3A3A3A", fg = "#ABEBE2" })
        vim.api.nvim_set_hl(0, "FileAlt", { fg = "#3A3A3A" })
        vim.api.nvim_set_hl(0, "FileType", { fg = "black", bg = "#3E8FB0" })
        vim.api.nvim_set_hl(0, "FileTypeAlt", { fg = "#3E8FB0" })
        vim.api.nvim_set_hl(0, "StatusLineDiag", { bg = "#7E85A5", fg = "black" })
        vim.cmd("redrawstatus")
    end,
})

-- git sign
local function current_git_branch()
    local ok, gs = pcall(require, "gitsigns")
    if not ok then
        return ""
    end
    local branch = vim.b.gitsigns_head
    if not branch or branch == "" then
        return ""
    end
    return " %#Git#  " .. branch .. " " .. "%*"
end

local function current_buf_flags()
    local flags = ""
    if vim.bo.modified then
        flags = flags .. " %#DiagnosticWarn#[+]%*"
    end
    if vim.bo.readonly or not vim.bo.modifiable then
        flags = flags .. " %#DiagnosticError#[RO]%*"
    end
    return flags
end

local lsp_progress = {}
local lsp_spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local lsp_progress_timer = nil

local function statusline_escape(text)
    if not text or text == "" then
        return ""
    end
    return (text:gsub("%%", "%%%%"))
end

local function ensure_lsp_progress_timer()
    if lsp_progress_timer then
        return
    end
    lsp_progress_timer = vim.uv.new_timer()
    if not lsp_progress_timer then
        return
    end
    lsp_progress_timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if vim.tbl_isempty(lsp_progress) then
                if lsp_progress_timer then
                    lsp_progress_timer:stop()
                    lsp_progress_timer:close()
                    lsp_progress_timer = nil
                end
                return
            end
            vim.cmd("redrawstatus")
        end)
    )
end

vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(ev)
        local data = ev.data
        if not data or not data.params or not data.params.value then
            return
        end

        local val = data.params.value
        local client_id = data.client_id
        if not client_id then
            return
        end

        local token = data.params.token
        if token == nil then
            token = "__default"
        end
        lsp_progress[client_id] = lsp_progress[client_id] or {}

        if val.kind == "end" then
            lsp_progress[client_id][token] = nil
            if vim.tbl_isempty(lsp_progress[client_id]) then
                lsp_progress[client_id] = nil
            end
        else
            local prev = lsp_progress[client_id][token] or {}
            local title = val.title or prev.title
            local message = val.message or prev.message
            lsp_progress[client_id][token] = {
                title = title,
                message = message,
                percentage = val.percentage or prev.percentage,
            }
        end

        if not vim.tbl_isempty(lsp_progress) then
            ensure_lsp_progress_timer()
        end

        vim.cmd("redrawstatus")
    end,
})
local function current_lsp_clients()
    if not vim.lsp or not vim.lsp.get_clients then
        return ""
    end
    local ok, clients = pcall(vim.lsp.get_clients, { bufnr = 0 })
    if not ok or #clients == 0 then
        return ""
    end
    local names = {}
    for _, client in ipairs(clients) do
        if client and client.name and client.name ~= "" then
            table.insert(names, client.name)
        end
    end
    if #names == 0 then
        return ""
    end
    return " %#LspClients# [" .. table.concat(names, ", ") .. "] %*"
end

local function current_lsp_progress()
    if vim.tbl_isempty(lsp_progress) then
        return ""
    end

    local frame = math.floor(vim.uv.hrtime() / 1e8) % #lsp_spinners
    local msgs = {}
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local clients_by_id = {}
    for _, client in ipairs(clients) do
        clients_by_id[client.id] = true
    end

    for client_id, tokens in pairs(lsp_progress) do
        if clients_by_id[client_id] then
            for _, item in pairs(tokens) do
                local parts = {}
                if item.title and item.title ~= "" then
                    table.insert(parts, item.title)
                end
                if item.message and item.message ~= "" then
                    table.insert(parts, item.message)
                end
                local text = table.concat(parts, ": ")
                if text == "" then
                    text = "…"
                end
                if #text > 20 then
                    text = text:sub(1, 20) .. "..."
                end
                if item.percentage ~= nil then
                    text = text .. string.format(" (%d%%)", item.percentage)
                end
                table.insert(msgs, statusline_escape(text))
            end
        end
    end

    if #msgs == 0 then
        return ""
    end

    return "%#LspClients# " .. lsp_spinners[frame + 1] .. " " .. table.concat(msgs, ", ") .. " %*"
end
-- cursor
local function set_cursor_color()
    vim.api.nvim_set_hl(0, "myCursor", { fg = "#FFA500", bg = "#FFA500" })
    vim.api.nvim_set_hl(0, "myICursor", { fg = "#FFA500", bg = "#FFA500" })
end
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = set_cursor_color,
})
set_cursor_color()
vim.opt.guicursor = "n-v-c:block-myCursor,i-ci-ve:ver25-myICursor"
-- local SOLID_LEFT_ARROW = vim.fn.nr2char(0xe0b2)
-- local SOLID_RIGHT_ARROW = vim.fn.nr2char(0xe0b0)
local SOLID_LEFT_ARROW = "░▒▓" -- needs a nerd font
local SOLID_LEFT_ARROW_PART = "▓"
local SOLID_RIGHT_ARROW = "▓▒░"
local SOLID_RIGHT_ARROW_PART = "▓"
local function current_mode()
    local m = vim.fn.mode()
    local mode_map = {
        n = { text = "[N]", hl = "StatusLineModeNormal", hl_alt = "StatusLineModeNormalAlt" },
        i = { text = "[I]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
        v = { text = "[V]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        V = { text = "[VL]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        ["\22"] = { text = "[VB]", hl = "StatusLineModeVisual", hl_alt = "StatusLineModeVisualAlt" },
        R = { text = "[R]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
        c = { text = "[C]", hl = "StatusLineModeNormal", hl_alt = "StatusLineModeNormalAlt" },
        t = { text = "[T]", hl = "StatusLineModeInsert", hl_alt = "StatusLineModeInsertAlt" },
    }
    local mode_info = mode_map[m] or { text = "[?]", hl = "StatusLineModeNormal" }
    return string.format("%%#%s#%s%%*", mode_info.hl_alt, SOLID_LEFT_ARROW_PART)
        .. string.format("%%#%s#%s%%*", mode_info.hl, mode_info.text)
        .. string.format("%%#%s#%s%%*", mode_info.hl_alt, SOLID_RIGHT_ARROW)
end

local filetype_icons = {
    lua = "",
    python = "",
    rust = "󱘗",
    c = "",
    go = "󰟓",
    javascript = "󰌞",
    typescript = "󰛦",
}
-- set to false if no nerd font
vim.g.have_nerd_font = true
local function current_filetype()
    local filetype = vim.bo.filetype
    local color = "%#FileType# "
    local color_alt = "%#FileTypeAlt#"
    if not vim.g.have_nerd_font then
        return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. "  " .. " "
    else
        local icon = filetype_icons[filetype]
        if icon == nil then
            icon = ""
        else
            icon = " " .. icon
        end
        return "%=" .. color_alt .. SOLID_LEFT_ARROW .. "%*" .. color .. filetype .. icon .. ""
    end
end

local function current_file()
    -- local root_path = vim.uv.cwd() or ""
    -- this reflects lcd change cwd
    local root_path = vim.fn.getcwd(0, 0)
    local root_dir = root_path:match("[^/]+$") or ""
    local home_path = vim.fn.expand("%:~")
    -- BUG: this sometimes break (e.g. .config/nvim/lua/config will have two matches, so need better handling for these cases)
    local overlap, _ = home_path:find(root_dir)
    local color = "%#File# "
    local color_alt = "%#FileAlt#"
    if home_path == "" then
        return color .. root_path:gsub(vim.env.HOME, "~") .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    elseif overlap then
        return color .. home_path:sub(overlap) .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    else
        return color .. home_path .. " %*" .. color_alt .. SOLID_RIGHT_ARROW .. "%*"
    end
end

local function current_cursor_info()
    local linenr = vim.api.nvim_win_get_cursor(0)[1]
    local colnr = vim.fn.col(".")
    local nlines = vim.api.nvim_buf_line_count(0)
    local percentage = 0
    if nlines > 0 then
        percentage = (linenr / nlines) * 100
    end
    return ""
        .. "%#CursorInfoAlt#"
        .. SOLID_LEFT_ARROW
        .. "%*"
        .. "%#CursorInfo# "
        .. string.format("%.1f", percentage)
        .. "%% "
        .. string.format("%d:%d ", linenr, colnr)
        .. "%#CursorInfoAlt#"
        .. SOLID_RIGHT_ARROW_PART
end

local function current_diagnostics()
    local ok, _diag_tbl = pcall(vim.diagnostic.get, 0)
    if not ok then
        return ""
    end
    local _n_ERROR = 0
    local _n_WARN = 0
    local _n_INFO = 0
    local _n_HINT = 0
    for _, v in pairs(_diag_tbl) do
        if v.severity == vim.diagnostic.severity.ERROR then
            _n_ERROR = _n_ERROR + 1
        end
        if v.severity == vim.diagnostic.severity.WARN then
            _n_WARN = _n_WARN + 1
        end
        if v.severity == vim.diagnostic.severity.INFO then
            _n_INFO = _n_INFO + 1
        end
        if v.severity == vim.diagnostic.severity.HINT then
            _n_HINT = _n_HINT + 1
        end
    end
    return " "
        .. "%#StatusLineDiag#"
        .. SOLID_LEFT_ARROW
        .. "  "
        .. _n_ERROR
        .. "┊"
        .. " "
        .. _n_WARN
        .. "┊"
        .. "󰋽 "
        .. _n_INFO
        .. "┊"
        .. " "
        .. _n_HINT
        .. " "
        .. SOLID_RIGHT_ARROW
end

function StatusLine()
    return current_mode()
        .. current_file()
        .. current_buf_flags()
        .. current_git_branch()
        .. current_lsp_clients()
        .. current_lsp_progress()
        .. current_filetype()
        .. current_diagnostics()
        .. current_cursor_info()
end

if vim.g.vscode then
    vim.opt.statusline = ""
else
    vim.opt.statusline = "%!v:lua.StatusLine()"
end
