-- [[ Autocommands ]]

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Disable automatic comment continuation
-- 'r' = auto-insert comment leader after <Enter> in Insert mode
-- 'o' = auto-insert comment leader after 'o' or 'O' in Normal mode
vim.api.nvim_create_autocmd('BufEnter', {
  group = vim.api.nvim_create_augroup('disable_comment_continuation', { clear = true }),
  callback = function() vim.opt.formatoptions:remove { 'r', 'o' } end,
})

-- Manually add common Ansible folders to the search path
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'yaml.ansible',
  callback = function()
    local current_file_dir = vim.fn.expand '%:p:h'
    vim.opt_local.path = '.,' .. current_file_dir .. ',' .. current_file_dir .. '/roles'
    vim.opt_local.suffixesadd = '/tasks/main.yml,/tasks/main.yaml,.yml,.yaml'
    vim.opt_local.isfname:append '-'
  end,
})
