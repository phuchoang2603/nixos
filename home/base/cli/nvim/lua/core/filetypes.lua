-- Register the custom filetypes Neovim doesn't know by default
vim.filetype.add {
  extension = {},
  filename = {
    ['go.work'] = 'gowork',
    ['docker-compose.yaml'] = 'yaml.docker-compose',
    ['docker-compose.yml'] = 'yaml.docker-compose',
    ['compose.yaml'] = 'yaml.docker-compose',
    ['compose.yml'] = 'yaml.docker-compose',
    ['.gitlab-ci.yml'] = 'yaml.gitlab',
  },
  pattern = {
    -- Match Helm templates (usually in a 'templates' folder)
    ['.*/templates/.*%.yaml'] = 'helm',
    ['.*/templates/.*%.tpl'] = 'gotmpl',
    -- Match Ansible playbooks
    ['.*/%(tasks%|defaults%|group_vars%|host_vars%|handlers%|vars%|molecule%|ansible%|playbooks%)/.*%.ya?ml'] = 'yaml.ansible',
    ['.*playbook.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/.*%.ya?ml'] = 'yaml.ansible',
    -- Terraform vars
    ['.*%.tfvars'] = 'terraform-vars',
  },
}

-- Manually add common Ansible folders to the search path
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'yaml.ansible',
  callback = function()
    vim.opt_local.path:append { 'tasks', 'templates', 'files', 'vars', 'handlers' }
    vim.opt_local.suffixesadd:prepend { '.yml', '.yaml', '.sh', '.j2' }
  end,
})
