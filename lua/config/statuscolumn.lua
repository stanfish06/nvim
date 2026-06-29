local function stl_hl(name)
    return string.format("%%#%s#", name)
end

local space = " "
local double_space = "  "

function Directory()
    if vim.v.virtnum ~= 0 then
        return double_space
    end

    local name = vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, true)[1]

    local icon, icon_color
    if name:sub(-1) == "/" then
        icon = "" -- nerd icon of folder.
        icon_color = "Directory"
    else
        -- use your favorite icon provider.
        local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
        if devicons_ok then
            local extension = vim.fs.ext(name)
            icon, icon_color = devicons.get_icon(name, extension)
            if not icon then
                icon, icon_color = devicons.get_icon_by_filetype(vim.bo[0].filetype, { default = true })
            end
        end
    end

    if not icon then
        return double_space
    end

    return table.concat({
        stl_hl(icon_color),
        icon,
        space,
    })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "directory",
    callback = function()
        vim.opt_local.statuscolumn = "%{%v:lua.Directory()%}"
        vim.opt_local.foldcolumn = "0"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function()
        vim.opt_local.statuscolumn = "%{%v:lua.Directory()%}"
        vim.opt_local.foldcolumn = "0"
    end,
})
