local map = vim.keymap.set

-- Better escape
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize windows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move lines up/down
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move selection up" })

-- Better indenting (stay in visual mode)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" })

-- Select all
map("n", "<C-a>", "gg<S-v>G", { desc = "Select all" })

-- Save with Ctrl+S
map({ "n", "i", "v", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Quick split
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Horizontal split" })
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Vertical split" })

-- Shift+Arrow selection (VSCode-style)
map("n", "<S-Up>", "v<Up>", { desc = "Select up" })
map("n", "<S-Down>", "v<Down>", { desc = "Select down" })
map("n", "<S-Left>", "v<Left>", { desc = "Select left" })
map("n", "<S-Right>", "v<Right>", { desc = "Select right" })
map("v", "<S-Up>", "<Up>", { desc = "Select up" })
map("v", "<S-Down>", "<Down>", { desc = "Select down" })
map("v", "<S-Left>", "<Left>", { desc = "Select left" })
map("v", "<S-Right>", "<Right>", { desc = "Select right" })
map("i", "<S-Up>", "<Esc>v<Up>", { desc = "Select up" })
map("i", "<S-Down>", "<Esc>v<Down>", { desc = "Select down" })
map("i", "<S-Left>", "<Esc>v<Left>", { desc = "Select left" })
map("i", "<S-Right>", "<Esc>v<Right>", { desc = "Select right" })

-- Run current file
map("n", "<leader>rr", function()
  vim.cmd("w")
  local ft = vim.bo.filetype
  local cmd = ({
    python = "python3 " .. vim.fn.expand("%"),
    javascript = "node " .. vim.fn.expand("%"),
    typescript = "npx ts-node " .. vim.fn.expand("%"),
    go = "go run " .. vim.fn.expand("%"),
    rust = "cargo run",
    c = "gcc " .. vim.fn.expand("%") .. " -o /tmp/a.out && /tmp/a.out",
    cpp = "g++ " .. vim.fn.expand("%") .. " -o /tmp/a.out && /tmp/a.out",
    sh = "bash " .. vim.fn.expand("%"),
    lua = "lua " .. vim.fn.expand("%"),
  })[ft]
  if cmd then
    require("toggleterm").exec(cmd, nil, nil, nil, "float")
  else
    vim.notify("No run command for filetype: " .. ft, vim.log.levels.WARN)
  end
end, { desc = "Run current file" })

-- Diagnostic navigation
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
