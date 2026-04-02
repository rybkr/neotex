local M = {}

local defaults = {
    latex_cmd = "pdflatex",
    pdf_viewer = "zathura",
    build_dir = "build",
    debounce_ms = 500,
    log_level = vim.log.levels.INFO,
}

M.options = vim.deepcopy(defaults)

function M.setup(user_options)
    M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_options or {})
    return M.options
end

function M.get()
    return M.options
end

return M
