{ pkgs, nvim }:
pkgs.runCommand "nvim-mini-files-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/proj/sub
    echo hi > $HOME/proj/a.txt
    echo deep > $HOME/proj/sub/b.txt
    cd $HOME/proj
    cat > probe.lua <<'LUA'
    local function main()
      local function ok(c, m) if not c then error("FAIL: " .. m) end end
      local function wait() vim.wait(300, function() return false end) end
      local function row(name)
        for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
          if l:find(name, 1, true) then return i end
        end
        error("FAIL: no entry " .. name)
      end
      require("lz.n").trigger_load("mini.files")
      require("mini.files").open(vim.uv.cwd(), true)
      wait()
      ok(vim.bo.filetype == "minifiles", "opened")
      ok(vim.fn.maparg("<CR>", "n", false, true).buffer == 1, "<CR> buffer map")
      -- directory: enter, explorer stays open
      vim.api.nvim_win_set_cursor(0, { row("sub"), 0 })
      vim.api.nvim_feedkeys(vim.keycode("<CR>"), "mx", false)
      wait()
      ok(vim.bo.filetype == "minifiles", "still open after entering dir")
      ok(vim.api.nvim_buf_get_name(0):find("sub", 1, true), "inside sub")
      vim.api.nvim_feedkeys("h", "mx", false)
      wait()
      -- file: open and close explorer
      vim.api.nvim_win_set_cursor(0, { row("a.txt"), 0 })
      vim.api.nvim_feedkeys(vim.keycode("<CR>"), "mx", false)
      wait()
      ok(vim.bo.filetype ~= "minifiles", "explorer closed after opening file")
      ok(vim.api.nvim_buf_get_name(0):find("a.txt", 1, true), "file opened")
      print("MINIFILES_OK")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then print(err) end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 60 "$nvim/bin/nvim" --headless -S probe.lua 2>&1 || true)
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -qx MINIFILES_OK
    touch $out
  ''
