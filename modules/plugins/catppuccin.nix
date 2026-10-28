# Second colorscheme, lazy — only loads on `:colorscheme catppuccin`.
# Undercurl diagnostics + integrations ported from LazyVim.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.colorschemes.catppuccin = {
    enable = lib.mkDefault true;
    package = mkPlugin "catppuccin" {
        nvimSkipModules = [
          "catppuccin.groups.integrations.noice"
          "catppuccin.palettes.latte"
          "catppuccin.palettes.frappe"
          "catppuccin.palettes.macchiato"
          "catppuccin.palettes.mocha"
          "catppuccin.special.bufferline"
          "catppuccin.special.feline"
        ];
      };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.colorscheme = "catppuccin";
    };
    settings = lib.mkDefault {
      integrations = {
        flash = true;
        gitsigns = true;
        indent_blankline.enabled = true;
        lsp_trouble = true;
        mini = true;
        native_lsp = {
          enabled = true;
          underlines = {
            errors = [ "undercurl" ];
            hints = [ "undercurl" ];
            warnings = [ "undercurl" ];
            information = [ "undercurl" ];
          };
        };
        neotest = true;
        noice = true;
        notify = true;
        treesitter_context = true;
        which_key = true;
      };
    };
  };
}
