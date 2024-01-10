return {
    "tpope/vim-fugitive",
    config = function()
        vim.keymap.set("n", "<leader>gs", vim.cmd.Git)

        local blackmou5e_fugitive = vim.api.nvim_create_augroup("blackmou5e_fugitive", {})
        local autocmd = vim.api.nvim_create_autocmd
        autocmd("BufWinEnter", {
        	group = blackmou5e_fugitive,
        	pattern = "*",
        	callback = function()
        		if vim.bo.ft ~= "fugitive" then
        			return
        		end
        		local bufnr = vim.api.nvim_get_current_buf()
        		local opts = {buffer = bufnr, remap = false}
        		vim.keymap.set("n", "<leader>p", function()
        			vim.cmd.Git('push')
        		end, opts)
        		-- always rebase
        		vim.keymap.set("n", "<leader>P", function()
        			vim.cmd.Git({'pull', '--rebase'})
        		end, opts)
        		-- set branch if it's not done via cli
        		vim.keymap.set("n", "<leader>t", ":Git push -u origin ", opts);
        	end,
        })
    end
}
