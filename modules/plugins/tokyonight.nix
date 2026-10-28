# Pilot plugin: proves pin-per-plugin + lz.n colorscheme trigger.
{ lib, mkPlugin, ... }:
{
  programs.nixvim = {
    # mkForce: two colorscheme modules are enabled (catppuccin is the lazy
    # alternative), so the plain priorities of both nixvim colorscheme
    # modules collide. Consumers switch the DEFAULT colorscheme with
    # lib.mkForce too; runtime switch: :colorscheme catppuccin.
    colorscheme = lib.mkForce "tokyonight";
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
