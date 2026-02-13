-- Docker language configuration
local utils = require 'lsp.utils'

return {
  lsp = {
    dockerls = {
      root_dir = utils.get_root_dir { 'Dockerfile', '.git' },
    },
    docker_compose_language_service = {
      root_dir = utils.get_root_dir { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml', '.git' },
    },
  },
  format = {},
  lint = {
    dockerfile = { 'hadolint' },
  },
}
