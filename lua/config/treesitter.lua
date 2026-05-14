-- treesitter
-- git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/plugins/start/nvim-treestter
-- require tree-sitter-cli (do npm install -g tree-sitter-cli)

local mod_async = require("lib.async")

local parser_repos = {
    { lang = "c", url = "https://github.com/tree-sitter/tree-sitter-c" },
    { lang = "python", url = "https://github.com/tree-sitter/tree-sitter-python" },
    { lang = "julia", url = "https://github.com/tree-sitter-grammars/tree-sitter-julia" },
    { lang = "cpp", url = "https://github.com/tree-sitter/tree-sitter-cpp" },
    { lang = "bash", url = "https://github.com/tree-sitter/tree-sitter-bash" },
    { lang = "lua", url = "https://github.com/tree-sitter-grammars/tree-sitter-lua" },
    { lang = "vim", url = "https://github.com/tree-sitter-grammars/tree-sitter-vim" },
    { lang = "vimdoc", url = "https://github.com/neovim/tree-sitter-vimdoc" },
    { lang = "javascript", url = "https://github.com/tree-sitter/tree-sitter-javascript" },
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
}

-- this function needs to be updated occasionally, as of 260130, glibc should be at least 2.30
local function get_glibc_version()
    local result = vim.fn.system("ldd --version 2>&1 | head -n1")
    if vim.v.shell_error ~= 0 then
        return nil
    end
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
local function ts_install()
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
end
ts_install()

-- this pulls and builds latest parsers since nvim-treesitter is no longer updated
-- TODO: query files might be incompatible overtime (I dont know how to write those for now but worth checking later)
local function build_latest_parsers(parser_dir)
    if not can_auto_install_parsers() then
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
                        result = vim.system({ "git", "clone", "--depth", "1", "--quiet", parser.url, repo_dir }):wait()
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
end

local function is_ts_enabled()
    local bufnr = vim.api.nvim_get_current_buf()
    return vim.treesitter.highlighter.active[bufnr] ~= nil
end
local function ts_highlight()
    if is_ts_enabled() then
        vim.treesitter.stop()
    else
        vim.treesitter.start()
    end
end
-- sometimes ts dont update all parsers and it fails things, you need to remove both parser and queries folder
local function ts_update(opts)
    if ts_status and can_auto_install_parsers() then
        local parser_dir = require("nvim-treesitter.config").get_install_dir("parser")
        local queries_dir = require("nvim-treesitter.config").get_install_dir("queries")
        print("Remove parser and queries folders...")
        vim.fn.delete(parser_dir, "rf")
        vim.fn.delete(queries_dir, "rf")
        ts_install()
        if opts.args == "latest" then
            build_latest_parsers(parser_dir)
        end
        print("You need to restart neovim after compilation")
    end
end
vim.api.nvim_create_user_command("TSBufToggle", ts_highlight, {})
-- TSSync latest will pull and build latest parsers (but sitll use nvim-treesitter's query files)
vim.api.nvim_create_user_command("TSSync", ts_update, { nargs = "?" })
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "*" },
    callback = function()
        local ok, err = pcall(vim.treesitter.start)
        if not ok then
            vim.cmd("syntax on")
        end
    end,
})
