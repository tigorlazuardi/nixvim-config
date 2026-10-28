# UI component library — dependency of noice.nvim, must be on rtp (start)
# before noice loads. nixvim's nui module has no setup() to call.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.nui = {
    enable = lib.mkDefault true;
    package = mkPlugin "nui.nvim" { };
    lazyLoad.enable = lib.mkDefault false;
  };
}
