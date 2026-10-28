{ pkgs, nvim }:
pkgs.runCommand "nvim-gitsigns-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    git config user.email a@b
    git config user.name t
    printf 'one\ntwo\nthree\nfour\nfive\n' > f.txt
    git add f.txt
    git commit -qm init
    printf 'one\nTWO\nthree\nfour\nfive\nsix\n' > f.txt
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["gitsigns"] == nil, "gitsigns lazy at start")
      vim.cmd("edit f.txt")
      ok(package.loaded["gitsigns"] ~= nil, "gitsigns loads on buffer read")
      ok(vim.wait(10000, function()
        local d = vim.b.gitsigns_status_dict
        return d and d.added ~= nil
      end, 100), "gitsigns attached")
      local d = vim.b.gitsigns_status_dict
      ok(d.added == 1 and d.changed == 1, "hunk counts for changed file")
      local n = 0
      vim.wait(3000, function()
        n = 0
        for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
          if m[4].sign_text and m[4].sign_text:find("▎", 1, true) then n = n + 1 end
        end
        return n >= 2
      end, 100)
      ok(n >= 2, "gutter signs (▎) shown")
      for _, k in ipairs({ "]h", "[h", "]H", "[H", "<leader>ghs", "<leader>ghr", "<leader>ghS", "<leader>ghu", "<leader>ghR", "<leader>ghp", "<leader>ghb", "<leader>ghB", "<leader>ghd", "<leader>ghD" }) do
        ok(vim.fn.maparg(k, "n", false, true).buffer == 1, "buffer map " .. k)
      end
      ok(vim.fn.maparg("ih", "o") ~= "" and vim.fn.maparg("ih", "x") ~= "", "ih text object")
      vim.cmd("normal! gg")
      vim.cmd("normal ]h")
      ok(vim.wait(5000, function() return vim.fn.line(".") == 2 end, 50), "]h jumps to first hunk")
      vim.cmd("normal dih")
      ok(vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "three", "dih deletes the hunk")
      io.stdout:write("GITSIGNS_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 100 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q GITSIGNS_OK
    touch $out
  ''
