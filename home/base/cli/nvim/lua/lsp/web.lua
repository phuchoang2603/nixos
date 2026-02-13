-- Web languages configuration (JavaScript, TypeScript, CSS, HTML, etc.)
-- This file contains formatters for web-related languages

return {
  lsp = {},
  format = {
    -- JavaScript
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    -- TypeScript
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    -- Vue
    vue = { 'prettierd', 'prettier', stop_after_first = true },
    -- CSS/SCSS/LESS
    css = { 'prettierd', 'prettier', stop_after_first = true },
    scss = { 'prettierd', 'prettier', stop_after_first = true },
    less = { 'prettierd', 'prettier', stop_after_first = true },
    -- HTML
    html = { 'prettierd', 'prettier', stop_after_first = true },
    -- GraphQL
    graphql = { 'prettierd', 'prettier', stop_after_first = true },
    -- Handlebars
    handlebars = { 'prettierd', 'prettier', stop_after_first = true },
  },
  lint = {},
}
