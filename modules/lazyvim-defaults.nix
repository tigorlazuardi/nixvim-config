# LazyVim's plugin-independent defaults that the base modules did not cover
# (#18; options/autocmds live in opts.nix/autocmds.nix, plugin keys in their
# plugin modules): window/buffer/tab/line keymaps, <leader>u* toggles via
# Snacks.toggle, the owner's mouse bindings and the global <C-S-v> paste.
# Skipped on purpose: <leader>gg/gG (owner remapped lazygit to <leader>z),
# <leader>l/L (no lazy.nvim/LazyVim), [q ]q (trouble, #28), <leader>cf (conform).
# ponytail: one Lua block; split into nixvim `keymaps` when a consumer needs
# to override single keys from Nix.
{ lib, ... }:
{
  programs.nixvim.extraConfigLuaPost = lib.mkAfter ''
    local map = vim.keymap.set

    -- Windows: resize, splits
    map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
    map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
    map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
    map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
    map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
    map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
    map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

    -- Move lines
    map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
    map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
    map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
    map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
    map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
    map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

    -- Buffers
    map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
    map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
    map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
    map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
    map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Delete Buffer" })
    map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
    map("n", "<leader>bi", function() Snacks.bufdelete.invisible() end, { desc = "Delete Invisible Buffers" })
    map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })

    -- Tabs
    map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
    map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
    map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
    map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
    map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
    map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
    map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

    -- Search: n/N always forward/backward, centered open folds
    map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
    map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
    map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
    map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
    map("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
      { desc = "Redraw / Clear hlsearch / Diff Update" })

    -- Misc
    map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
    map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })
    map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
    map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
    map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
    map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
    map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
    map("n", "<leader>uI", function() vim.treesitter.inspect_tree() vim.api.nvim_input("I") end, { desc = "Inspect Tree" })
    map("n", "<leader>xl", function()
      local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
      if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
    end, { desc = "Location List" })
    map("n", "<leader>xq", function()
      local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
      if not ok and err then vim.notify(err, vim.log.levels.ERROR) end
    end, { desc = "Quickfix List" })

    -- Diagnostics (]] [[ severity nav lives in lspconfig.nix)
    local function jump(next, severity)
      return function()
        vim.diagnostic.jump({
          count = (next and 1 or -1) * vim.v.count1,
          severity = severity and vim.diagnostic.severity[severity] or nil,
          float = true,
        })
      end
    end
    map("n", "]d", jump(true), { desc = "Next Diagnostic" })
    map("n", "[d", jump(false), { desc = "Prev Diagnostic" })
    map("n", "]e", jump(true, "ERROR"), { desc = "Next Error" })
    map("n", "[e", jump(false, "ERROR"), { desc = "Prev Error" })
    map("n", "]w", jump(true, "WARN"), { desc = "Next Warning" })
    map("n", "[w", jump(false, "WARN"), { desc = "Prev Warning" })

    -- Git (snacks pickers); <leader>gd/gs/gS are in snacks.nix
    map("n", "<leader>gL", function() Snacks.picker.git_log() end, { desc = "Git Log (cwd)" })
    map("n", "<leader>gl", function() Snacks.picker.git_log({ cwd = vim.fn.getcwd() }) end, { desc = "Git Log" })
    map("n", "<leader>gb", function() Snacks.picker.git_log_line() end, { desc = "Git Blame Line" })
    map("n", "<leader>gf", function() Snacks.picker.git_log_file() end, { desc = "Git Current File History" })
    map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse (open)" })
    map({ "n", "x" }, "<leader>gY", function()
      Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
    end, { desc = "Git Browse (copy)" })

    -- Floating terminal (<c-/> is in snacks.nix)
    map("n", "<leader>fT", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })
    map("n", "<leader>ft", function() Snacks.terminal(nil, { cwd = vim.fn.getcwd() }) end, { desc = "Terminal (Root Dir)" })

    -- Toggles (<leader>uf/uF conform, ug/ut/up snacks.nix, uh lspconfig, um markdown)
    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.line_number():map("<leader>ul")
    Snacks.toggle.option("conceallevel", {
      off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level",
    }):map("<leader>uc")
    Snacks.toggle.option("showtabline", {
      off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline",
    }):map("<leader>uA")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
    Snacks.toggle.dim():map("<leader>uD")
    Snacks.toggle.animate():map("<leader>ua")
    Snacks.toggle.scroll():map("<leader>uS")
    Snacks.toggle.profiler_highlights():map("<leader>dph")
    Snacks.toggle.zoom():map("<leader>wm")

    -- Owner's mouse bindings
    local mopts = function(desc) return { silent = true, desc = desc } end
    map({ "n", "v", "s", "x", "o", "i", "l", "c", "t" }, "<C-S-v>",
      function() vim.api.nvim_paste(vim.fn.getreg("+"), true, -1) end, { noremap = true, silent = true, desc = "Paste" })
    map("v", "<LeftRelease>", '"+ygv', mopts("Copy to clipboard on mouse select"))
    map("n", "<MiddleMouse>", '"+p', mopts("Paste from clipboard"))
    map("i", "<MiddleMouse>", "<C-r>+", mopts("Paste from clipboard"))
    map("v", "<MiddleMouse>", '"+p', mopts("Paste from clipboard"))
    map("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", mopts("Go to definition"))
    map("n", "<2-LeftMouse>", 'viw"+y', mopts("Select word and copy"))
    map("n", "<3-LeftMouse>", '"+yy', mopts("Select line and copy"))
    map({ "n", "v" }, "<RightMouse>", function() vim.cmd("popup PopUp") end, mopts("Context menu"))
    map("n", "<A-ScrollWheelUp>", "4zh", mopts("Scroll left"))
    map("n", "<A-ScrollWheelDown>", "4zl", mopts("Scroll right"))
    vim.opt.mousefocus = true

    vim.g.markdown_recommended_style = 0
  '';
}
