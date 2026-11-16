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
    -- dashboard header = fortune|cowsay, computed once per start (not per render)
    require("mini.files").close() -- floating explorer from the check above
    vim.cmd("only")
    Snacks.dashboard.open()
    vim.wait(800, function() return false end)
    local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") end
    local first = text()
    ok(first:find("Find File", 1, true), "dashboard keys still rendered")
    ok(first:find("\\   ", 1, false) or first:find("\\\n", 1, true) or first:find("--", 1, true), "cowsay output in header")
    ok(not first:find("████", 1, true), "fortune header, not static banner")
    Snacks.dashboard.update()
    vim.wait(500, function() return false end)
    ok(text():gsub("%s+", "") == first:gsub("%s+", ""), "same quote on re-render")
    print("SNACKS_OK")
    LUA
    res=$("$nvim/bin/nvim" --headless -S probe.lua +qa 2>&1)
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -qx SNACKS_OK
    touch $out
  ''
