{ pkgs, nvim }:
pkgs.runCommand "nvim-helper-edit-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf 'x = 5\nfoo\nbar\n' > a.lua
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      for _, m in ipairs({ "grug-far", "dial.map", "inc_rename", "yanky" }) do
        ok(package.loaded[m] == nil, m .. " lazy at start")
      end
      for _, k in ipairs({ "<leader>sr", "<leader>cr", "<C-a>", "<C-x>", "g<C-a>", "g<C-x>", "<leader>p", "y", "p", "P", "gp", "gP", "[y", "]y", "]p", "[p", "<p", ">p", "=p" }) do
        ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
      end
      ok(vim.fn.maparg("<F2>", "n"):find("vim.lsp.buf.rename", 1, true), "F2 still plain rename")
      ok(vim.fn.exists(":IncRename") == 2 and vim.fn.exists(":GrugFar") == 2, "commands exist")
      vim.cmd("edit a.lua")
      vim.cmd("normal! gg")
      vim.api.nvim_feedkeys(vim.keycode("<C-a>"), "x", false)
      ok(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "x = 6", "dial increments")
      vim.cmd("normal! jyy")
      vim.api.nvim_feedkeys("p", "x", false)
      ok(vim.wait(3000, function() return vim.api.nvim_buf_get_lines(0, 2, 3, false)[1] == "foo" end, 50), "yanky put")
      ok(#require("yanky.history").all() >= 1, "yank ring has entry")
      ok(Snacks.picker.sources.yanky ~= nil, "snacks yanky source")
      local cr = vim.fn.maparg("<leader>cr", "n", false, true)
      vim.cmd("normal! 2G")
      ok(cr.expr == 1, "cr is an expr map")
      pcall(cr.callback) -- lz.n stub: loads the plugin and replays the key
      ok(package.loaded["inc_rename"] ~= nil, "inc-rename loaded by key")
      cr = vim.fn.maparg("<leader>cr", "n", false, true)
      ok(cr.callback() == ":IncRename foo", "cr expr gives IncRename prefill")
      vim.cmd("GrugFar")
      ok(vim.bo.filetype == "grug-far", "GrugFar opens")
      io.stdout:write("HELPER_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 100 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q HELPER_OK
    touch $out
  ''
