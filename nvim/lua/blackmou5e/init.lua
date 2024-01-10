require("blackmou5e.set")
require("blackmou5e.remap")
require("blackmou5e.lazy")

local augroup = vim.api.nvim_create_augroup
local blackmou5e_group = augroup("blackmou5e", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
    require("plenary.reload").reload_module(name)
end

autocmd("TextYankPost", {
    group = yank_group,
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({
            higroup = "IncSearch",
            timeout = 40,
        })
    end,
})

autocmd({ "BufWritePre" }, {
    group = blackmou5e_group,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd('LspAttach', {
    group = blackmou5e_group,
    callback = function(e)
        local opts = { buffer = e.buf }
	    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
	    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
	    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
	    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
	    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
	    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
	    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
	    vim.keymap.set("n", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
    end
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
vim.cmd("colorscheme rose-pine")
