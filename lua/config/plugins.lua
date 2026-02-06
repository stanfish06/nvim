local mod_async = require("lib.async")

-- packages
local package_list = {
    ["fzf-lua"] = "https://github.com/ibhagwan/fzf-lua.git",
    ["nvim-lspconfig"] = "https://github.com/neovim/nvim-lspconfig",
    ["sneaks.vim"] = "https://github.com/justinmk/vim-sneak",
    ["nvim-treesitter"] = "https://github.com/nvim-treesitter/nvim-treesitter.git",
    ["conform.nvim"] = "https://github.com/stevearc/conform.nvim.git",
    ["dark-theme"] = "https://github.com/stanfish06/dark-theme.git",
    ["rose-pine"] = "https://github.com/rose-pine/neovim.git",
    ["tokyonight"] = "https://github.com/folke/tokyonight.nvim.git",
}
function sync_packages()
    mod_async
        .new(function()
            local package_dir = os.getenv("HOME") .. "/.config/nvim/pack/plugins/start/"
            print("Sync packages...")
            local jobs = {}
            for pkg_name, pkg_url in pairs(package_list) do
                local job = mod_async.new(function()
                    local full_path = package_dir .. pkg_name .. "/"
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
vim.api.nvim_create_user_command("SyncPkgs", sync_packages, {})
