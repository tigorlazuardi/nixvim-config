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
