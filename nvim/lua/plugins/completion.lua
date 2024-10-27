return {
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-path",
            {
                "L3MON4D3/LuaSnip",
                version = "v2.*",
                build = "make install_jsregexp",
            },
            "rafamadriz/friendly-snippets",
            "onsails/lspkind.nvim",
        },
        opts = function()
            local cmp = require("cmp")
            local lspkind = require("lspkind")
            local luasnip = require("luasnip")

            require("luasnip.loaders.from_vscode").lazy_load()


            return {
                    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
                    window = {
                        completion = { border = "rounded", scrollbar = false },
                        documentation = { border = "rounded", scrollbar = false },
                    },
                    completion = { completeopt = "menu,menuone,noinsert" },
                    mapping = {
                        ["<C-p>"] = cmp.mapping.select_prev_item(),
                        ["<C-n>"] = cmp.mapping.select_next_item(),
                        ["<C-y>"] = cmp.mapping.confirm(),
                    },
                    formatting = { fields = { "kind", "abbr", "menu" } },
                    sources = cmp.config.sources({
                        { name = "nvim_lsp" },
                        { name = "luasnip" },
                        { name = "path" },
                    }),
                },

                vim.cmd([[
                set completeopt=menuone,noinsert,noselect
                highlight! default link CmpItemKind CmpItemMenuDefault
            ]])
        end,
    },
    {
        "tpope/vim-surround",
    },
}
