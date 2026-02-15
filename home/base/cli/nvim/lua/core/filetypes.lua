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
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/defaults/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/molecule/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/ansible/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/host_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/group_vars/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*playbook.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/handlers/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/defaults/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*/vars/.*%.ya?ml'] = 'yaml.ansible',
    -- Terraform vars
    ['.*%.tfvars'] = 'terraform-vars',
  },
}
