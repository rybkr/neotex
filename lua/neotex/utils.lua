local config = require("neotex.config")
local logger = require("neotex.logger")

local M = {}
local uv = vim.uv or vim.loop

local function join_paths(...)
    return table.concat(vim.tbl_flatten({ ... }), "/")
end

function M.file_exists(path)
    local stat = uv.fs_stat(path)
    return stat and stat.type == "file" or false
end

function M.dir_exists(path)
    local stat = uv.fs_stat(path)
    return stat and stat.type == "directory" or false
end

function M.ensure_dir(path)
    if M.dir_exists(path) then
        return true
    end

    local ok = vim.fn.mkdir(path, "p") == 1
    if not ok and not M.dir_exists(path) then
        logger.error("Failed to create directory: " .. path)
        return false
    end

    return true
end

function M.is_executable(program)
    return vim.fn.executable(program) == 1
end

function M.assert_executable(program, label)
    if M.is_executable(program) then
        return true
    end

    logger.error(string.format("%s is not executable: %s", label or "Program", program))
    return false
end

function M.is_tex_file(path)
    return path:sub(-4) == ".tex"
end

function M.normalize_path(path)
    return vim.fn.fnamemodify(path, ":p")
end

function M.resolve_tex_path(target)
    local candidate = target

    if not candidate or candidate == "" then
        candidate = vim.api.nvim_buf_get_name(0)
    end

    if candidate == "" then
        logger.error("No TeX file is associated with the current buffer.")
        return nil
    end

    if not M.is_tex_file(candidate) then
        candidate = candidate .. ".tex"
    end

    candidate = M.normalize_path(candidate)

    if not M.file_exists(candidate) then
        logger.error("TeX file does not exist: " .. candidate)
        return nil
    end

    return candidate
end

function M.resolve_tex_context(target)
    local source = M.resolve_tex_path(target)
    if not source then
        return nil
    end

    local opts = config.get()
    local source_dir = vim.fn.fnamemodify(source, ":h")
    local stem = vim.fn.fnamemodify(source, ":t:r")
    local build_dir = opts.build_dir

    if build_dir == nil or build_dir == "" then
        build_dir = source_dir
    elseif build_dir:sub(1, 1) ~= "/" then
        build_dir = join_paths(source_dir, build_dir)
    end

    return {
        source = source,
        source_dir = source_dir,
        stem = stem,
        build_dir = build_dir,
        pdf = join_paths(build_dir, stem .. ".pdf"),
        log = join_paths(build_dir, stem .. ".log"),
        synctex = join_paths(build_dir, stem .. ".synctex.gz"),
    }
end

function M.ensure_dbus()
    if vim.env.DBUS_SESSION_BUS_ADDRESS and vim.env.DBUS_SESSION_BUS_ADDRESS ~= "" then
        return true
    end

    local handle = io.popen("dbus-daemon --session --fork --print-address 2>/dev/null")
    if not handle then
        logger.error("Could not start D-Bus daemon.")
        return false
    end

    local address = handle:read("*a"):match("%S+")
    handle:close()

    if not address then
        logger.error("Failed to start D-Bus daemon.")
        return false
    end

    vim.env.DBUS_SESSION_BUS_ADDRESS = address
    return true
end

return M
