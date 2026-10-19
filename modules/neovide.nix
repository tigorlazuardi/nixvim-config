# Neovide GUI tweaks.
{
  lib,
  pkgs,
  ...
}:
{
  # Neovide GUI + the font its block below uses; list stays plain so consumers append.
  home.packages = [
    pkgs.neovide
    pkgs.jetbrains-mono
    pkgs.nerd-fonts.symbols-only
  ];
  fonts.fontconfig.enable = lib.mkDefault true;

  programs.nixvim.extraConfigLua = # lua
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

        vim.keymap.set(
          { "n", "v", "s", "x", "o", "i", "l", "c", "t" },
          "<C-S-v>",
          function() vim.api.nvim_paste(vim.fn.getreg "+", true, -1) end,
          { noremap = true, silent = true }
        )
      end
    '';
}
