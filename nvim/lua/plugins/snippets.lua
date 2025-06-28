return {
    "L3MON4D3/LuaSnip",
    dependencies = {
        "rafamadriz/friendly-snippets",
        "benfowler/telescope-luasnip.nvim",
    },

    config = function(_, opts)
        if opts then require("luasnip").config.setup(opts) end
        vim.tbl_map(
            function(type) require("luasnip.loaders.from_".. type).lazy_load() end,
            { "vscode", "snipmate", "lua" }
        )
        require("luasnip").filetype_extend("html", { "html" })
        require("luasnip").filetype_extend("php", { "html", "php" })
    end,
}
