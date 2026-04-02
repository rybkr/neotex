local M = {}

function M.setup()
    local ok, ls = pcall(require, "luasnip")
    if not ok then
        return
    end

    local s = ls.snippet
    local t = ls.text_node
    local i = ls.insert_node
    local f = ls.function_node

    ls.add_snippets("tex", {
        s("env", {
            t("\\begin{"),
            i(1, "environment"),
            t({ "}", "\t" }),
            i(0),
            t({ "", "\\end{" }),
            f(function(args)
                return args[1][1]
            end, { 1 }),
            t("}"),
        }),
    }, {
        key = "neotex",
    })
end

return M
