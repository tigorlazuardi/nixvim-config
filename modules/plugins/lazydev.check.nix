{ pkgs, nvim }:
pkgs.runCommand "nvim-lazydev-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    echo '{ }' > a.nix
    printf 'local x = vim.api.nvim_get_current_buf()\nlocal z = undefined_global_xyz\nprint(x, z)\n' > m.lua
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["lazydev"] == nil, "lazydev lazy at start")
      vim.cmd("edit a.nix")
      ok(package.loaded["lazydev"] == nil, "lazydev not loaded for nix")
      vim.cmd("edit m.lua")
      ok(package.loaded["lazydev"] ~= nil, "lazydev loaded for lua")
      ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "lua_ls" }) > 0 end, 100), "lua_ls attach")
      ok(vim.wait(10000, function()
        local w = require("lazydev.workspace").find({ buf = 0 })
        return w and w.settings and w.settings.Lua ~= nil
      end, 100), "lazydev workspace settings")
      local w = require("lazydev.workspace").find({ buf = 0 })
      local rt = false
      for _, l in ipairs(vim.tbl_get(w.settings, "Lua", "workspace", "library") or {}) do
        if l:find("share/nvim/runtime", 1, true) then rt = true end
      end
      ok(rt, "neovim runtime in workspace library")
      ok(vim.wait(30000, function() return #vim.diagnostic.get(0) > 0 end, 200), "lua_ls diagnostics")
      for _, d in ipairs(vim.diagnostic.get(0)) do
        ok(not d.message:find("`vim`", 1, true), "vim must be a known global")
      end
      vim.api.nvim_exec_autocmds("InsertEnter", {})
      ok(vim.wait(5000, function()
        local c = package.loaded["blink.cmp.config"]
        return c and c.sources and c.sources.providers and c.sources.providers.lazydev
      end, 100), "blink config loaded")
      local c = require("blink.cmp.config")
      ok(c.sources.per_filetype.lua[1] == "lazydev", "lazydev first blink source for lua")
      io.stdout:write("LAZYDEV_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q LAZYDEV_OK
    touch $out
  ''
