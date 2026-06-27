return {
  -- Catppuccin colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        neotree = true,
        treesitter = true,
        notify = true,
        mini = { enabled = true },
        noice = true,
        telescope = { enabled = true },
        which_key = true,
        indent_blankline = { enabled = true },
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin" },
  },

  -- Indent guides (ibl v3)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│", tab_char = "│" },
      scope = { show_start = false, show_end = false },
      exclude = { filetypes = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble", "lazy", "mason", "notify", "toggleterm" } },
    },
  },

  -- Dashboard
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    opts = function()
      local logo = [[
      ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
      ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
      ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
      ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
      ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
      ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
      ]]
      logo = string.rep("\n", 4) .. logo .. "\n\n"
      local opts = {
        theme = "doom",
        hide = { statusline = false },
        config = {
          header = vim.split(logo, "\n"),
          center = {
            { action = "Telescope find_files", desc = " Find File", icon = " ", key = "f" },
            { action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
            { action = "Telescope oldfiles", desc = " Recent Files", icon = " ", key = "r" },
            { action = "Telescope live_grep", desc = " Find Text", icon = " ", key = "g" },
            { action = "e $MYVIMRC", desc = " Config", icon = " ", key = "c" },
            { action = 'lua require("persistence").load()', desc = " Restore Session", icon = " ", key = "s" },
            { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
            { action = "qa", desc = " Quit", icon = " ", key = "q" },
          },
          footer = function()
            local stats = require("lazy").stats()
            return { "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins" }
          end,
        },
      }
      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end
      return opts
    end,
  },

  -- Better notifications
  {
    "rcarriga/nvim-notify",
    opts = {
      timeout = 3000,
      render = "wrapped-compact",
      stages = "fade",
      max_height = function() return math.floor(vim.o.lines * 0.75) end,
      max_width = function() return math.floor(vim.o.columns * 0.75) end,
      on_open = function(win) vim.api.nvim_win_set_config(win, { zindex = 100 }) end,
    },
  },

  -- Scrollbar
  {
    "petertriho/nvim-scrollbar",
    event = "BufReadPost",
    opts = {
      handle = { blend = 30 },
      excluded_filetypes = { "neo-tree", "dashboard", "lazy", "mason", "notify" },
    },
  },

  -- Color highlighter
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPost",
    opts = {
      filetypes = { "*" },
      user_default_options = {
        css = true,
        tailwind = true,
        mode = "virtualtext",
        virtualtext = "■",
      },
    },
  },

  -- Window separators
  {
    "nvim-zh/colorful-winsep.nvim",
    event = "WinNew",
    opts = {},
  },
}
