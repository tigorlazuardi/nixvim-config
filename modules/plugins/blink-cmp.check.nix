{ pkgs, nvim }:
pkgs.runCommand "nvim-cmp-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    printf 'builtins.' > t.nix
    printf 'for' > t.lua
    cat > probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
    local function shown(opts)
      local b = require("blink.cmp")
      vim.api.nvim_feedkeys("A", "nx", false)
      b.show(opts)
      local v = vim.wait(10000, function() return b.is_visible() end, 100)
      local items = v and require("blink.cmp.completion.list").items or {}
      b.hide()
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
      return v, items
    end
    vim.cmd("doautocmd User DeferredUIEnter")
    -- packadd runs blink's plugin/ file (requires the main module for
    -- LSP capabilities); setup itself must wait for InsertEnter.
    ok(package.loaded["blink.cmp.completion.list"] == nil, "blink setup must stay lazy before InsertEnter")
    vim.cmd("edit t.nix")
    ok(vim.wait(8000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "nil_ls" }) > 0 end, 100), "nil_ls attach")
    ok(vim.lsp.get_clients({ bufnr = 0 })[1].config.capabilities.textDocument.completion.completionItem.snippetSupport, "snippet capability reached nil_ls")
    -- nil_ls can answer slowly when checks run in parallel: retry.
    local v, items
    for _ = 1, 3 do
      v, items = shown()
      if v and #items > 0 then break end
    end
    ok(v and #items > 0 and items[1].source_id == "lsp", "LSP completion in .nix")
    ok(package.loaded["blink.cmp.completion.list"] ~= nil, "blink setup ran on InsertEnter")
    ok(vim.wait(8000, function() return require("blink.cmp.fuzzy").implementation_type == "rust" end, 100), "rust fuzzy lib in use")
    vim.cmd("edit! t.lua")
    local v2, items2 = shown({ providers = { "snippets" } })
    ok(v2 and #items2 > 0, "friendly-snippets items in lua")
    io.stdout:write("CMP_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 90 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q CMP_OK
    touch $out
  ''
