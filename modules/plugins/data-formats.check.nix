{ pkgs, nvim }:
pkgs.runCommand "nvim-data-formats-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p/.github/workflows && cd $HOME/p
    git init -q
    printf '{"name":"x","version":"1.0.0"}\n' > package.json
    printf 'name: ci\non: push\njobs:\n  a:\n    runs-on: x\n    steps: []\n' > .github/workflows/ci.yaml
    printf '[package]\nname = "x"\n' > Cargo.toml
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function attach(f, name)
      vim.cmd("edit " .. f)
      local c
      ok(vim.wait(20000, function()
        c = vim.lsp.get_clients({ bufnr = 0, name = name })[1]
        return c ~= nil
      end, 100), name .. " attaches to " .. f)
      return c
    end
    local function main()
      ok(package.loaded["schemastore"] == nil, "SchemaStore lazy at start")
      local j = attach("package.json", "jsonls")
      ok(package.loaded["schemastore"] ~= nil, "SchemaStore loaded by server start")
      ok(#j.config.settings.json.schemas > 100, "jsonls has SchemaStore schemas")
      ok(j.config.settings.json.validate.enable, "jsonls validate on")
      local y = attach(".github/workflows/ci.yaml", "yamlls")
      local n = 0
      for _ in pairs(y.config.settings.yaml.schemas) do n = n + 1 end
      ok(n > 100, "yamlls has SchemaStore schemas")
      ok(y.config.settings.yaml.schemaStore.enable == false, "yamlls built-in schemaStore off")
      attach("Cargo.toml", "taplo")
      io.stdout:write("DATA_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q DATA_OK
    touch $out
  ''
