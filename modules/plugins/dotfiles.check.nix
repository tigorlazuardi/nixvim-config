{ pkgs, nvim }:
pkgs.runCommand "nvim-dotfiles-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p/hypr $HOME/p/waybar $HOME/p/kitty $HOME/p/mako && cd $HOME/p
    git init -q
    printf 'x=1\n' > run.sh
    touch hypr/a.conf waybar/config kitty/k.conf mako/config t.rasi .env.local
    printf '.a { color: #ff0000; background: #0f0; }\n' > s.css
    printf '<div class="bg-red-500 text-blue-300">x</div>\n' > i.html
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function hl_groups()
      local groups = {}
      for name, ns in pairs(vim.api.nvim_get_namespaces()) do
        if name:lower():find("hipat") then
          for _, m in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
            groups[m[4].hl_group] = true
          end
        end
      end
      return groups
    end
    local function main()
      ok(package.loaded["mini.hipatterns"] == nil, "mini.hipatterns lazy at start")
      local fts = {
        ["hypr/a.conf"] = "hyprlang", ["waybar/config"] = "jsonc", ["kitty/k.conf"] = "kitty",
        ["mako/config"] = "dosini", ["t.rasi"] = "rasi", [".env.local"] = "sh",
      }
      for f, ft in pairs(fts) do
        vim.cmd("edit " .. f)
        ok(vim.bo.filetype == ft, f .. " filetype " .. ft .. " got " .. vim.bo.filetype)
      end
      vim.cmd("edit run.sh")
      ok(vim.wait(20000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "bashls" }) > 0 end, 100), "bashls attaches")
      ok(vim.fn.executable("shellcheck") == 1, "shellcheck on PATH")
      vim.cmd("edit s.css")
      ok(vim.wait(5000, function() return hl_groups()["MiniHipatterns_ff0000_bg"] end, 50), "hex color highlighted")
      ok(hl_groups()["MiniHipatterns_00ff00_bg"], "#rgb shorthand highlighted")
      vim.cmd("edit i.html")
      ok(vim.wait(5000, function() return hl_groups()["MiniHipatternsTailwindred500"] end, 50), "tailwind class highlighted")
      ok(hl_groups()["MiniHipatternsTailwindblue300"], "second tailwind class highlighted")
      io.stdout:write("DOT_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q DOT_OK
    touch $out
  ''
