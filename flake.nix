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
                res=$(timeout 60 "$nvim/bin/nvim" --headless -S probe.lua 2>&1)
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
                local v, items = shown()
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
                res=$(timeout 90 "$nvim/bin/nvim" --headless -S probe.lua 2>&1)
                printf '%s\n' "$res"
                printf '%s\n' "$res" | grep -q CMP_OK
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
