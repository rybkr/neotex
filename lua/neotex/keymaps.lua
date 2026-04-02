local compiler = require("neotex.compiler")
local pdfviewer = require("neotex.pdfviewer")
local snippets = require("neotex.snippets")


local M = {}

local keymap = vim.keymap

function M.setup()
    snippets.setup()

    keymap.set("n", "<leader>lc", function()
        compiler.compile()
    end, { noremap = true, silent = true, desc = "Compile LaTeX" })

    keymap.set("n", "<leader>lo", function()
        pdfviewer.view_pdf()
    end, { noremap = true, silent = true, desc = "Open PDF" })

    keymap.set("n", "<leader>lp", function()
        compiler.compile(nil, function(did_compile)
            if not did_compile then
                return
            end

            pdfviewer.view_pdf()
        end)
    end, { noremap = true, silent = true, desc = "Compile LaTeX and open PDF" })

    keymap.set("n", "<leader>ll", function()
        compiler.toggle_live()
    end, { noremap = true, silent = true, desc = "Toggle live LaTeX compilation" })

    keymap.set("n", "<leader>lj", function()
        pdfviewer.forward_search()
    end, { noremap = true, silent = true, desc = "Jump from TeX to PDF" })

    local has_luasnip = pcall(require, "luasnip")
    if not has_luasnip then
        return
    end

    keymap.set("i", "<Tab>", "<cmd>lua require('luasnip').expand_or_jump()<CR>", { noremap = true, silent = true })
    keymap.set("s", "<Tab>",
        "<cmd>lua require'luasnip'.jump(1)<CR>",
        { noremap = true, silent = true })
    keymap.set("i", "<S-Tab>",
        "<cmd>lua require'luasnip'.jump(-1)<CR>",
        { noremap = true, silent = true })
    keymap.set("s", "<S-Tab>",
        "<cmd>lua require'luasnip'.jump(-1)<CR>",
        { noremap = true, silent = true })
end

return M
