{ pkgs, nvim }:
pkgs.runCommand "nvim-trouble-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf '# TODO: first\nx = 1\n# FIXME: second\n# NOTE: third\n' > a.py
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["trouble"] == nil and package.loaded["todo-comments"] == nil, "both lazy at start")
      for _, k in ipairs({ "<leader>xx", "<leader>xX", "<leader>cs", "<leader>cS", "<leader>xL", "<leader>xQ", "[q", "]q", "<leader>xt", "<leader>xT", "]t", "[t", "<leader>st", "<leader>sT" }) do
        ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
      end
      vim.cmd("Trouble diagnostics toggle")
      ok(package.loaded["trouble"] ~= nil, ":Trouble loads trouble")
      vim.cmd("only | edit a.py")
      ok(package.loaded["todo-comments"] ~= nil, "todo-comments loads on buffer read")
      ok(vim.wait(5000, function() return Snacks.picker.sources.todo_comments ~= nil end, 50), "snacks todo_comments source registered")
      vim.cmd("TodoQuickFix")
      ok(vim.wait(5000, function() return #vim.fn.getqflist() >= 3 end, 100), "TodoQuickFix finds TODO/FIXME/NOTE")
      ok(pcall(require, "trouble.sources.profiler"), "snacks profiler trouble source")
      ok(pcall(require, "trouble.sources.todo"), "todo trouble source")
      io.stdout:write("TROUBLE_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 100 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q TROUBLE_OK
    touch $out
  ''
