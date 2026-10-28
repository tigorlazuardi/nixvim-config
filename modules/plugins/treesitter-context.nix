# Floating function/class context. <leader>ut toggle via Snacks — #12.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.treesitter-context = {
    enable = lib.mkDefault true;
    package = mkPlugin "nvim-treesitter-context" {
      nvimSkipModules = [ "context.highlight" ];
    };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [
        "BufReadPost"
        "BufNewFile"
      ];
    };
    settings = lib.mkDefault {
      mode = "cursor";
      max_lines = 3;
    };
  };
}
