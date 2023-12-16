require("cloak").setup({
	enabled = true,
	cloak_character = "*",
	highlight_group = "Comment",
	patterns = {
		{
			file_pattern = {
				".env*",
				"wrangler.tomls",
				".dev.vars",
			},
			cloak_pattern = "=.+"
		},
	},
})
