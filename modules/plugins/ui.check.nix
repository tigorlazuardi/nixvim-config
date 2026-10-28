{ pkgs, nvim }:
pkgs.runCommand "nvim-ui-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    printf 'package main\nfunc main(){}\n' > t.go
    cat > probe.lua <<'LUA'
    vim.cmd("doautocmd User DeferredUIEnter")
    vim.wait(700, function() return false end)
    vim.cmd("edit t.go")
    vim.wait(500, function() return false end)
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    ok(package.loaded["bufferline"], "bufferline")
    ok(package.loaded["lualine"], "lualine")
    ok(package.loaded["which-key"], "which-key")
    ok(package.loaded["noice"], "noice")
    ok(package.loaded["ibl"], "ibl")
    ok(package.loaded["tiny-inline-diagnostic"], "tiny")
    ok(vim.wo.statusline:find("lualine") ~= nil, "statusline")
    ok(vim.fn.maparg("<leader>bp", "n") ~= "", "map bp")
    ok(vim.fn.maparg("<leader>snl", "n") ~= "", "map snl")
    ok(vim.fn.exists(":TSContext") == 2, "TSContext")
    ok(_G.__nvim_hl_fg("NonText") == nil or _G.__nvim_hl_fg("NonText"):find("^#"), "hl fg")
    -- catppuccin stays lazy: switch must load it.
    vim.cmd("colorscheme catppuccin")
    vim.wait(500, function() return false end)
    ok(vim.g.colors_name and vim.g.colors_name:find("^catppuccin") ~= nil, "catppuccin lazy switch, got " .. tostring(vim.g.colors_name))
    print("UI_OK")
    LUA
    res=$("$nvim/bin/nvim" --headless -S probe.lua +qa 2>&1)
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -qx UI_OK
    touch $out
  ''
