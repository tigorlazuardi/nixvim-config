{ pkgs, nvim }:
pkgs.runCommand "nvim-conform-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    cat > probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function write(name, text)
      local f = io.open(name, "w"); f:write(text); f:close()
    end
    local function main()
      vim.cmd("doautocmd User DeferredUIEnter")
      ok(package.loaded["conform"] == nil, "conform must stay lazy at start")
      for _, k in ipairs({ "<leader>cf", "<leader>cF", "<leader>uf", "<leader>uF" }) do
        ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
      end
      write("a.nix", "{a=1;b=   [1 2   3];}\n")
      vim.cmd("silent edit a.nix")
      vim.cmd("silent write")
      ok(package.loaded["conform"] ~= nil, "conform loaded by save")
      ok(table.concat(vim.fn.readfile("a.nix"), "\n"):find("  a = 1;", 1, true), "nixfmt ran on save")
      vim.g.autoformat = false
      write("b.nix", "{a=1;}\n")
      vim.cmd("silent edit b.nix")
      vim.cmd("silent write")
      ok(vim.fn.readfile("b.nix")[1] == "{a=1;}", "global toggle off skips format")
      vim.g.autoformat = nil
      vim.b.autoformat = false
      vim.cmd("silent write")
      ok(vim.fn.readfile("b.nix")[1] == "{a=1;}", "buffer toggle off skips format")
      vim.b.autoformat = true
      vim.g.autoformat = false
      vim.cmd("silent write")
      ok(vim.fn.readfile("b.nix")[1] ~= "{a=1;}", "buffer on overrides global off")
      io.stdout:write("CONFORM_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 60 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q CONFORM_OK
    touch $out
  ''
