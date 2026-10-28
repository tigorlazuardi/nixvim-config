{ pkgs, nvim }:
pkgs.runCommand "nvim-web-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p/src && cd $HOME/p
    git init -q
    echo '{"name":"x"}' > package.json
    touch package-lock.json
    echo '{}' > biome.json
    echo '{"compilerOptions":{"strict":true}}' > tsconfig.json
    printf 'import { b } from "./b"\nimport { a } from "./a"\nexport const c = a + b\n' > src/m.ts
    echo 'export const a = 1' > src/a.ts
    echo 'export const b = 2' > src/b.ts
    printf '<div class="flex p-4">x</div>\n' > src/i.html
    printf '<script>let n = 1</script>\n<p>{n}</p>\n' > src/c.svelte
    printf -- '---\nconst x = 1\n---\n<h1>{x}</h1>\n' > src/p.astro
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function has(name)
      for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do if c.name == name then return true end end
      return false
    end
    local function attach(file, name)
      vim.cmd("edit " .. file)
      ok(vim.wait(30000, function() return has(name) end, 100), name .. " attach on " .. file)
    end
    local function main()
      attach("src/i.html", "tailwindcss")
      attach("src/c.svelte", "svelte")
      attach("src/c.svelte", "tailwindcss")
      attach("src/p.astro", "astro")
      attach("src/p.astro", "tailwindcss")
      ok(not vim.tbl_contains(vim.lsp.config.tailwindcss.filetypes, "markdown"), "tailwind excludes markdown")
      ok(vim.fn.maparg("<leader>co", "n") ~= "", "<leader>co mapped")
      vim.cmd("edit src/m.ts")
      ok(vim.wait(30000, function() return has("tsc") end, 100), "tsc attach for organize imports")
      vim.wait(3000)
      vim.lsp.buf.code_action({
        apply = true,
        filter = function(a) return a.title:find("Organize") ~= nil end,
        context = { only = { "source.organizeImports" }, diagnostics = {} },
      })
      ok(vim.wait(10000, function() return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]:find('"./a"', 1, true) ~= nil end, 100), "imports organized")
      require("lz.n").trigger_load("conform.nvim")
      local f = require("conform").formatters_by_ft
      ok(vim.deep_equal(f.svelte, { "prettier" }) and vim.deep_equal(f.astro, { "prettier" }), "prettier for svelte/astro")
      io.stdout:write("WEB_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q WEB_OK
    touch $out
  ''
