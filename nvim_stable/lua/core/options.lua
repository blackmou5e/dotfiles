vim.opt.mouse = ""
vim.opt.termguicolors = true
vim.opt.swapfile = false
vim.opt.updatetime = 50

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.numberwidth = 1

vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.wrap = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true


vim.diagnostic.config({
    update_in_insert = true,
    virtual_text = false,
    underline = true,
    virtual_lines = true,
    signs = true,
    float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = "always",
        header = "",
        prefix = "●",
    },
})
