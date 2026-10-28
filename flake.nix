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
    "persistence.nvim" = {
      url = "github:folke/persistence.nvim";
      flake = false;
    };
    "nvim-sops" = {
      url = "github:prismatic-koi/nvim-sops";
      flake = false;
    };
    "grug-far.nvim" = {
      url = "github:MagicDuck/grug-far.nvim";
      flake = false;
    };
    "dial.nvim" = {
      url = "github:monaqa/dial.nvim";
      flake = false;
    };
    "inc-rename.nvim" = {
      url = "github:smjonas/inc-rename.nvim";
      flake = false;
    };
    "yanky.nvim" = {
      url = "github:gbprod/yanky.nvim";
      flake = false;
    };
    "SchemaStore.nvim" = {
      url = "github:b0o/SchemaStore.nvim";
      flake = false;
    };
    "render-markdown.nvim" = {
      url = "github:MeanderingProgrammer/render-markdown.nvim";
      flake = false;
    };
    "mini.hipatterns" = {
      url = "github:nvim-mini/mini.hipatterns";
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
          nvim = self.packages.${system}.default;
          # Behaviour checks live next to the module they test:
          # modules/**/<name>.check.nix -> checks.<system>.nvim-<name>
          # (shape: { pkgs, nvim }: pkgs.runCommand ...).
          files = builtins.filter (nixpkgs.lib.hasSuffix ".check.nix") (
            map toString (nixpkgs.lib.filesystem.listFilesRecursive ./modules)
          );
        in
        builtins.listToAttrs (
          map (f: {
            name =
              let
                n = nixpkgs.lib.removeSuffix ".check.nix" (baseNameOf f);
              in
              if nixpkgs.lib.hasPrefix "nvim-" n then n else "nvim-" + n;
            value = import f { inherit pkgs nvim; };
          }) files
        )
      );
    };
}
