return {
    "mfussenegger/nvim-dap",
    config = function()
        local dap = require('dap')
        dap.adapters.codelldb = {
            type = "executable",
            command = "codelldb", -- or if not in $PATH: "/absolute/path/to/codelldb"
            -- On windows you may have to uncomment this:
            -- detached = false,
        }
    end
}
