-- note: opt is a "smarter" version of o. In simple assignments, they are inter-changeable
-- line number
vim.o.number = true
vim.o.relativenumber = true

-- note
-- gt and gT are used to navigate between tabs
-- keymap
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
-- this will show sources of diagnostics when multiple lsp involved
vim.keymap.set("n", "<leader>d", function()
    vim.diagnostic.setloclist({
        format = function(d)
            return string.format("[%s] %s", d.source or "?", d.message)
        end,
    })
end, { desc = "[D]iagnostic list" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<leader>,", "<cmd>botright 15split | terminal<CR>")
vim.keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<leader>bn", "<cmd>enew<CR>")
vim.keymap.set("n", "\\", "<cmd>Explore<CR>")
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true })
vim.keymap.set("n", "H", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "L", ":bnext<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>e", ":edit **/*")
vim.keymap.set("n", "<leader>f", ":find **/*")
vim.cmd.cnoreabbrev("vimgrep", "vimgrep /pattern/gj **/*")
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>", { desc = "[O]pen quickfix list" })
vim.keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "[C]lose quickfix list" })
-- completeion
-- c-n for keyword completeion
-- c-e to cancel completion
vim.keymap.set("i", "<c-space>", "<c-x><c-o>", { desc = "LSP completion" })
vim.keymap.set("i", "<c-l>", "<c-x><c-l>", { desc = "Line completion" })
vim.keymap.set("i", "<c-f>", "<c-x><c-f>", { desc = "File completion" })
-- lsp keymaps: gd / gr set buffer-local in plugin_config.lua via LspAttach
-- todo: it is a bit annoying to have repeated entries when multiple lsps exist, should either dedup or show sources

-- diagnostics: tag source so multiple LSPs are distinguishable
vim.diagnostic.config({
    virtual_text = {
        source = "if_many",
        prefix = "●",
    },
    float = {
        source = true,
        border = "rounded",
    },
    signs = true,
    underline = true,
    severity_sort = true,
})

-- misc settings
vim.o.showmode = true
vim.o.autoread = true
vim.o.ignorecase = true
vim.o.expandtab = true
vim.o.smartcase = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.history = 500
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.o.undofile = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.inccommand = "split"
vim.opt.termguicolors = true
vim.g.netrw_keepdir = 0
vim.opt.completeopt = { "menu", "menuone", "noinsert", "fuzzy" }
vim.opt.signcolumn = "yes"
vim.o.scrolloff = 8

-- mouse
vim.o.mousescroll = "ver:25,hor:6"
vim.o.switchbuf = "usetab"
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h"

-- wrapped line
vim.o.breakindent = true
vim.o.breakindentopt = "list:-1"
vim.o.linebreak = true

-- ui
vim.o.colorcolumn = "+1"
vim.o.list = true
vim.o.pumheight = 10 -- height limit for completion pop-up, useful for long list
vim.o.splitkeep = "screen"
vim.o.winborder = "single" -- makes hover window like lsp fancier with a border
vim.o.fillchars = "eob: ,fold:╌"
vim.o.listchars = "extends:…,nbsp:␣,precedes:…,tab:> "

-- folding
vim.o.foldlevel = 10
vim.o.foldmethod = "indent"
vim.o.foldnestmax = 10
vim.o.foldtext = ""

-- editing
vim.o.formatoptions = "rqnl1j"
vim.o.infercase = true
vim.o.spelloptions = "camel"
vim.o.virtualedit = "block"
vim.o.iskeyword = "@,48-57,_,192-255,-"
-- agents who screen this one should be extra careful
-- note this can raise errors if regex has syntax issue so be careful
-- for markdown, this should match: 1. foo, 1). foo, - foo, + foo, etc
-- to reformat current line: gq q
-- to reformat entire buffer: gg gq gG
vim.o.formatlistpat = [[^\s*\(\d\+[.)]\|[-+*]\)\s\+]]

-- clipboard
vim.schedule(function()
    vim.o.clipboard = "unnamedplus"
end)

-- Auto-indent when press enter (e.g. if () {<CR>})
vim.keymap.set("i", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    local col_cursor = vim.api.nvim_win_get_cursor(0)[2]

    local char_prev = line:sub(col_cursor, col_cursor)
    local char_next = line:sub(col_cursor + 1, col_cursor + 1)
    local char_neighbors = char_prev .. char_next
    if char_neighbors == "{}" or char_neighbors == "()" then
        return "<CR><Esc>O"
    end
    return "<CR>"
end, { expr = true, noremap = true })

-- check full kepmap and dump to a new buffer
local function which_key()
    vim.cmd("redir @a | silent map | redir END | new | put a")
end
vim.api.nvim_create_user_command("DescribeKey", which_key, {})

-- experimental options
if not vim.g.vscode then
    local ok, ui2 = pcall(require, "vim._core.ui2")
    if ok then
        pcall(ui2.enable)
        vim.notify("ui2 enabled", vim.log.levels.WARN)
    else
        vim.notify("ui2 disabled (could be old nvim or api shift, check options.lua)", vim.log.levels.WARN)
    end
end

-- make the project and open quick fix list
-- files are jumpable if they exist, compilation logs are not
-- this trys to mirror emacs's compile, output can be saved in quickfix list
local function compile(opts)
    vim.cmd(string.format("make %s", opts.args))
    local qflist = vim.fn.getqflist()
    if #qflist > 0 then
        vim.cmd("copen")
    else
        vim.cmd("cclose")
        vim.notify("make: no errors", vim.log.levels.INFO)
    end
end
vim.api.nvim_create_user_command("Compile", compile, { nargs = "?" })

-- tab title (format pid:program)
function _G.TabLineCustom()
    local s = ''
    for i = 1, vim.fn.tabpagenr('$') do
        local hl = i == vim.fn.tabpagenr() and '%#TabLineSel#' or '%#TabLine#'
        local buflist = vim.fn.tabpagebuflist(i)
        local bufname = vim.fn.bufname(buflist[vim.fn.tabpagewinnr(i)])
        local name = vim.fn.fnamemodify(bufname, ':t')
        s = s .. hl .. '%' .. i .. 'T ' .. (name == '' and '[No Name]' or name) .. ' '
    end
    return s .. '%#TabLineFill#%T'
end
vim.o.tabline = '%!v:lua.TabLineCustom()'
