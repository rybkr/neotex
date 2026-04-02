local utils = require("neotex.utils")

local M = {}

local function collect_matches(path, matcher)
    local matches = {}

    if not utils.file_exists(path) then return matches end

    for line in io.lines(path) do
        if matcher(line) then table.insert(matches, vim.trim(line)) end
    end

    return matches
end

function M.parse_log(path)
    if not utils.file_exists(path) then
        return {errors = {}, warnings = {}, overfull = {}}
    end

    return {
        errors = collect_matches(path,
                                 function(line) return line:match("^!") end),
        warnings = collect_matches(path, function(line)
            return line:match("Warning:")
        end),
        overfull = collect_matches(path, function(line)
            return line:match("Overfull %\\hbox") or
                       line:match("Underfull %\\hbox")
        end)
    }
end

return M
