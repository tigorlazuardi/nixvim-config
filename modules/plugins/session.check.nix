{ pkgs, nvim }:
pkgs.runCommand "nvim-session-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [
      pkgs.git
      pkgs.age
    ];
  }
  ''
    export HOME=$(mktemp -d)
    export XDG_STATE_HOME=$HOME/state
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf 'alpha\n' > a.txt
    printf 'beta\n' > b.txt
    age-keygen -o $HOME/key.txt 2> $HOME/pub
    PUB=$(sed 's/Public key: //' $HOME/pub)
    printf 'creation_rules:\n  - age: %s\n' "$PUB" > .sops.yaml
    printf 'secret: hunter2\n' > s.yaml
    export SOPS_AGE_KEY_FILE=$HOME/key.txt

    cat > $HOME/p1.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["persistence"] == nil, "persistence lazy at start")
      vim.cmd("edit a.txt")
      vim.cmd("split b.txt")
      ok(package.loaded["persistence"] ~= nil and require("persistence").active(), "persistence recording after BufReadPre")
      io.stdout:write("SAVE_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res1=$(timeout 60 "$nvim/bin/nvim" --headless -S $HOME/p1.lua 2>&1) || true
    printf '%s\n' "$res1"
    printf '%s\n' "$res1" | grep -q SAVE_OK

    cat > $HOME/p2.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(vim.fn.maparg("<leader>qs", "n") ~= "" and vim.fn.maparg("<leader>qS", "n") ~= "" and vim.fn.maparg("<leader>ql", "n") ~= "" and vim.fn.maparg("<leader>qd", "n") ~= "", "session keys")
      vim.api.nvim_feedkeys(vim.keycode("<leader>qs"), "x", false)
      ok(vim.wait(5000, function() return #vim.api.nvim_list_wins() == 2 end, 50), "session restored 2 windows")
      local names = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        names[vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t")] = true
      end
      ok(names["a.txt"] and names["b.txt"], "session restored buffers")
      io.stdout:write("RESTORE_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res2=$(timeout 60 "$nvim/bin/nvim" --headless -S $HOME/p2.lua 2>&1) || true
    printf '%s\n' "$res2"
    printf '%s\n' "$res2" | grep -q RESTORE_OK

    cat > $HOME/p3.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      ok(package.loaded["nvim_sops"] == nil, "nvim-sops lazy at start")
      ok(vim.fn.exists(":SopsEncrypt") == 2 and vim.fn.exists(":SopsDecrypt") == 2, "sops commands exist")
      ok(vim.fn.executable("sops") == 1, "sops binary on PATH")
      vim.cmd("edit s.yaml")
      vim.cmd("SopsEncrypt")
      ok(vim.wait(10000, function()
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("ENC%[") ~= nil
      end, 100), "file encrypted in place")
      ok(package.loaded["nvim_sops"] ~= nil, "nvim-sops loaded by command")
      vim.cmd("SopsDecrypt")
      ok(vim.wait(10000, function()
        return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("secret: hunter2", 1, true) ~= nil
      end, 100), "file decrypted back")
      io.stdout:write("SOPS_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res3=$(timeout 60 "$nvim/bin/nvim" --headless -S $HOME/p3.lua 2>&1) || true
    printf '%s\n' "$res3"
    printf '%s\n' "$res3" | grep -q SOPS_OK
    touch $out
  ''
