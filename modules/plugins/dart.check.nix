{ pkgs, nvim }:
pkgs.runCommand "nvim-dart-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p/lib && cd $HOME/p
    printf 'name: x\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n' > pubspec.yaml
    printf 'void main() {\n  int x = "s";\n}\n' > lib/main.dart
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      vim.cmd("edit lib/main.dart")
      ok(vim.treesitter.language.add("dart"), "dart parser")
      ok(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "treesitter highlight active")
      -- lz.n loads flutter-tools on ft=dart
      ok(vim.wait(10000, function() return vim.fn.exists(":FlutterRun") == 2 end, 100), "FlutterRun command (flutter-tools lazy load)")
      ok(vim.fn.executable("flutter") == 1 and vim.fn.executable("dart") == 1, "flutter/dart on PATH")
      ok(vim.wait(90000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "dartls" }) > 0 end, 200), "dartls attach")
      ok(vim.wait(90000, function() return #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }) > 0 end, 200), "type error diagnostic")
      io.stdout:write("DART_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 200 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q DART_OK
    touch $out
  ''
