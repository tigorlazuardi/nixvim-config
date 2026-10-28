# Inline diagnostics. virtual_text=false (LazyVim pairs this with LSP
# config) lives in plugins/lsp.nix (#14) via diagnostic.settings.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.tiny-inline-diagnostic = {
    enable = lib.mkDefault true;
    package = mkPlugin "tiny-inline-diagnostic.nvim" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [ "DeferredUIEnter" ];
    };
    settings = lib.mkDefault {
      options = {
        show_source = true;
        throttle = 0;
        multilines = {
          enabled = true;
          always_show = true;
        };
        multiple_diag_under_cursor = true;
        enable_on_insert = true;
      };
    };
  };
}
