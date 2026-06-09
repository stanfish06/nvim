local mod_async = require("lib.async")

-- packages
local package_list = {
    { name = "fzf-lua", src = "https://github.com/ibhagwan/fzf-lua.git" },
    {
        name = "fff.nvim",
        src = "https://github.com/dmtrKovalenko/fff.nvim",
        lazy = true,
        version = vim.version.range("0.9.0"),
    }, -- this package breaks frequently, specify version
    { name = "nvim-lspconfig", src = "https://github.com/neovim/nvim-lspconfig" },
    { name = "sneaks.vim", src = "https://github.com/justinmk/vim-sneak" }, -- remaps s/S intentionally
    { name = "guh.nvim", src = "https://github.com/justinmk/guh.nvim" }, -- gh wrapper in nvim
    { name = "fugitive.vim", src = "https://tpope.io/vim/fugitive.git" },
    { name = "diffview.nvim", src = "https://github.com/sindrets/diffview.nvim.git" },
    { name = "nvim-treesitter", src = "https://github.com/nvim-treesitter/nvim-treesitter.git" },
    {
        name = "nvim-treesitter-textobjects",
        src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git",
    },
    { name = "conform.nvim", src = "https://github.com/stevearc/conform.nvim.git" },
    { name = "gitsigns.nvim", src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { name = "obsidian.nvim", src = "https://github.com/obsidian-nvim/obsidian.nvim.git", skip_old_nvim = true },
    { name = "plenary.nvim", src = "https://github.com/nvim-lua/plenary.nvim.git" },
    { name = "dark-theme", src = "https://github.com/stanfish06/dark-theme.git" },
    { name = "rose-pine", src = "https://github.com/rose-pine/neovim.git" },
    { name = "tokyonight", src = "https://github.com/folke/tokyonight.nvim.git" },
    { name = "eldritch", src = "https://github.com/eldritch-theme/eldritch.nvim.git" },
    { name = "solarized-osaka.nvim", src = "https://github.com/craftzdog/solarized-osaka.nvim.git" },
}
local vim_pack_ok, _ = pcall(require, "vim.pack")
local function sync_packages()
    -- local old_package_dir = os.getenv("HOME") .. "/.config/nvim/pack/plugins/start/"
    local old_package_dir = vim.fn.stdpath("config") .. "/pack/plugins/start/"
    if vim_pack_ok then
        print("Vim pack available!")
        mod_async
            .new(function()
                print("Check and remove old installs...")
                local jobs = {}
                for _, entry in ipairs(package_list) do
                    local pkg_name = entry.name
                    local job = mod_async.new(function()
                        local full_path = old_package_dir .. pkg_name .. "/"
                        if vim.fn.isdirectory(full_path) == 1 then
                            print("Remove: " .. pkg_name .. "...")
                            vim.fn.delete(full_path, "rf")
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
        print("Done clean-up!")
        print("Install all packages...")
        vim.pack.add(package_list)
        vim.pack.update()
        print("All packages installed!")
    else
        mod_async
            .new(function()
                print("Sync packages (old approach)...")
                local jobs = {}
                for _, entry in ipairs(package_list) do
                    local pkg_name = entry.name
                    local pkg_skip = entry.skip_old_nvim
                    local pkg_url = entry.src
                    local sub_dir = entry.lazy and "opt/" or "start/"
                    local pkg_root = vim.fn.stdpath("config") .. "/pack/plugins/" .. sub_dir
                    local job = mod_async.new(function()
                        local full_path = pkg_root .. pkg_name .. "/"
                        if vim.fn.isdirectory(full_path) == 1 then
                            print("Reinstall: " .. pkg_name .. "...")
                            vim.fn.delete(full_path, "rf")
                        else
                            print("Install: " .. pkg_name .. "...")
                        end
                        if pkg_skip then
                            print("Package skiped manually. Likely due to incompatibility.")
                        else
                            vim.system({
                                "git",
                                "clone",
                                "--depth",
                                "1",
                                "--quiet",
                                pkg_url,
                                full_path,
                            }):wait()
                            print("Synced: " .. pkg_name)
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
        print("Done!")
    end
end
vim.api.nvim_create_user_command("SyncPkgs", sync_packages, {})
-- loading packages if available (vim pack does not install in start so you need to load them)
if vim_pack_ok then
    for _, pkg in ipairs(package_list) do
        pcall(vim.cmd.packadd, pkg.name)
    end
end
