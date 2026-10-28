{ pkgs, nvim }:
pkgs.runCommand "nvim-lint-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    printf 'let x = 1; in { a = if true then 1 else 2; }\n' > a.nix
    printf '#!/bin/sh\necho $foo\n' > a.sh
    printf 'FROM ubuntu\nRUN apt-get install x\n' > Dockerfile
    printf '# T\n\n\n\ntext\n' > a.md
    printf 'package main\nfunc main(){}\n' > a.go
    cat > probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["lint"] == nil, "nvim-lint must stay lazy at start")
      vim.cmd("silent edit a.nix")
      ok(vim.wait(3000, function() return package.loaded["lint"] ~= nil end, 50), "loaded by first buffer")
      local by = require("lint").linters_by_ft
      ok(by.nix[1] == "statix" and by.sh[1] == "shellcheck", "nix/sh mapping")
      ok(by.markdown[1] == "markdownlint-cli2" and by.dockerfile[1] == "hadolint", "md/docker mapping")
      ok(type(by.go) == "table" and #by.go == 0, "go linters empty")
      local function has(file, why)
        vim.cmd("silent edit! " .. file)
        ok(vim.wait(20000, function() return #vim.diagnostic.get(0) > 0 end, 100), why)
      end
      has("a.nix", "statix diagnostics on .nix open")
      has("a.sh", "shellcheck diagnostics on .sh open")
      has("Dockerfile", "hadolint diagnostics on Dockerfile open")
      has("a.md", "markdownlint diagnostics on .md open")
      vim.cmd("silent edit! a.go")
      vim.wait(1500, function() return false end, 100)
      ok(#vim.diagnostic.get(0) == 0, "no linter diagnostics for go")
      io.stdout:write("LINT_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 120 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q LINT_OK
    touch $out
  ''
