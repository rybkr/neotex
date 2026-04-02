local compiler = require("neotex.compiler")
local pdfviewer = require("neotex.pdfviewer")

local M = {}

local created = false

function M.jump_to(line, file)
    local target = file

    if type(target) ~= "string" or target == "" then return end

    if target:sub(1, 1) ~= "/" then target = vim.fn.fnamemodify(target, ":p") end

    vim.cmd.edit(vim.fn.fnameescape(target))

    if tonumber(line) then
        vim.api.nvim_win_set_cursor(0, {tonumber(line), 0})
    end
end

function M.setup()
    if created then return end

    vim.api.nvim_create_user_command("NeoTexCompile",
                                     function() compiler.compile() end, {})

    vim.api.nvim_create_user_command("NeoTexOpen",
                                     function() pdfviewer.view_pdf() end, {})

    vim.api.nvim_create_user_command("NeoTexPreview", function()
        compiler.compile(nil, function(did_compile)
            if did_compile then pdfviewer.view_pdf() end
        end)
    end, {})

    vim.api.nvim_create_user_command("NeoTexForwardSearch",
                                     function() pdfviewer.forward_search() end,
                                     {})

    vim.api.nvim_create_user_command("NeoTexLiveToggle",
                                     function() compiler.toggle_live() end, {})

    created = true
end

return M
