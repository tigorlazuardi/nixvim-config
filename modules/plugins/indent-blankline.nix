# Indent guides. <leader>ug toggle uses Snacks — deferred to #12.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.indent-blankline = {
    enable = lib.mkDefault true;
    package = mkPlugin "indent-blankline.nvim" {
      nvimSkipModules = [
        "ibl.config.types"
        "ibl.hooks.types"
        "ibl.config"
        "ibl.hooks"
        "ibl.utils"
      ];
    };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [
        "BufReadPost"
        "BufNewFile"
      ];
    };
    settings = lib.mkDefault {
      indent = {
        char = "│";
        tab_char = "│";
      };
      scope = {
        show_start = false;
        show_end = false;
      };
      exclude.filetypes = [
        "Trouble"
        "alpha"
        "dashboard"
        "help"
        "lazy"
        "mason"
        "neo-tree"
        "notify"
        "snacks_dashboard"
        "snacks_notif"
        "snacks_terminal"
        "snacks_win"
        "toggleterm"
        "trouble"
      ];
    };
  };
}
