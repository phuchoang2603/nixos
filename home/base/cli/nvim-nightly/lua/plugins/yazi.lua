vim.pack.add({
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/mikavilpas/yazi.nvim' },
}
)

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    require("yazi").setup({
      open_for_directories = true,
    })
  end,
})

-- Keymap
local map = vim.keymap.set

-- Open yazi at the current file (Normal and Visual mode)
map({ 'n', 'v' }, '<leader>e', '<cmd>Yazi<cr>',
  { desc = 'Open yazi at the current file', silent = true })

-- Open yazi at the root working directory
map('n', '<leader>E', '<cmd>Yazi cwd<cr>',
  { desc = "Open the file manager in nvim's working directory", silent = true })
