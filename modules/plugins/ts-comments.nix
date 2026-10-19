{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.ts-comments = {
    enable = lib.mkDefault true;
    package = mkPlugin "ts-comments.nvim" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [ "DeferredUIEnter" ];
    };
  };
}
