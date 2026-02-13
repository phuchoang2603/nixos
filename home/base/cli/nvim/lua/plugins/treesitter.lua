return {
  'nvim-treesitter/nvim-treesitter',
  config = function()
    local filetypes = {
      -- Core
      'bash',
      'c',
      'cpp',
      'diff',
      'html',
      'lua',
      'luadoc',
      'markdown',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',

      -- Programming Languages
      'python',
      'go',
      'gomod',
      'gowork',
      'gosum',
      'javascript',
      'typescript',
      'tsx',
      'json',
      'yaml',
      'toml',
      'sql',

      -- DevOps & Infrastructure
      'dockerfile',
      'terraform',
      'hcl',
      'nix',
      'helm',

      -- Config files
      'gitignore',
      'gitcommit',
      'git_rebase',
      'git_config',

      -- LaTeX
      'latex',
      'bibtex',
    }

    require('nvim-treesitter').install(filetypes)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = filetypes,
      callback = function() vim.treesitter.start() end,
    })
  end,
}
