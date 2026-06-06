vim.filetype.add({
  -- Match by file extension
  -- extension = {
  --   mdx = 'markdown',
  --   env = 'sh',
  --   config = 'toml',
  -- },

  -- Match by exact filename
  -- filename = {
  --   ['.env.local'] = 'sh',
  --   ['Jenkinsfile'] = 'groovy',
  -- },

  -- Match by regex/pattern (useful for complex paths or extensions)
  pattern = {
    -- Matches anything like '.tmux.conf.local'
    ['Jenkinsfile.*'] = 'groovy',
    -- ['%.tmux%.conf%.*'] = 'tmux',
    -- Matches README files inside a specific directory template
    -- ['.*/templates/.*%.txt'] = 'html',
  },
})
