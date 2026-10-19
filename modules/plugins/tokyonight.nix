# Pilot plugin: proves pin-per-plugin + lz.n colorscheme trigger.
{ lib, mkPlugin, ... }:
{
  programs.nixvim = {
    colorscheme = lib.mkDefault "tokyonight";
    colorschemes.tokyonight = {
      enable = lib.mkDefault true;
      package = mkPlugin "tokyonight.nvim" {
        nvimSkipModules = [ "tokyonight.docs" ];
      };
      # Trigger on startup via colorscheme; nixvim will emit the colorscheme name
      lazyLoad.enable = lib.mkDefault true;
      settings = lib.mkDefault {
        transparent = true;
        styles = {
          sidebars = "transparent";
          floats = "transparent";
        };
      };
    };
  };
}
