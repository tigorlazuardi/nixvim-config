{ pkgs, nvim }:
pkgs.runCommand "nvim-go-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf 'module example.com/x\n\ngo 1.22\n' > go.mod
    printf 'package main\n\ntype S interface{ A() }\n\nfunc main() {\n\tvar x int = 1\n\t_ = x\n}\n' > main.go
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["telescope"] == nil and vim.fn.exists(":GoImpl") == 0, "goimpl/telescope lazy at start")
      vim.cmd("edit main.go")
      ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "gopls" }) > 0 end, 100), "gopls attach")
      local g = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })[1].config.settings.gopls
      ok(g.usePlaceholders == false, "usePlaceholders off")
      for k, v in pairs(g.hints) do ok(v == false, "hint off " .. k) end
      ok(g.analyses.shadow == false and g.analyses.ST1000 == false and g.analyses.ST1023 == false, "shadow/ST1xxx off")
      ok(g.analyses.nilness == true, "LazyVim analyses kept")
      ok(vim.fn.exists(":GoImpl") == 2, "GoImpl command")
      ok(vim.fn.maparg("<leader>im", "n") ~= "", "<leader>im map")
      ok(type(require("telescope").extensions.goimpl.goimpl) == "function", "telescope goimpl extension")
      for _, b in ipairs({ "dlv", "impl", "gopls", "goimports", "gofumpt" }) do ok(vim.fn.executable(b) == 1, "binary " .. b) end
      ok(#require("lint").linters_by_ft.go == 0, "golangci-lint off")
      io.stdout:write("GO_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 120 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q GO_OK
    touch $out
  ''
