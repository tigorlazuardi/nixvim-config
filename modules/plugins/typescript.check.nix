{ pkgs, nvim }:
pkgs.runCommand "nvim-typescript-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/proj/src && cd $HOME/proj
    git init -q
    echo '{"name":"x"}' > package.json
    touch package-lock.json
    echo '{"formatter":{"indentStyle":"space","indentWidth":2}}' > biome.json
    echo '{"compilerOptions":{"strict":true}}' > tsconfig.json
    printf 'const x:number="a"\nfunction  f( a ){return    a}\n' > src/a.ts
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      vim.cmd("edit src/a.ts")
      ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0 }) >= 2 end, 100), "tsc + biome attach")
      local names = {}
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[c.name] = true end
      ok(names.tsc and names.biome, "clients tsc and biome")
      ok(not names.vtsls and not names.tsgo and not names.ts_ls, "vtsls/tsgo/ts_ls not active")
      ok(vim.wait(20000, function() return #vim.diagnostic.get(0) > 0 end, 100), "tsc type diagnostics")
      ok(vim.bo.tabstop == 4 and vim.bo.shiftwidth == 4 and vim.bo.expandtab, "tabstop 4")
      vim.cmd("silent write")
      local text = table.concat(vim.fn.readfile("src/a.ts"), "\n")
      ok(text:find('const x: number = "a";', 1, true) and text:find("  return a;", 1, true), "biome formatted on save")
      io.stdout:write("TS_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 120 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q TS_OK
    touch $out
  ''
