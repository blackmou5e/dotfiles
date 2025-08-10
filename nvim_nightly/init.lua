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
vim.pack.add({ { src = "https://github.com/vague2k/vague.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/echasnovski/mini.pick" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/chomosuke/typst-preview.nvim" },
    { src = "https://github.com/p00f/clangd_extensions.nvim" },
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


-- some lua ls config, in order to make diagnostics shut up
vim.lsp.config['lua_ls'] = {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
            diagnostics = {
                globals = { "vim" },
            }
        }
    }
}

vim.lsp.enable({ "lua_ls", "clangd" })

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
    -- plugins = {
    --     cmp = {
    --         match = "bold",
    --         match_fuzzy = "bold",
    --     },
    --     dashboard = {
    --         footer = "italic",
    --     },
    --     lsp = {
    --         diagnostic_error = "bold",
    --         diagnostic_hint = "none",
    --         diagnostic_info = "italic",
    --         diagnostic_ok = "none",
    --         diagnostic_warn = "bold",
    --     },
    --     neotest = {
    --         focused = "bold",
    --         adapter_name = "bold",
    --     },
    --     telescope = {
    --         match = "bold",
    --     },
    -- },

    -- Override highlights or add new highlights
    -- on_highlights = function(highlights, colors) end,

    -- Override colors
    -- colors = {
    --     bg = "#141415",
    --     fg = "#cdcdcd",
    --     floatBorder = "#878787",
    --     line = "#252530",
    --     comment = "#606079",
    --     builtin = "#b4d4cf",
    --     func = "#c48282",
    --     string = "#e8b589",
    --     number = "#e0a363",
    --     property = "#c3c3d5",
    --     constant = "#aeaed1",
    --     parameter = "#bb9dbd",
    --     visual = "#333738",
    --     error = "#d8647e",
    --     warning = "#f3be7c",
    --     hint = "#7e98e8",
    --     operator = "#90a0b5",
    --     keyword = "#6e94b2",
    --     type = "#9bb4bc",
    --     search = "#405065",
    --     plus = "#7fa563",
    --     delta = "#f3be7c",
    -- },
})

vim.cmd("colorscheme vague")


-- plugins init
require("oil").setup()
require("mini.pick").setup()

-- some keymaps
vim.keymap.set('n', '<leader>f', ':Pick files<CR>')
vim.keymap.set('n', '<leader>h', ':Pick help<CR>')
vim.keymap.set('n', '<leader>e', ':Oil<CR>')
