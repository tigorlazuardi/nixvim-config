# Rust: rust-analyzer LSP (LazyVim lang.rust settings: all features, build
# scripts + proc macros on, clippy on save), rustfmt via conform, toolchain on
# PATH (rust-analyzer shells out to cargo/rustc). Treesitter rust/ron grammars
# live in treesitter.nix. Cargo.toml is handled by taplo (data-formats.nix).
# ponytail: plain rust_analyzer, no rustaceanvim/crates.nvim; no rust-src, so
# go-to-definition into std is unavailable until a toolchain with rust-src is wanted.
{ lib, pkgs, ... }:
{
  programs.nixvim = {
    lsp.servers.rust_analyzer = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.rust-analyzer;
      config.settings."rust-analyzer" = {
        cargo = {
          allFeatures = true;
          loadOutDirsFromCheck = true;
          buildScripts.enable = true;
        };
        checkOnSave = true;
        check.command = "clippy";
        procMacro.enable = true;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft.rust = lib.mkDefault [ "rustfmt" ];

    # cargo/rustc: rust-analyzer needs them; clippy for check on save;
    # rustfmt for conform.
    extraPackages = [
      pkgs.cargo
      pkgs.rustc
      pkgs.clippy
      pkgs.rustfmt
    ];
  };
}
