local config = require("neotex.config")

local M = {}

local titles = {
    [vim.log.levels.DEBUG] = "Debug",
    [vim.log.levels.INFO] = "Info",
    [vim.log.levels.WARN] = "Warning",
    [vim.log.levels.ERROR] = "Error",
}

local function should_log(level)
    return level >= (config.get().log_level or vim.log.levels.INFO)
end

function M.log(level, message, opts)
    if not should_log(level) then
        return
    end

    vim.notify(message, level, vim.tbl_extend("force", {
        title = "neotex",
    }, opts or {}))
end

function M.debug(message, opts)
    M.log(vim.log.levels.DEBUG, message, opts)
end

function M.info(message, opts)
    M.log(vim.log.levels.INFO, message, opts)
end

function M.warn(message, opts)
    M.log(vim.log.levels.WARN, message, opts)
end

function M.error(message, opts)
    M.log(vim.log.levels.ERROR, message, opts)
end

function M.level_name(level)
    return titles[level] or "Log"
end

return M
