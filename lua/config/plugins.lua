local mod_async = require("lib.async")

-- packages
local package_list = {
    { name = "fzf-lua", src = "https://github.com/ibhagwan/fzf-lua.git" },
    { name = "fff.nvim", src = "https://github.com/dmtrKovalenko/fff.nvim" },
    { name = "nvim-lspconfig", src = "https://github.com/neovim/nvim-lspconfig" },
    { name = "sneaks.vim", src = "https://github.com/justinmk/vim-sneak" },
    { name = "nvim-treesitter", src = "https://github.com/nvim-treesitter/nvim-treesitter.git" },
    { name = "conform.nvim", src = "https://github.com/stevearc/conform.nvim.git" },
    { name = "gitsigns.nvim", src = "https://github.com/lewis6991/gitsigns.nvim.git" },
    { name = "dark-theme", src = "https://github.com/stanfish06/dark-theme.git" },
    { name = "rose-pine", src = "https://github.com/rose-pine/neovim.git" },
    { name = "tokyonight", src = "https://github.com/folke/tokyonight.nvim.git" },
    { name = "eldritch", src = "https://github.com/eldritch-theme/eldritch.nvim.git" },
}
local vim_pack_ok, _ = pcall(require, "vim.pack")
function sync_packages()
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
                    local pkg_url = entry.src
                    local job = mod_async.new(function()
                        local full_path = old_package_dir .. pkg_name .. "/"
                        if vim.fn.isdirectory(full_path) == 1 then
                            print("Reinstall: " .. pkg_name .. "...")
                            vim.fn.delete(full_path, "rf")
                        else
                            print("Install: " .. pkg_name .. "...")
                        end
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
