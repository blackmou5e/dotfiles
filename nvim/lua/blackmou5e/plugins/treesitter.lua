return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
        ensure_installed = { "vimdoc", "c", "lua", "rust", "go" },
        sync_install = true,
        auto_install = true,

        highlight = {
        	enable = true,
        	additional_vim_regex_highlighting = false,
        },
    }
}
