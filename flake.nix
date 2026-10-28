{
  description = ''
    nixvim config as a Home Manager module.

    Single source of truth: this repo owns the editor config for every
    consumer; each consumer (host machine) may override any
    `programs.nixvim.*` value. See
    docs/adr/0001-nixvim-module-granular-plugin-inputs.md.
  '';

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Plugins (granular pinning, ADR-0001) ---
    # One input per plugin, `flake = false`. Input name == repo name == the
    # `pack/opt/<name>` folder lz.n loads. Update one: nix flake update <name>
    "tokyonight.nvim" = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };
    "nvim-treesitter-textobjects" = {
      url = "github:nvim-treesitter/nvim-treesitter-textobjects/main";
      flake = false;
    };
    "ts-comments.nvim" = {
      url = "github:folke/ts-comments.nvim";
      flake = false;
    };
    "mini.ai" = {
      url = "github:nvim-mini/mini.ai";
      flake = false;
    };
    "mini.pairs" = {
      url = "github:nvim-mini/mini.pairs";
      flake = false;
    };
    "flash.nvim" = {
      url = "github:folke/flash.nvim";
      flake = false;
    };
    "catppuccin" = {
      url = "github:catppuccin/nvim";
      flake = false;
    };
    "bufferline.nvim" = {
      url = "github:akinsho/bufferline.nvim";
      flake = false;
    };
    "lualine.nvim" = {
      url = "github:nvim-lualine/lualine.nvim";
      flake = false;
    };
    "which-key.nvim" = {
      url = "github:folke/which-key.nvim";
      flake = false;
    };
    "noice.nvim" = {
      url = "github:folke/noice.nvim";
      flake = false;
    };
    "nui.nvim" = {
      url = "github:MunifTanjim/nui.nvim";
      flake = false;
    };
    "mini.icons" = {
      url = "github:nvim-mini/mini.icons";
      flake = false;
    };
    "indent-blankline.nvim" = {
      url = "github:lukas-reineke/indent-blankline.nvim";
      flake = false;
    };
    "nvim-treesitter-context" = {
      url = "github:nvim-treesitter/nvim-treesitter-context";
      flake = false;
    };
    "tiny-inline-diagnostic.nvim" = {
      url = "github:rachartier/tiny-inline-diagnostic.nvim";
      flake = false;
    };
    "snacks.nvim" = {
      url = "github:folke/snacks.nvim";
      flake = false;
    };
    "mini.files" = {
      url = "github:nvim-mini/mini.files";
      flake = false;
    };
    "nvim-lspconfig" = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
    # Nix-only library (no plugins): splits Rust deps into their own
    # derivation so a plugin bump does not recompile every crate.
    crane.url = "github:ipetkov/crane";
    "goimpl.nvim" = {
      url = "github:edolphin-ydf/goimpl.nvim";
      flake = false;
    };
    "telescope.nvim" = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
    "plenary.nvim" = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
    "neotest" = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    "nvim-nio" = {
      url = "github:nvim-neotest/nvim-nio";
      flake = false;
    };
    "neotest-golang" = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };
    "lazydev.nvim" = {
      url = "github:folke/lazydev.nvim";
      flake = false;
    };
    "trouble.nvim" = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
    "todo-comments.nvim" = {
      url = "github:folke/todo-comments.nvim";
      flake = false;
    };
    "gitsigns.nvim" = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    "nvim-lint" = {
      url = "github:mfussenegger/nvim-lint";
      flake = false;
    };
    "conform.nvim" = {
      url = "github:stevearc/conform.nvim";
      flake = false;
    };
    "blink.cmp" = {
      url = "github:saghen/blink.cmp/v1"; # v2 (main) needs blink.lib; v1 = LazyVim/nixpkgs line
      flake = false;
    };
    "friendly-snippets" = {
      url = "github:rafamadriz/friendly-snippets";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      nixvim,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    in
    {
      homeManagerModules.default = import ./modules inputs;

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default =
            (home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                self.homeManagerModules.default
                {
                  home.username = "nixvim-check";
                  home.homeDirectory = "/tmp/nixvim-check";
                  home.stateVersion = "25.05";
                }
              ];
            }).config.programs.nixvim.build.package;
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Headless boot: init.lua must generate, evaluate, and exit clean
          # with zero startup output, and the lz.n lazy trigger must load
          # the pilot colorscheme.
          nvim-headless =
            pkgs.runCommand "nvim-headless-boot"
              {
                nvim = self.packages.${system}.default;
              }
              ''
                export HOME=$(mktemp -d)
                output=$("$nvim/bin/nvim" --headless "+qa" 2>&1)
                if [ -n "$output" ]; then
                  echo "nvim startup produced output:"
                  echo "$output"
                  exit 1
                fi
                # lz.n colorscheme trigger must actually load tokyonight.
                output=$("$nvim/bin/nvim" --headless \
                  -c "colorscheme tokyonight" \
                  -c "lua assert(vim.g.colors_name and vim.g.colors_name:find('^tokyonight'), 'not applied: '..tostring(vim.g.colors_name)); print('LAZY_TRIGGER_OK')" \
                  +qa 2>&1)
                printf '%s\n' "$output" | grep -q '^LAZY_TRIGGER_OK$' || {
                  echo "lz.n lazy trigger did not load tokyonight:"
                  printf '%s\n' "$output"
                  exit 1
                }
                if printf '%s\n' "$output" | grep -v '^LAZY_TRIGGER_OK$' | grep -q .; then
                  echo "lazy-trigger run produced unexpected output:"
                  printf '%s\n' "$output"
                  exit 1
                fi
                touch $out
              '';
          nvim-ui =
            pkgs.runCommand "nvim-ui-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-snacks =
            pkgs.runCommand "nvim-snacks-behaviour"
              {
                nvim = self.packages.${system}.default;
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
                print("SNACKS_OK")
                LUA
                res=$("$nvim/bin/nvim" --headless -S probe.lua +qa 2>&1)
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -qx SNACKS_OK
                touch $out
              '';
          nvim-lsp =
            pkgs.runCommand "nvim-lsp-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-cmp =
            pkgs.runCommand "nvim-cmp-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-conform =
            pkgs.runCommand "nvim-conform-behaviour"
              {
                nvim = self.packages.${system}.default;
              }
              ''
                export HOME=$(mktemp -d)
                cd $HOME
                cat > probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function write(name, text)
                  local f = io.open(name, "w"); f:write(text); f:close()
                end
                local function main()
                  vim.cmd("doautocmd User DeferredUIEnter")
                  ok(package.loaded["conform"] == nil, "conform must stay lazy at start")
                  for _, k in ipairs({ "<leader>cf", "<leader>cF", "<leader>uf", "<leader>uF" }) do
                    ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
                  end
                  write("a.nix", "{a=1;b=   [1 2   3];}\n")
                  vim.cmd("silent edit a.nix")
                  vim.cmd("silent write")
                  ok(package.loaded["conform"] ~= nil, "conform loaded by save")
                  ok(table.concat(vim.fn.readfile("a.nix"), "\n"):find("  a = 1;", 1, true), "nixfmt ran on save")
                  vim.g.autoformat = false
                  write("b.nix", "{a=1;}\n")
                  vim.cmd("silent edit b.nix")
                  vim.cmd("silent write")
                  ok(vim.fn.readfile("b.nix")[1] == "{a=1;}", "global toggle off skips format")
                  vim.g.autoformat = nil
                  vim.b.autoformat = false
                  vim.cmd("silent write")
                  ok(vim.fn.readfile("b.nix")[1] == "{a=1;}", "buffer toggle off skips format")
                  vim.b.autoformat = true
                  vim.g.autoformat = false
                  vim.cmd("silent write")
                  ok(vim.fn.readfile("b.nix")[1] ~= "{a=1;}", "buffer on overrides global off")
                  io.stdout:write("CONFORM_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 60 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q CONFORM_OK
                touch $out
              '';
          nvim-lint =
            pkgs.runCommand "nvim-lint-behaviour"
              {
                nvim = self.packages.${system}.default;
              }
              ''
                export HOME=$(mktemp -d)
                cd $HOME
                printf 'let x = 1; in { a = if true then 1 else 2; }\n' > a.nix
                printf '#!/bin/sh\necho $foo\n' > a.sh
                printf 'FROM ubuntu\nRUN apt-get install x\n' > Dockerfile
                printf '# T\n\n\n\ntext\n' > a.md
                printf 'package main\nfunc main(){}\n' > a.go
                cat > probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function main()
                  ok(package.loaded["lint"] == nil, "nvim-lint must stay lazy at start")
                  vim.cmd("silent edit a.nix")
                  ok(vim.wait(3000, function() return package.loaded["lint"] ~= nil end, 50), "loaded by first buffer")
                  local by = require("lint").linters_by_ft
                  ok(by.nix[1] == "statix" and by.sh[1] == "shellcheck", "nix/sh mapping")
                  ok(by.markdown[1] == "markdownlint-cli2" and by.dockerfile[1] == "hadolint", "md/docker mapping")
                  ok(type(by.go) == "table" and #by.go == 0, "go linters empty")
                  local function has(file, why)
                    vim.cmd("silent edit! " .. file)
                    ok(vim.wait(20000, function() return #vim.diagnostic.get(0) > 0 end, 100), why)
                  end
                  has("a.nix", "statix diagnostics on .nix open")
                  has("a.sh", "shellcheck diagnostics on .sh open")
                  has("Dockerfile", "hadolint diagnostics on Dockerfile open")
                  has("a.md", "markdownlint diagnostics on .md open")
                  vim.cmd("silent edit! a.go")
                  vim.wait(1500, function() return false end, 100)
                  ok(#vim.diagnostic.get(0) == 0, "no linter diagnostics for go")
                  io.stdout:write("LINT_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 120 "$nvim/bin/nvim" --headless -S probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q LINT_OK
                touch $out
              '';
          nvim-typescript =
            pkgs.runCommand "nvim-typescript-behaviour"
              {
                nvim = self.packages.${system}.default;
                nativeBuildInputs = [ pkgs.git ];
              }
              ''
                export HOME=$(mktemp -d)
                mkdir -p $HOME/proj/src && cd $HOME/proj
                git init -q
                echo '{"name":"x"}' > package.json
                touch package-lock.json
                echo '{"formatter":{"indentStyle":"space","indentWidth":2}}' > biome.json
                echo '{"compilerOptions":{"strict":true}}' > tsconfig.json
                printf 'const x:number="a"\nfunction  f( a ){return    a}\n' > src/a.ts
                cat > $HOME/probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function main()
                  vim.cmd("edit src/a.ts")
                  ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0 }) >= 2 end, 100), "tsc + biome attach")
                  local names = {}
                  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do names[c.name] = true end
                  ok(names.tsc and names.biome, "clients tsc and biome")
                  ok(not names.vtsls and not names.tsgo and not names.ts_ls, "vtsls/tsgo/ts_ls not active")
                  ok(vim.wait(20000, function() return #vim.diagnostic.get(0) > 0 end, 100), "tsc type diagnostics")
                  ok(vim.bo.tabstop == 4 and vim.bo.shiftwidth == 4 and vim.bo.expandtab, "tabstop 4")
                  vim.cmd("silent write")
                  local text = table.concat(vim.fn.readfile("src/a.ts"), "\n")
                  ok(text:find('const x: number = "a";', 1, true) and text:find("  return a;", 1, true), "biome formatted on save")
                  io.stdout:write("TS_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 120 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q TS_OK
                touch $out
              '';
          nvim-go =
            pkgs.runCommand "nvim-go-behaviour"
              {
                nvim = self.packages.${system}.default;
                nativeBuildInputs = [ pkgs.git ];
              }
              ''
                export HOME=$(mktemp -d)
                mkdir -p $HOME/p && cd $HOME/p
                git init -q
                printf 'module example.com/x\n\ngo 1.22\n' > go.mod
                printf 'package main\n\ntype S interface{ A() }\n\nfunc main() {\n\tvar x int = 1\n\t_ = x\n}\n' > main.go
                cat > $HOME/probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function main()
                  ok(package.loaded["telescope"] == nil and vim.fn.exists(":GoImpl") == 0, "goimpl/telescope lazy at start")
                  vim.cmd("edit main.go")
                  ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "gopls" }) > 0 end, 100), "gopls attach")
                  local g = vim.lsp.get_clients({ bufnr = 0, name = "gopls" })[1].config.settings.gopls
                  ok(g.usePlaceholders == false, "usePlaceholders off")
                  for k, v in pairs(g.hints) do ok(v == false, "hint off " .. k) end
                  ok(g.analyses.shadow == false and g.analyses.ST1000 == false and g.analyses.ST1023 == false, "shadow/ST1xxx off")
                  ok(g.analyses.nilness == true, "LazyVim analyses kept")
                  ok(vim.fn.exists(":GoImpl") == 2, "GoImpl command")
                  ok(vim.fn.maparg("<leader>im", "n") ~= "", "<leader>im map")
                  ok(type(require("telescope").extensions.goimpl.goimpl) == "function", "telescope goimpl extension")
                  for _, b in ipairs({ "dlv", "impl", "gopls", "goimports", "gofumpt" }) do ok(vim.fn.executable(b) == 1, "binary " .. b) end
                  ok(#require("lint").linters_by_ft.go == 0, "golangci-lint off")
                  io.stdout:write("GO_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 120 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q GO_OK
                touch $out
              '';
          nvim-neotest =
            pkgs.runCommand "nvim-neotest-behaviour"
              {
                nvim = self.packages.${system}.default;
                # neotest-golang runs `go test -race`, which needs a C compiler.
                nativeBuildInputs = [
                  pkgs.git
                  pkgs.gcc
                ];
              }
              ''
                export HOME=$(mktemp -d)
                mkdir -p $HOME/p && cd $HOME/p
                git init -q
                printf 'module example.com/x\n\ngo 1.22\n' > go.mod
                printf 'package x\n\nfunc Add(a, b int) int { return a + b }\n' > x.go
                printf 'package x\n\nimport "testing"\n\nfunc TestAdd(t *testing.T) {\n\tif Add(1, 2) != 3 {\n\t\tt.Fatal("bad")\n\t}\n}\n' > x_test.go
                cat > $HOME/probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function main()
                  ok(package.loaded["neotest"] == nil, "neotest lazy at start")
                  for _, k in ipairs({ "tt", "tT", "tr", "tl", "ts", "to", "tO", "tS", "tw", "ta" }) do
                    ok(vim.fn.maparg("<leader>" .. k, "n") ~= "", "map <leader>" .. k)
                  end
                  vim.cmd("edit x_test.go")
                  require("lz.n").trigger_load("neotest")
                  local nt = require("neotest")
                  local names = {}
                  for _, a in ipairs(require("neotest.config").adapters or {}) do names[#names + 1] = a.name end
                  ok(vim.tbl_contains(names, "neotest-golang"), "golang adapter loaded")
                  local started
                  require("nio").run(function() nt.run.run(vim.fn.expand("%")); started = true end)
                  ok(vim.wait(20000, function() return started end, 100), "run started")
                  ok(vim.wait(90000, function()
                    local ids = nt.state.adapter_ids()
                    if not ids or #ids == 0 then return false end
                    local c = nt.state.status_counts(ids[1])
                    return c and c.passed and c.passed > 0
                  end, 500), "go test passed via neotest")
                  io.stdout:write("NEOTEST_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q NEOTEST_OK
                touch $out
              '';
          nvim-web =
            pkgs.runCommand "nvim-web-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-lazydev =
            pkgs.runCommand "nvim-lazydev-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-trouble =
            pkgs.runCommand "nvim-trouble-behaviour"
              {
                nvim = self.packages.${system}.default;
                nativeBuildInputs = [ pkgs.git ];
              }
              ''
                export HOME=$(mktemp -d)
                mkdir -p $HOME/p && cd $HOME/p
                git init -q
                printf '# TODO: first\nx = 1\n# FIXME: second\n# NOTE: third\n' > a.py
                cat > $HOME/probe.lua <<'LUA'
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                local function main()
                  ok(package.loaded["trouble"] == nil and package.loaded["todo-comments"] == nil, "both lazy at start")
                  for _, k in ipairs({ "<leader>xx", "<leader>xX", "<leader>cs", "<leader>cS", "<leader>xL", "<leader>xQ", "[q", "]q", "<leader>xt", "<leader>xT", "]t", "[t", "<leader>st", "<leader>sT" }) do
                    ok(vim.fn.maparg(k, "n") ~= "", "map " .. k)
                  end
                  vim.cmd("Trouble diagnostics toggle")
                  ok(package.loaded["trouble"] ~= nil, ":Trouble loads trouble")
                  vim.cmd("only | edit a.py")
                  ok(package.loaded["todo-comments"] ~= nil, "todo-comments loads on buffer read")
                  ok(vim.wait(5000, function() return Snacks.picker.sources.todo_comments ~= nil end, 50), "snacks todo_comments source registered")
                  vim.cmd("TodoQuickFix")
                  ok(vim.wait(5000, function() return #vim.fn.getqflist() >= 3 end, 100), "TodoQuickFix finds TODO/FIXME/NOTE")
                  ok(pcall(require, "trouble.sources.profiler"), "snacks profiler trouble source")
                  ok(pcall(require, "trouble.sources.todo"), "todo trouble source")
                  io.stdout:write("TROUBLE_OK\n")
                end
                local good, err = xpcall(main, debug.traceback)
                if not good then io.stdout:write(tostring(err) .. "\n") end
                vim.cmd(good and "qa!" or "cquit")
                LUA
                res=$(timeout 100 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q TROUBLE_OK
                touch $out
              '';
          nvim-gitsigns =
            pkgs.runCommand "nvim-gitsigns-behaviour"
              {
                nvim = self.packages.${system}.default;
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
              '';
          nvim-treesitter =
            pkgs.runCommand "nvim-treesitter-behaviour"
              {
                nvim = self.packages.${system}.default;
              }
              ''
                export HOME=$(mktemp -d)
                cd $HOME
                printf 'package main\nfunc main() {}\n' > t.go
                cat > t.lua <<'LUA'
                vim.cmd("edit t.go")
                vim.cmd("doautocmd User DeferredUIEnter")
                vim.wait(500, function() return false end)
                vim.cmd("edit! t.go")
                local function ok(c, m) if not c then error("FAIL: " .. m) end end
                ok(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "ts highlight")
                ok(vim.wo.foldmethod == "expr", "foldmethod")
                ok(vim.o.foldlevelstart == 99, "foldlevelstart")
                ok(vim.fn.maparg("s", "n") ~= "", "flash s")
                ok(vim.fn.maparg("]f", "n") ~= "", "textobjects ]f")
                ok(package.loaded["mini.ai"], "mini.ai")
                ok(package.loaded["ts-comments"], "ts-comments")
                print("TS_OK")
                LUA
                res=$("$nvim/bin/nvim" --headless -S t.lua +qa 2>&1)
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -qx TS_OK
                touch $out
              '';
        }
      );
    };
}
