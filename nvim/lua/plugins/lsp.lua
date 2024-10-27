return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local nvim_lsp = require("lspconfig")
            local mason_lspconfig = require("mason-lspconfig")

            local protocol = require("vim.lsp.protocol")

            local on_attach = function(client, bufnr)
                -- format on save
                if client.server_capabilities.documentFormattingProvider then
                    vim.api.nvim_create_autocmd("BufWritePre", {
                        group = vim.api.nvim_create_augroup("Format", { clear = true }),
                        buffer = bufnr,
                        callback = function()
                            vim.lsp.buf.format()
                        end,
                    })
                end
            end

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            nvim_lsp["nixd"].setup({
                on_attach = on_attach,
                capabilities = capabilities,
                cmd = { "nixd" },
                settings = {
                    nixd = {
                        nixpkgs = {
                            expre = "import <nixpkgs> { }"
                        },
                        formatting = {
                            command = { "nixpkgs-fmt" },
                        }
                    }
                }
            })

            mason_lspconfig.setup_handlers({
                function(server)
                    nvim_lsp[server].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["gopls"] = function()
                    nvim_lsp["gopls"].setup({
                        filtypes = { "go", "gomod" },
                        root_dir = require("lspconfig").util.root_pattern("go.work", "go.mod", ".git"),
                        settings = {
                            gopls = {
                                analyses = {
                                    unusedparams = true,
                                },
                                staticcheck = true,
                            }
                        }
                    })
                end,
                ["helm_ls"] = function()
                    nvim_lsp["helm_ls"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["ts_ls"] = function()
                    nvim_lsp["ts_ls"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["volar"] = function()
                    nvim_lsp["volar"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["cssls"] = function()
                    nvim_lsp["cssls"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["html"] = function()
                    nvim_lsp["html"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                ["jsonls"] = function()
                    nvim_lsp["jsonls"].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
            })
        end,
    },
    { "folke/lazydev.nvim", ft = "lua", opts = {} },
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                c = { "clangformat" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
            notify_on_error = false,
        },
    },
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            "lua_ls",
            "gopls",
            "rust_analyzer",
            "zls",
            "yamlls",
            "ts_ls",
            "volar"
        },
    },
}
