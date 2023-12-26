require("rose-pine").setup({
    disable_background = true,
    variant = "main",
    dark_variant  = "main",
    bold_vert_split = false,
    dim_nc_background = false,
    disable_float_background = true,
    disable_italics = false,
})

function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMyPencils()
