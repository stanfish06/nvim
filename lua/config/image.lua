local function preview_image(path)
    -- image api does not associate with window at this point, check later
    local id = vim.ui.img.set(
     vim.fn.readblob(path),
     { row = 0, col = 0, width = 100, height = 50, zindex = 0 }
    )
    return id
end
