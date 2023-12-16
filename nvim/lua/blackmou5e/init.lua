require("blackmou5e.set")
require("blackmou5e.remap")
require("blackmou5e.packer")

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

autocmd({"BufWritePre"}, {
	group = blackmou5e_group,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
