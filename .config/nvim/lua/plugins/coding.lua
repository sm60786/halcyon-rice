return {
  -- LSP servers, formatters, linters
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
        float = { border = "rounded" },
      },
      inlay_hints = { enabled = true },
      servers = {
        pyright = {},
        ruff = {},
        lua_ls = { settings = { Lua = { workspace = { checkThirdParty = false }, completion = { callSnippet = "Replace" } } } },
        ts_ls = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        jsonls = {},
        yamlls = {},
        bashls = {},
        dockerls = {},
        docker_compose_language_service = {},
        gopls = {},
        rust_analyzer = {},
        clangd = {},
      },
    },
  },

  -- Mason: auto-install LSP servers, formatters, linters
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        "shellcheck",
        "black",
        "isort",
        "ruff",
        "prettier",
        "eslint_d",
        "goimports",
        "gofumpt",
        "rustywind",
        "clang-format",
      },
      ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "goimports", "gofumpt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        ["_"] = { "trim_whitespace" },
      },
      format_on_save = { timeout_ms = 3000, lsp_fallback = true },
    },
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "ruff" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
      },
    },
  },


  -- Treesitter: advanced syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "c", "cpp", "css", "dockerfile", "go", "gomod", "gowork",
        "html", "javascript", "json", "json5", "jsonc", "lua", "luadoc",
        "luap", "markdown", "markdown_inline", "python", "query", "regex",
        "rust", "sql", "toml", "tsx", "typescript", "vim", "vimdoc",
        "xml", "yaml", "zig",
      },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
        },
      },
    },
  },

  -- Comments
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = { enable_autocmd = false },
  },

  -- Refactoring helpers
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>re", function() require("refactoring").refactor("Extract Function") end, mode = "v", desc = "Extract Function" },
      { "<leader>rv", function() require("refactoring").refactor("Extract Variable") end, mode = "v", desc = "Extract Variable" },
      { "<leader>ri", function() require("refactoring").refactor("Inline Variable") end, mode = { "n", "v" }, desc = "Inline Variable" },
    },
    opts = {},
  },
}
