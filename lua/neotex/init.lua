local config = require("neotex.config")
local commands = require("neotex.commands")
local keymaps = require("neotex.keymaps")

local M = {}

function M.setup(user_config)
    config.setup(user_config)
    commands.setup()
    keymaps.setup()

    local ok, luasnip = pcall(require, "luasnip")
    if not ok then
        return
    end

    luasnip.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
    })
end

return M
