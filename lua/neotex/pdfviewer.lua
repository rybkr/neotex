local config = require("neotex.config")
local logger = require("neotex.logger")
local utils = require("neotex.utils")

local M = {}

local function viewer_command() return config.get().pdf_viewer end

local function is_zathura() return viewer_command() == "zathura" end

local function pdf_is_open(pdf_path)
    if not is_zathura() then return false end

    local handle = io.popen("pgrep -f " ..
                                vim.fn.shellescape("zathura.*" .. pdf_path))
    if not handle then return false end

    local result = handle:read("*a")
    handle:close()
    return result ~= ""
end

local function build_open_command(ctx)
    local cmd = {viewer_command()}

    if is_zathura() and vim.v.servername ~= "" then
        table.insert(cmd, "--synctex-editor-command")
        table.insert(cmd, string.format(
                         [[nvim --server %s --remote-send <Cmd>lua require('neotex.commands').jump_to(%%l, [=[%%f]=])<CR>]],
                         vim.v.servername))
    end

    table.insert(cmd, ctx.pdf)
    return cmd
end

function M.open_pdf(target)
    local ctx = utils.resolve_tex_context(target)
    if not ctx or not utils.file_exists(ctx.pdf) then
        logger.error("PDF does not exist. Compile the document first.")
        return false
    end

    if not utils.assert_executable(viewer_command(), "PDF viewer") then
        return false
    end

    local job_id = vim.fn.jobstart(build_open_command(ctx), {detach = true})
    if job_id <= 0 then
        logger.error("Failed to launch PDF viewer.")
        return false
    end

    logger.info("Opening PDF: " .. vim.fn.fnamemodify(ctx.pdf, ":t"))
    return true
end

function M.view_pdf(target)
    local ctx = utils.resolve_tex_context(target)
    if not ctx or not utils.file_exists(ctx.pdf) then
        logger.error("PDF does not exist. Compile the document first.")
        return false
    end

    if not utils.assert_executable(viewer_command(), "PDF viewer") then
        return false
    end

    if pdf_is_open(ctx.pdf) then return true end

    return M.open_pdf(ctx.source)
end

function M.forward_search(target)
    local ctx = utils.resolve_tex_context(target)
    if not ctx or not utils.file_exists(ctx.pdf) then
        logger.error("PDF does not exist. Compile the document first.")
        return false
    end

    if not is_zathura() then
        logger.warn("Forward SyncTeX is currently only implemented for zathura.")
        return false
    end

    if not utils.assert_executable(viewer_command(), "PDF viewer") then
        return false
    end

    if not utils.ensure_dbus() then return false end

    local cmd = {
        viewer_command(), "--synctex-forward",
        string.format("%d:%d:%s", vim.fn.line("."), vim.fn.col("."), ctx.source),
        ctx.pdf
    }

    local job_id = vim.fn.jobstart(cmd, {detach = true})
    if job_id <= 0 then
        logger.error("Failed to execute SyncTeX forward search.")
        return false
    end

    return true
end

return M
