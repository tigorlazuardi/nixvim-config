{ pkgs, nvim }:
pkgs.runCommand "nvim-lsp-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    printf '{ a = 1; }\n' > t.nix
    printf 'FOO=1\n' > .env.local
    printf '# x\n' > r.md
    printf 'FROM scratch\n' > Dockerfile
    cat > probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
    vim.cmd("doautocmd User DeferredUIEnter")
    vim.cmd("edit t.nix")
    ok(vim.wait(8000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "nil_ls" }) > 0 end, 100), "nil_ls attach")
    ok(vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), "inlay hints on")
    ok(vim.diagnostic.config().virtual_text == false, "virtual_text off")
    for _, k in ipairs({ "]]", "[[", "gd", "K", "<leader>ca", "<leader>cr", "<leader>cR", "<leader>uh" }) do
      ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
    end
    -- ]] prefers ERROR over a nearer WARN.
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "a", "b", "c", "d" })
    local ns = vim.api.nvim_create_namespace("probe")
    vim.diagnostic.set(ns, 0, {
      { lnum = 1, col = 0, message = "w", severity = vim.diagnostic.severity.WARN },
      { lnum = 3, col = 0, message = "e", severity = vim.diagnostic.severity.ERROR },
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal ]]")
    ok(vim.api.nvim_win_get_cursor(0)[1] == 4, "]] jumps to error first")
    vim.cmd("normal [[")
    ok(vim.api.nvim_win_get_cursor(0)[1] == 4 or vim.api.nvim_win_get_cursor(0)[1] == 2, "[[ moves")
    vim.cmd("silent! edit! .env.local")
    ok(not vim.diagnostic.is_enabled({ bufnr = 0 }), "diag off .env")
    vim.cmd("silent! edit! r.md")
    ok(not vim.diagnostic.is_enabled({ bufnr = 0 }), "diag off markdown")
    vim.cmd("silent! edit! Dockerfile")
    ok(not vim.diagnostic.is_enabled({ bufnr = 0 }), "diag off dockerfile")
    io.stdout:write("LSP_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 60 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q LSP_OK
    touch $out
  ''
