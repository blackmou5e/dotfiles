return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = "nvim-lua/plenary.nvim",
        keys = function()
            local harpoon = require("harpoon")
            return {
                { "<leader>;", function() harpoon:list():add() end },
                { "<leader>]", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end },
                { "<leader>h", function() harpoon:list():select(1) end },
                { "<leader>j", function() harpoon:list():select(2) end },
                { "<leader>k", function() harpoon:list():select(3) end },
                { "<leader>l", function() harpoon:list():select(4) end },
            }
        end,
        opts = { settings = { save_on_toggle = true } },
    },
}
