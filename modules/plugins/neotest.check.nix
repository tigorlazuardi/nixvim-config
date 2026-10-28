{ pkgs, nvim }:
pkgs.runCommand "nvim-neotest-behaviour"
  {
    inherit nvim;
    # neotest-golang runs `go test -race`, which needs a C compiler.
    nativeBuildInputs = [
      pkgs.git
      pkgs.gcc
    ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf 'module example.com/x\n\ngo 1.22\n' > go.mod
    printf 'package x\n\nfunc Add(a, b int) int { return a + b }\n' > x.go
    printf 'package x\n\nimport "testing"\n\nfunc TestAdd(t *testing.T) {\n\tif Add(1, 2) != 3 {\n\t\tt.Fatal("bad")\n\t}\n}\n' > x_test.go
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["neotest"] == nil, "neotest lazy at start")
      for _, k in ipairs({ "tt", "tT", "tr", "tl", "ts", "to", "tO", "tS", "tw", "ta" }) do
        ok(vim.fn.maparg("<leader>" .. k, "n") ~= "", "map <leader>" .. k)
      end
      vim.cmd("edit x_test.go")
      require("lz.n").trigger_load("neotest")
      local nt = require("neotest")
      local names = {}
      for _, a in ipairs(require("neotest.config").adapters or {}) do names[#names + 1] = a.name end
      ok(vim.tbl_contains(names, "neotest-golang"), "golang adapter loaded")
      local started
      require("nio").run(function() nt.run.run(vim.fn.expand("%")); started = true end)
      ok(vim.wait(20000, function() return started end, 100), "run started")
      ok(vim.wait(90000, function()
        local ids = nt.state.adapter_ids()
        if not ids or #ids == 0 then return false end
        local c = nt.state.status_counts(ids[1])
        return c and c.passed and c.passed > 0
      end, 500), "go test passed via neotest")
      io.stdout:write("NEOTEST_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q NEOTEST_OK
    touch $out
  ''
