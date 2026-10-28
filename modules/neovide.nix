# Neovide GUI tweaks.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.programs.nixvim-config.gui.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Install Neovide and its fonts (JetBrains Mono, Symbols Nerd Font) via
      home.packages. Set to false on headless hosts to keep the closure small.
      The Neovide Lua tweaks stay (they only run under Neovide).
    '';
  };

  # Neovide GUI + the font its block below uses; list stays plain so consumers append.
  config.home.packages = lib.mkIf config.programs.nixvim-config.gui.enable [
    pkgs.neovide
    pkgs.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];
  config.fonts.fontconfig.enable = lib.mkIf config.programs.nixvim-config.gui.enable (
    lib.mkDefault true
  );

  config.programs.nixvim.extraConfigLua = # lua
    ''
      if vim.g.neovide then
        _M.platform = "Neovide"

        -- Fallback to Symbols Nerd Font to avoid glyph-patching jankiness
        -- (Neovide supports comma-separated fallback fonts)
        local font = "JetBrains Mono,Symbols Nerd Font"

        local font_size = vim.o.lines < 60 and 11 or 12

        vim.o.guifont = font .. ":h" .. font_size
        vim.g.neovide_opacity = 0.8
        vim.g.transparency = 0.8
        vim.g.neovide_window_blurred = true
        vim.g.experimental_layer_grouping = true

        vim.keymap.set("n", "<c-->", function()
          font_size = font_size - 1
          vim.o.guifont = font .. ":h" .. font_size
          vim.notify("Font Set: " .. font .. ":h" .. font_size)
        end, { desc = "Decrease font size" })

        vim.keymap.set("n", "<c-=>", function()
          font_size = font_size + 1
          vim.o.guifont = font .. ":h" .. font_size
          vim.notify("Font Set: " .. font .. ":h" .. font_size)
        end, { desc = "Increase font size" })
      end
    '';
}
