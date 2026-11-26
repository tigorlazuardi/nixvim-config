{ pkgs, nvim }:
pkgs.runCommand "nvim-snacks-behaviour"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    cd $HOME
    cat > probe.lua <<'LUA'
    vim.cmd("doautocmd User DeferredUIEnter")
    vim.wait(700, function() return false end)
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    ok(_G.Snacks and Snacks.picker and Snacks.lazygit and Snacks.terminal, "snacks modules")
    for _, k in ipairs({ "<leader>z", "<leader>e", "<leader>/", "<leader><space>", "<c-/>", "<leader>ug", "<leader>ut", "<leader>up", "<F3>" }) do
      ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
    end
    -- mini.files: lazy, loads on '-'
    ok(not package.loaded["mini.files"], "mini.files must start lazy")
    vim.cmd("normal -")
    vim.wait(300, function() return false end)
    ok(package.loaded["mini.files"] and vim.bo.filetype == "minifiles", "mini.files open via -")
    local cfg = require("mini.files").config
    ok(cfg.windows.preview == true, "preview on")
    ok(cfg.content.filter == nil or cfg.content.filter({ name = ".x", fs_type = "file" }) == true, "no filtering")
    -- dashboard header = static TIGOR banner (no fortune/cowsay subprocess)
    require("mini.files").close() -- floating explorer from the check above
    vim.cmd("only")
    Snacks.dashboard.open()
    vim.wait(800, function() return false end)
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    ok(text:find("Find File", 1, true), "dashboard keys still rendered")
    ok(text:find("████", 1, true), "static banner header")
    print("SNACKS_OK")
    LUA
    res=$("$nvim/bin/nvim" --headless -S probe.lua +qa 2>&1)
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -qx SNACKS_OK
    touch $out
  ''
