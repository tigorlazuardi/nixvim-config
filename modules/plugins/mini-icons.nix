# Icon provider. Eager (start) because the nvim-web-devicons shim must be
# preloaded before any other plugin asks for icons. Custom glyphs ported
# from LazyVim's mini.icons opts.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.mini-icons = {
    enable = lib.mkDefault true;
    package = mkPlugin "mini.icons" { };
    lazyLoad.enable = lib.mkDefault false;
    settings = lib.mkDefault {
      file = {
        ".keep" = {
          glyph = "󰊢";
          hl = "MiniIconsGrey";
        };
        "devcontainer.json" = {
          glyph = "";
          hl = "MiniIconsAzure";
        };
      };
      filetype = {
        dotenv = {
          glyph = "";
          hl = "MiniIconsYellow";
        };
      };
    };
    luaConfig.post = ''
      require("mini.icons").mock_nvim_web_devicons()
    '';
  };
}
