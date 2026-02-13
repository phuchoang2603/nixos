-- Terraform language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    terraformls = {
      root_dir = utils.get_root_dir { '.terraform', '.git' },
    },
    tflint = {
      root_dir = utils.get_root_dir { '.tflint.hcl', '.terraform', '.git' },
    },
  },
  format = {
    terraform = { 'terraform_fmt' },
    tf = { 'terraform_fmt' },
    ['terraform-vars'] = { 'terraform_fmt' },
  },
  lint = {
    terraform = { 'terraform_validate' },
    tf = { 'terraform_validate' },
  },
}
