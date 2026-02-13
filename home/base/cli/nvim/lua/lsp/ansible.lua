-- Ansible language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    ansiblels = {
      root_dir = utils.get_root_dir { 'ansible.cfg', '.ansible-lint', '.git' },
    },
  },
  format = {},
  lint = {},
  -- Additional plugins for Ansible support
  plugins = {
    {
      'mfussenegger/nvim-ansible',
      ft = { 'yaml.ansible', 'ansible' },
      config = function()
        -- Automatically detect Ansible files
        vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
          pattern = {
            '*/playbooks/*.yml',
            '*/playbooks/*.yaml',
            '*/roles/*/tasks/*.yml',
            '*/roles/*/tasks/*.yaml',
            '*/roles/*/handlers/*.yml',
            '*/roles/*/handlers/*.yaml',
            '*/ansible/*.yml',
            '*/ansible/*.yaml',
            '*play*.yml',
            '*play*.yaml',
          },
          callback = function()
            vim.bo.filetype = 'yaml.ansible'
          end,
        })
      end,
    },
  },
}
