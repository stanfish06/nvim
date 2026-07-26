-- lsp
-- git clone https://github.com/neovim/nvim-lspconfig ~/.config/nvim/pack/nvim/start/nvim-lspconfig
-- after v12, neovim will have built-in package manager
--
-- Extracted out of plugin_config.lua so stable mode can bring up LSP without also
-- pulling in the ~20 other plugin setups living there. See the module table in
-- init.lua: this is "core" tier, plugin_config.lua is "extra".

if vim.g.vscode then
    return
end

-- Builtin completion is only wanted when blink.cmp is absent; the LspAttach handler
-- at the bottom keys off this. In stable mode blink is not installed at all, so the
-- probe fails and vim.lsp.completion takes over with autotrigger. require() is
-- cached, so probing costs nothing even when blink is present.
local blink_ok = pcall(require, "blink.cmp")

-- vim.keymap.set renamed `buffer` -> `buf` in 0.13 (`buffer` is documented as
-- soft-deprecated but still honored). `buf` does not exist on 0.11, where it would
-- be forwarded to nvim_set_keymap as an unknown key, so keep the older spelling:
-- it is the only one valid across the whole 0.11 - 0.13 range this config targets.
local BUF = "buffer"

-- lua
vim.lsp.config("luals", {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".luarc.jsonc", ".git" },
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
            },
        },
    },
})
-- brew install lua-language-server
vim.lsp.enable("luals")
-- uv tool install pyright
vim.lsp.config("pyright", {
    settings = {
        python = {
            analysis = {
                diagnosticMode = "workspace",
            },
        },
    },
})
vim.lsp.enable("pyright")
-- install via uv: uv tool install pyrefly, then pyrefly init inside project folder (will transfer configs from pyright if available)
-- pyrefly seems capable of showing more type issues as far as I can tell
vim.lsp.enable("pyrefly")
-- install using system package manager
vim.lsp.enable("clangd")
-- npm instal -g typescript-language-server
vim.lsp.enable("ts_ls")
-- rust
vim.lsp.enable("rust_analyzer")
-- go
vim.lsp.enable("gopls")
vim.lsp.enable("sourcekit")

-- vim.list.unique() is 0.12+, and this module has to load on distro nvim reached over
-- ssh (:NvimRemote), so dedupe by hand. Unlike vim.list.unique this returns a new
-- table rather than mutating, hence the reassignment at the call site.
local function dedupe(items, keyfn)
    local seen, out = {}, {}
    for _, item in ipairs(items) do
        local key = keyfn(item)
        if not seen[key] then
            seen[key] = true
            out[#out + 1] = item
        end
    end
    return out
end

local function lsp_on_list(what, tag)
    what.items = dedupe(what.items, function(item)
        return ("%s\0%d\0%d\0%d\0%d"):format(
            item.filename or "",
            item.lnum or 0,
            item.col or 0,
            item.end_lnum or 0,
            item.end_col or 0
        )
    end)

    vim.fn.setqflist({}, " ", what)

    local method = what.context and what.context.method
    local jump_single = #what.items == 1
        and method ~= "textDocument/implementation"
        and method ~= "textDocument/references"

    if jump_single then
        if tag then
            vim.fn.settagstack(tag.win, {
                items = { { tagname = tag.name, from = tag.from } },
            }, "t")
        end
        vim.cmd("cfirst")
    else
        vim.cmd("botright copen")
    end
end

---@param method fun(opts?: vim.lsp.ListOpts)
local function lsp_jump(method)
    local from = vim.fn.getpos(".")
    from[1] = vim.api.nvim_get_current_buf()
    local tag = {
        name = vim.fn.expand("<cword>"),
        from = from,
        win = vim.api.nvim_get_current_win(),
    }
    method({
        on_list = function(what)
            lsp_on_list(what, tag)
        end,
    })
end

local function lsp_references()
    vim.lsp.buf.references(nil, {
        on_list = function(what)
            lsp_on_list(what)
        end,
    })
end

vim.keymap.set("n", "grr", lsp_references, { desc = "vim.lsp.buf.references() (deduped)" })
vim.keymap.set("n", "gri", function()
    lsp_jump(vim.lsp.buf.implementation)
end, { desc = "vim.lsp.buf.implementation() (deduped)" })
vim.keymap.set("n", "grt", function()
    lsp_jump(vim.lsp.buf.type_definition)
end, { desc = "vim.lsp.buf.type_definition() (deduped)" })

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not blink_ok and client and client:supports_method("textDocument/completion") then
            pcall(function()
                vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
            end)
        end
        vim.keymap.set("n", "gd", function()
            lsp_jump(vim.lsp.buf.definition)
        end, { [BUF] = ev.buf, desc = "LSP definition (deduped)" })
        vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { [BUF] = ev.buf, desc = "LSP code action" })
        -- route the gq operator through the LSP formatter (conform is wired as lsp_format fallback)
        vim.bo[ev.buf].formatexpr = "v:lua.vim.lsp.formatexpr()"
    end,
})
