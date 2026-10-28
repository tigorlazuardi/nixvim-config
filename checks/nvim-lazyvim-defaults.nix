{ pkgs, nvim }:
pkgs.runCommand "nvim-lazyvim-defaults-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    printf '# t\n' > a.md
    printf 'x\n' > b.ts
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(vim.g.mapleader == " " and vim.g.maplocalleader == "\\", "leader keys set")
      ok(vim.fn.maparg("<leader>sp", "n") == "", "no lazy.nvim-only <leader>sp")
      ok(vim.o.relativenumber and vim.o.ruler == false, "LazyVim options applied")
      ok(vim.o.completeopt == "menu,menuone,noselect", "completeopt")
      ok(vim.o.tabstop == 4 and vim.o.clipboard == "unnamedplus", "owner overrides kept")
      ok(vim.o.foldlevelstart == 99 and vim.o.foldlevel == 99, "folds open")
      ok(vim.o.mousefocus, "mousefocus")
      local keys = {
        { "n", "<C-Up>" }, { "n", "<leader>-" }, { "n", "<leader>wd" }, { "n", "<A-j>" },
        { "v", "<A-j>" }, { "n", "<leader>bb" }, { "n", "<leader>bd" }, { "n", "<leader><tab><tab>" },
        { "n", "n" }, { "n", "<C-s>" }, { "n", "<leader>K" }, { "n", "gco" }, { "n", "<leader>qq" },
        { "n", "]d" }, { "n", "[e" }, { "n", "<leader>gl" }, { "n", "<leader>ft" },
        { "n", "<leader>us" }, { "n", "<leader>uw" }, { "n", "<leader>uL" }, { "n", "<leader>ud" },
        { "n", "<leader>uT" }, { "n", "<leader>wm" }, { "n", "<C-S-v>" }, { "v", "<LeftRelease>" },
        { "n", "<MiddleMouse>" }, { "n", "<C-LeftMouse>" }, { "n", "<RightMouse>" }, { "i", "," },
      }
      for _, k in ipairs(keys) do
        ok(vim.fn.maparg(k[2], k[1]) ~= "", "map " .. k[1] .. " " .. k[2])
      end
      vim.cmd("edit a.md")
      ok(vim.wo.wrap and vim.wo.spell, "markdown wrap + spell")
      vim.cmd("edit b.ts")
      ok(vim.bo.tabstop == 4 and vim.bo.shiftwidth == 4, "TS/JS indent 4")
      local before = vim.wo.relativenumber
      vim.api.nvim_feedkeys(vim.keycode("<leader>uL"), "x", false)
      ok(vim.wo.relativenumber ~= before, "<leader>uL toggles relativenumber")
      vim.cmd("startinsert")
      vim.snippet.expand("foo ''${1:bar} baz")
      ok(vim.snippet.active(), "snippet active")
      vim.api.nvim_feedkeys(vim.keycode("<esc>"), "x", false)
      ok(not vim.snippet.active(), "<esc> stops snippet")
      ok(#vim.api.nvim_get_autocmds({ group = "HighlightYank" }) == 1, "yank highlight autocmd")
      io.stdout:write("DEFAULTS_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 100 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q DEFAULTS_OK
    touch $out
  ''
