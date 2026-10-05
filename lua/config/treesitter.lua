-- treesitter
-- git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/plugins/start/nvim-treestter
-- require tree-sitter-cli (do npm install -g tree-sitter-cli)

local mod_async = require("lib.async")

local parser_repos = {
    { lang = "c", url = "https://github.com/tree-sitter/tree-sitter-c" },
    { lang = "python", url = "https://github.com/tree-sitter/tree-sitter-python" },
    { lang = "julia", url = "https://github.com/tree-sitter-grammars/tree-sitter-julia" },
    { lang = "cpp", url = "https://github.com/tree-sitter/tree-sitter-cpp" },
    { lang = "rust", url = "https://github.com/tree-sitter/tree-sitter-rust" },
    { lang = "bash", url = "https://github.com/tree-sitter/tree-sitter-bash" },
    { lang = "lua", url = "https://github.com/tree-sitter-grammars/tree-sitter-lua" },
    { lang = "vim", url = "https://github.com/tree-sitter-grammars/tree-sitter-vim" },
    { lang = "vimdoc", url = "https://github.com/neovim/tree-sitter-vimdoc" },
    { lang = "javascript", url = "https://github.com/tree-sitter/tree-sitter-javascript" },
    {
        lang = "typescript",
        url = "https://github.com/tree-sitter/tree-sitter-typescript",
        location = "typescript",
    },
    {
        lang = "tsx",
        url = "https://github.com/tree-sitter/tree-sitter-typescript",
        location = "tsx",
    },
    {
        lang = "markdown",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
        location = "tree-sitter-markdown",
    },
    {
        lang = "markdown_inline",
        url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown",
        location = "tree-sitter-markdown-inline",
    },
    { lang = "latex", url = "https://github.com/latex-lsp/tree-sitter-latex" },
}

-- this function needs to be updated occasionally, as of 260130, glibc should be at least 2.30
--
-- vim.fn.system() forks a shell and blocks the whole UI until it exits (see
-- #237); vim.system() with a callback never blocks the main loop. The
-- result only depends on the host, so it's cached after the first check
-- instead of re-spawning a shell on every startup / :TSSync.
local glibc_version_cache -- nil = not checked yet, false = check failed, number = version
local function get_glibc_version(cb)
    if glibc_version_cache ~= nil then
        cb(glibc_version_cache or nil)
        return
    end
    local ok = pcall(vim.system, { "ldd", "--version" }, { text = true }, function(result)
        local version
        if result.code == 0 then
            local first_line = ((result.stdout or "") .. "\n" .. (result.stderr or "")):match("^[^\n]*") or ""
            version = first_line:match("(%d+%.%d+)%s*$") or first_line:match("GLIBC (%d+%.%d+)")
            version = version and tonumber(version)
        end
        glibc_version_cache = version or false
        vim.schedule(function()
            cb(version)
        end)
    end)
    if not ok then
        glibc_version_cache = false
        cb(nil)
    end
end

local function has_tree_sitter_cli()
    return vim.fn.executable("tree-sitter") == 1
end

local function can_auto_install_parsers(cb)
    get_glibc_version(function(glibc_version)
        if glibc_version and glibc_version < 2.30 then
            vim.notify(
                string.format(
                    "Tree-sitter parser install skipped: glibc %.2f < 2.30 (e.g. compile parsers manually)",
                    glibc_version
                ),
                vim.log.levels.WARN
            )
            cb(false)
            return
        end

        if not has_tree_sitter_cli() then
            vim.notify(
                "Tree-sitter parser install skipped: tree-sitter-cli not found (e.g. use npm)",
                vim.log.levels.WARN
            )
            cb(false)
            return
        end

        cb(true)
    end)
end

local ts_status, ts = pcall(require, "nvim-treesitter")
local function ts_install()
    if not ts_status then
        return
    end
    can_auto_install_parsers(function(ok)
        if ok then
            ts.install({
                "c",
                "python",
                "julia",
                "cpp",
                "rust",
                "bash",
                "lua",
                "vim",
                "vimdoc",
                "javascript",
                "typescript",
                "tsx",
                "markdown",
                "markdown_inline",
                "latex",
            })
        end
    end)
end
ts_install()

local function build_latest_parsers(parser_dir, cb)
    can_auto_install_parsers(function(ok)
        if not ok then
            if cb then
                cb()
            end
            return
        end
        local cache_dir = vim.fn.stdpath("cache") .. "/treesitter-parsers-latest"
        vim.fn.mkdir(cache_dir, "p")
        vim.fn.mkdir(parser_dir, "p")
        mod_async
            .new(function()
                local jobs = {}
                for _, parser in ipairs(parser_repos) do
                    local job = mod_async.new(function()
                        local repo_dir = cache_dir .. "/" .. parser.lang
                        local result
                        if vim.fn.isdirectory(repo_dir .. "/.git") == 1 then
                            result = vim.system({ "git", "-C", repo_dir, "pull", "--ff-only", "--quiet" }):wait()
                        else
                            result =
                                vim.system({ "git", "clone", "--depth", "1", "--quiet", parser.url, repo_dir }):wait()
                        end
                        if result.code ~= 0 then
                            vim.notify(result.stderr, vim.log.levels.ERROR)
                            return
                        end
                        local build_dir = parser.location and (repo_dir .. "/" .. parser.location) or repo_dir
                        result = vim.system({
                            "tree-sitter",
                            "build",
                            "-o",
                            parser_dir .. "/" .. parser.lang .. ".so",
                        }, { cwd = build_dir }):wait()
                        if result.code ~= 0 then
                            vim.notify(result.stderr, vim.log.levels.ERROR)
                        end
                    end)
                    table.insert(jobs, job)
                end
                for _, job in ipairs(jobs) do
                    while job:running() do
                        mod_async.yield()
                    end
                end
            end)
            :wait()
        if cb then
            cb()
        end
    end)
end

local ts_highlight_active = {}
local function ts_highlight()
    local bufnr = vim.api.nvim_get_current_buf()
    if ts_highlight_active[bufnr] then
        vim.treesitter.stop(bufnr)
        ts_highlight_active[bufnr] = false
    else
        vim.treesitter.start(bufnr)
        ts_highlight_active[bufnr] = true
    end
end

local treesitter_aug = vim.api.nvim_create_augroup("Treesitter", { clear = true })
vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = treesitter_aug,
    callback = function(ev) ts_highlight_active[ev.buf] = nil end,
})

-- sometimes ts dont update all parsers and it fails things, you need to remove both parser and queries folder
local function ts_update(opts)
    if not ts_status then
        return
    end
    can_auto_install_parsers(function(ok)
        if not ok then
            return
        end
        local parser_dir = require("nvim-treesitter.config").get_install_dir("parser")
        local queries_dir = require("nvim-treesitter.config").get_install_dir("queries")
        print("Remove parser and queries folders...")
        vim.fn.delete(parser_dir, "rf")
        vim.fn.delete(queries_dir, "rf")
        ts_install()
        if opts.args == "latest" then
            build_latest_parsers(parser_dir, function()
                print("You need to restart neovim after compilation")
            end)
        else
            print("You need to restart neovim after compilation")
        end
    end)
end
vim.api.nvim_create_user_command("TSBufToggle", ts_highlight, {})
-- TSSync latest will pull and build latest parsers (but sitll use nvim-treesitter's query files)
vim.api.nvim_create_user_command("TSSync", ts_update, { nargs = "?" })
vim.api.nvim_create_autocmd("FileType", {
    group = treesitter_aug,
    pattern = { "*" },
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local ok = pcall(vim.treesitter.start)
        if not ok then
            vim.cmd("syntax on")
        else
            ts_highlight_active[bufnr] = true
        end
    end,
})
