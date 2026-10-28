# Completion (#32): blink.cmp. Lazy on InsertEnter/CmdlineEnter.
# The Rust fuzzy lib is built (crane) from the same flake input: one
# `--update-input blink.cmp` advances plugin and lib together (ADR-0001).
# Settings mirror LazyVim's blink spec; cmp-git is dropped (needs nvim-cmp).
{
  lib,
  pkgs,
  craneLib,
  mkPlugin,
  ...
}:
let
  # `src` is the flake input, shared with the Lua plugin below.
  src = (mkPlugin "blink.cmp" { }).src;
  # Two layers: deps (rebuilt only when Cargo.lock changes) and the crate.
  # Cargo.lock is registry-only, so no output hashes to maintain.
  crateArgs = {
    pname = "blink-fuzzy-lib";
    version = src.shortRev or "dirty";
    inherit src;
    strictDeps = true;
    # build.rs shells out to `git rev-parse HEAD`.
    nativeBuildInputs = [ pkgs.gitMinimal ];
    doCheck = false;
    # The crate still uses nightly-only features.
    env.RUSTC_BOOTSTRAP = true;
    # Undefined symbols resolve against Neovim's LuaJIT at runtime.
    env.RUSTFLAGS = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin "-C link-arg=-undefined -C link-arg=dynamic_lookup";
  };
  fuzzy = craneLib.buildPackage (
    crateArgs
    // {
      # Constant version: the deps derivation name must not change per rev.
      cargoArtifacts = craneLib.buildDepsOnly (crateArgs // { version = "deps"; });
    }
  );
  ext = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
in
{
  programs.nixvim = {
    plugins.blink-cmp = {
      enable = lib.mkDefault true;
      package = mkPlugin "blink.cmp" {
        nvimSkipModules = [ "repro" ];
        preInstall = ''
          mkdir -p target/release
          ln -s ${fuzzy}/lib/libblink_cmp_fuzzy${ext} target/release/libblink_cmp_fuzzy${ext}
        '';
      };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.event = lib.mkDefault [
          "InsertEnter"
          "CmdlineEnter"
        ];
      };
      settings = {
        keymap.preset = lib.mkDefault "default";
        appearance.nerd_font_variant = lib.mkDefault "mono";
        completion = {
          accept.auto_brackets.enabled = lib.mkDefault true;
          menu.draw.treesitter = lib.mkDefault [ "lsp" ];
          documentation = {
            auto_show = lib.mkDefault true;
            auto_show_delay_ms = lib.mkDefault 200;
          };
          ghost_text.enabled = lib.mkDefault true;
        };
        sources.default = lib.mkDefault [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];
        cmdline = {
          enabled = lib.mkDefault true;
          keymap = {
            preset = lib.mkDefault "cmdline";
            "<Right>" = lib.mkDefault false;
            "<Left>" = lib.mkDefault false;
          };
          completion = {
            list.selection.preselect = lib.mkDefault false;
            menu.auto_show = lib.mkDefault {
              __raw = ''function() return vim.fn.getcmdtype() == ":" end'';
            };
            ghost_text.enabled = lib.mkDefault true;
          };
        };
      };
      # Servers start (BufReadPost) before the first InsertEnter, but
      # capabilities are sent at initialize. packadd runs blink's
      # plugin/ file, which merges completion capabilities into
      # vim.lsp.config("*") without running setup (setup stays lazy).
    };
    extraConfigLuaPost = ''
      vim.cmd.packadd("blink.cmp")
    '';
  };
}
