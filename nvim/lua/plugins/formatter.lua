return {
  {
    'stevearc/conform.nvim',
    init = function()
      vim.keymap.set('n', '<leader>F', require 'conform'.format, { silent = true })
    end,
    opts = function()
      return {
        formatters = {
          -- config working directory に prettierrc がある場合に利用可能とみなす
          -- cf. https://github.com/stevearc/conform.nvim/issues/407#issuecomment-2120988992
          prettier = {
            require_cwd = true,
            cwd = require 'conform.util'.root_file {
              '.prettierrc',
              '.prettierrc.json',
              '.prettierrc.js',
              '.prettierrc.cjs',
              '.prettierrc.mjs',
              'prettier.config.js',
              'prettier.config.cjs',
              'prettier.config.mjs',
            },
          },
          biome = { require_cwd = true },
          injected = {
            options = {
              lang_to_formatters = {
                html = { 'prettier', 'biome', stop_after_first = true },
              },
            },
          },
        },
        formatters_by_ft = {
          html = { 'injected', lsp_format = 'first' },
          markdown = { 'deno_fmt', 'injected' },
          javascript = { 'prettier', 'biome', stop_after_first = true },
          typescript = { 'prettier', 'biome', stop_after_first = true },
          typescriptreact = { 'prettier', 'biome', stop_after_first = true },
          vue = { 'prettier', 'biome', stop_after_first = true },
          lua = { 'stylua', stop_after_first = true },
        },
        format_on_save = {},
        default_format_opts = {
          lsp_format = 'last',
        },
      }
    end,
  },
}
