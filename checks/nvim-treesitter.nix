{ pkgs, nvim }:
pkgs.runCommand "nvim-treesitter-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    printf 'package main\nfunc main() {}\n' > t.go
    cat > t.lua <<'LUA'
    vim.cmd("edit t.go")
    vim.cmd("doautocmd User DeferredUIEnter")
    vim.wait(500, function() return false end)
    vim.cmd("edit! t.go")
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    ok(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "ts highlight")
    ok(vim.wo.foldmethod == "expr", "foldmethod")
    ok(vim.o.foldlevelstart == 99, "foldlevelstart")
    ok(vim.fn.maparg("s", "n") ~= "", "flash s")
    ok(vim.fn.maparg("]f", "n") ~= "", "textobjects ]f")
    ok(package.loaded["mini.ai"], "mini.ai")
    ok(package.loaded["ts-comments"], "ts-comments")
    print("TS_OK")
    LUA
    res=$("$nvim/bin/nvim" --headless -S t.lua +qa 2>&1)
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -qx TS_OK
    touch $out
  ''
