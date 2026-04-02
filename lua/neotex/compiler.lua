local config = require("neotex.config")
local logger = require("neotex.logger")
local parser = require("neotex.parser")
local utils = require("neotex.utils")

local M = {}
local uv = vim.uv or vim.loop

local GROUP = vim.api.nvim_create_augroup("neotex_live_compile", {clear = true})

local state = {
    active_job = nil,
    pending_target = nil,
    last_compile_ok = false,
    live_enabled = false,
    live_target = nil,
    live_bufnr = nil,
    debounce_timer = nil
}

local function stop_timer()
    if not state.debounce_timer then return end

    state.debounce_timer:stop()
    state.debounce_timer:close()
    state.debounce_timer = nil
end

local function summarize_log(result)
    if #result.errors > 0 then
        logger.error(result.errors[1])
    elseif #result.warnings > 0 then
        logger.warn(result.warnings[1])
    elseif #result.overfull > 0 then
        logger.warn(result.overfull[1])
    end
end

local function run_pending_compile()
    if not state.pending_target then return end

    local target = state.pending_target
    state.pending_target = nil
    vim.schedule(function() M.compile(target) end)
end

function M.is_live() return state.live_enabled end

function M.compile(target, on_complete)
    local ctx = utils.resolve_tex_context(target)
    if not ctx then return false end

    local latex_cmd = config.get().latex_cmd
    if not utils.assert_executable(latex_cmd, "LaTeX compiler") then
        return false
    end

    if not utils.ensure_dir(ctx.build_dir) then return false end

    if state.active_job then
        state.pending_target = ctx.source
        return true
    end

    state.last_compile_ok = false

    local stdout = {}
    local stderr = {}
    local cmd = {
        latex_cmd, "-interaction=nonstopmode", "-halt-on-error",
        "-file-line-error", "-synctex=1", "-output-directory=" .. ctx.build_dir,
        ctx.source
    }

    state.active_job = vim.fn.jobstart(cmd, {
        cwd = ctx.source_dir,
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
            if data then vim.list_extend(stdout, data) end
        end,
        on_stderr = function(_, data)
            if data then vim.list_extend(stderr, data) end
        end,
        on_exit = function(_, code)
            state.active_job = nil

            local log_result = parser.parse_log(ctx.log)
            local did_compile = code == 0 and utils.file_exists(ctx.pdf)
            state.last_compile_ok = did_compile

            if did_compile then
                logger.info("LaTeX compilation successful: " ..
                                vim.fn.fnamemodify(ctx.pdf, ":t"))
                if #log_result.warnings > 0 or #log_result.overfull > 0 then
                    summarize_log(log_result)
                end
            else
                summarize_log(log_result)
                if #stderr > 0 then
                    logger.error(table.concat(stderr, "\n"))
                elseif #stdout > 0 then
                    logger.error(table.concat(stdout, "\n"))
                else
                    logger.error("LaTeX compilation failed.")
                end
            end

            if on_complete then
                vim.schedule(function()
                    on_complete(did_compile, ctx, log_result)
                end)
            end

            run_pending_compile()
        end
    })

    if state.active_job <= 0 then
        state.active_job = nil
        logger.error("Failed to start LaTeX compiler job.")
        return false
    end

    return true
end

function M.enable_live(target)
    local ctx = utils.resolve_tex_context(target)
    if not ctx then return false end

    local bufnr = vim.api.nvim_get_current_buf()
    stop_timer()
    vim.api.nvim_clear_autocmds({group = GROUP})

    state.live_enabled = true
    state.live_target = ctx.source
    state.live_bufnr = bufnr

    vim.api.nvim_create_autocmd({"BufWritePost", "TextChanged", "TextChangedI"},
                                {
        group = GROUP,
        buffer = bufnr,
        callback = function()
            stop_timer()
            state.debounce_timer = uv.new_timer()
            state.debounce_timer:start(config.get().debounce_ms, 0,
                                       vim.schedule_wrap(
                                           function()
                    M.compile(state.live_target)
                end))
        end
    })

    logger.info("Live compilation enabled.")
    return true
end

function M.disable_live()
    vim.api.nvim_clear_autocmds({group = GROUP})
    stop_timer()

    state.live_enabled = false
    state.live_target = nil
    state.live_bufnr = nil

    logger.info("Live compilation disabled.")
end

function M.toggle_live(target)
    if state.live_enabled then
        M.disable_live()
        return
    end

    M.enable_live(target)
end

return M
