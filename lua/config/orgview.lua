local ns = vim.api.nvim_create_namespace("orgview")

local icons = {
    heading = { "󰲡", "󰲣", "󰲥", "󰲧", "󰲩", "󰲫" },
    bullet = "•",
    todo = "󰱒",
    done = "󰄱",
    link = "󰌹",
}

for level = 1, 6 do
    vim.api.nvim_set_hl(0, "OrgViewH" .. level, { link = "@markup.heading." .. level, default = true })
end
vim.api.nvim_set_hl(0, "OrgViewBullet", { link = "@markup.list", default = true })
vim.api.nvim_set_hl(0, "OrgViewTodo", { link = "@markup.list.unchecked", default = true })
vim.api.nvim_set_hl(0, "OrgViewDone", { link = "@markup.list.checked", default = true })
vim.api.nvim_set_hl(0, "OrgViewLink", { link = "@markup.link", default = true })

local function swap(buf, row, from, to, icon, hl)
    vim.api.nvim_buf_set_extmark(buf, ns, row, from, { end_col = to, conceal = "" })
    vim.api.nvim_buf_set_extmark(buf, ns, row, from, {
        virt_text = { { icon, hl } },
        virt_text_pos = "inline",
    })
end

local function render_links(buf, row, line)
    local ranges = {}
    -- [[url][desc]] first: conceal "[[url][" and "]]", keep desc
    for s, url, desc, e in line:gmatch("()%[%[([^%]]+)%]%[([^%]]*)%]%]()") do
        local desc_start = s - 1 + 2 + #url + 2 -- 0-based col of desc
        local desc_end = e - 1 - 2
        swap(buf, row, s - 1, desc_start, icons.link .. " ", "OrgViewLink")
        vim.api.nvim_buf_set_extmark(buf, ns, row, desc_start, { end_col = desc_end, hl_group = "OrgViewLink" })
        vim.api.nvim_buf_set_extmark(buf, ns, row, desc_end, { end_col = e - 1, conceal = "" })
        table.insert(ranges, { s - 1, e - 1 })
    end
    -- bare [[url]]: conceal "[[" and "]]", keep url (skip if inside a match above)
    for s, url, e in line:gmatch("()%[%[([^%]]+)%]%]()") do
        local overlaps = vim.iter(ranges):any(function(r)
            return s - 1 >= r[1] and s - 1 < r[2]
        end)
        if not overlaps then
            local url_start = s - 1 + 2
            local url_end = e - 1 - 2
            swap(buf, row, s - 1, url_start, icons.link .. " ", "OrgViewLink")
            vim.api.nvim_buf_set_extmark(buf, ns, row, url_start, { end_col = url_end, hl_group = "OrgViewLink" })
            vim.api.nvim_buf_set_extmark(buf, ns, row, url_end, { end_col = e - 1, conceal = "" })
        end
    end
end

local function render(buf)
    if vim.bo[buf].filetype ~= "org" then
        return
    end
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.wo[win].conceallevel = 2
    end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local row = i - 1
        local stars = line:match("^(%*+)%s") -- col-0 stars = headline (org rule)
        local indent, bullet = line:match("^(%s*)([%-%+])%s")
        if not stars and not bullet then
            indent, bullet = line:match("^(%s+)(%*)%s") -- indented * = bullet
        end
        if stars then
            local level = math.min(#stars, 6)
            swap(buf, row, 0, #stars, icons.heading[level] .. " ", "OrgViewH" .. level)
            vim.api.nvim_buf_set_extmark(buf, ns, row, #stars + 1, { end_col = #line, hl_group = "OrgViewH" .. level })
        elseif bullet then
            local box = line:sub(#indent + 3, #indent + 5) -- chars after "x " bullet: "[ ]"/"[X]"
            if box:match("^%[[ xX]%]$") then
                local checked = box:match("[xX]") ~= nil
                swap(
                    buf,
                    row,
                    #indent,
                    #indent + 5,
                    checked and icons.done or icons.todo,
                    checked and "OrgViewDone" or "OrgViewTodo"
                )
            else
                swap(buf, row, #indent, #indent + 1, icons.bullet, "OrgViewBullet")
            end
        end
        render_links(buf, row, line)
    end
end

local group = vim.api.nvim_create_augroup("OrgView", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "org",
    callback = function(ev)
        render(ev.buf)
        vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter" }, {
            group = group,
            buffer = ev.buf,
            callback = function()
                render(ev.buf)
            end,
        })
    end,
})
