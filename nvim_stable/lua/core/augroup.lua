vim.api.nvim_create_autocmd(
    {
        "BufNewfile",
        "BufRead",
        "BufEnter",
    },
    {
        pattern = "**/.helm/**/*.yaml",
        callback = function()
            vim.api.nvim_set_option_value("filetype", "helm", {})
        end
    }
)
