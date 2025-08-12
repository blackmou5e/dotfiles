-- Some basic qol settings
vim.o.mouse = ""
vim.o.termguicolors = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.signcolumn = "yes"
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.scrolloff = 8


-- leader, obviously
vim.g.mapleader = " "

-- New built-in plugin manager, here we go guys!
vim.pack.add({
    { src = "https://github.com/vague2k/vague.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/echasnovski/mini.pick" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/chomosuke/typst-preview.nvim" },
    { src = "https://github.com/p00f/clangd_extensions.nvim" },
})

require("nvim-treesitter.configs").setup({
    ensure_installed = { "lua", "luadoc", "c", "cpp", "terraform", "helm", "go" },
    auto_install = false,
    highlight = { enabled = true },
})

-- A bit of omnicomplete and lsp magic, to enable them doing love
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
    end,
})
vim.cmd("set completeopt+=noselect")

vim.lsp.enable({ "lua_ls", "clangd", "gopls", "helm_ls", "tinymist" })

-- diagnostics setup
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
        source = "if_many",
        header = "",
        prefix = "",
    }
})

vim.keymap.set('n', '<leader>lf', vim.lsp.buf.format)


-- snippets
local ls = require("luasnip")
ls.setup({ enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })

vim.keymap.set({ "i" }, "<C-e>", function() ls.expand() end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-J>", function() ls.jump(1) end, { silent = true })
vim.keymap.set({ "i", "s" }, "<C-K>", function() ls.jump(-1) end, { silent = true })


-- Theme settings, nothing interesting in particular
require("vague").setup({
    transparent = true, -- don't set background
    -- disable bold/italic globally in `style`
    bold = true,
    italic = true,
    style = {
        -- "none" is the same thing as default. But "italic" and "bold" are also valid oions
        boolean = "bold",
        number = "none",
        float = "none",
        error = "bold",
        comments = "italic",
        conditionals = "none",
        functions = "none",
        headings = "bold",
        operators = "none",
        strings = "none",
        variables = "none",

        -- keywords
        keywords = "none",
        keyword_return = "italic",
        keywords_loop = "none",
        keywords_label = "none",
        keywords_exception = "none",

        -- builtin
        builtin_constants = "bold",
        builtin_functions = "none",
        builtin_types = "bold",
        builtin_variables = "none",
    },
    -- plugin styles where applicable
    -- make an issue/pr if you'd like to see more styling oions!
    plugins = {
        lsp = {
            diagnostic_error = "bold",
            diagnostic_hint = "none",
            diagnostic_info = "italic",
            diagnostic_ok = "none",
            diagnostic_warn = "bold",
        },
    },
})

vim.cmd("colorscheme vague")


-- plugins init
require("oil").setup({
    view_options = {
        show_hidden = true,
        is_hidden_file = function(name, bufnr)
            local m = name:match("^%.")
            return m ~= nil
        end,
        is_always_hidden = function(name, bufnr)
            return false
        end,
        natural_order = "fast",
        case_insensitive = false,
        sort = {
            { "type", "asc" },
            { "name", "asc" },
        },
    }
})
require("mini.pick").setup()

-- some keymaps
vim.keymap.set('n', '<leader>f', ':Pick files<CR>')
vim.keymap.set('n', '<leader>h', ':Pick help<CR>')
vim.keymap.set('n', '<leader>e', ':Oil<CR>')
