# Web (#36): tailwindcss, astro and svelte language servers (nixpkgs
# binaries, no mason), prettier for astro/svelte/css/html (the shared
# `prettier` formatter in conform.nix only runs where a prettier config
# exists), `<leader>co` = organize imports.
# Not ported: LazyVim's vtsls globalPlugins for astro/svelte (vtsls is off
# by decision in #35, tsc has no tsserver-plugin hook) and the
# tailwindcss-colorizer-cmp nvim-cmp hook (blink.cmp instead). The
# tailwind "No information available" noice skip routes live in noice.nix
# (its `settings` is one mkDefault block; a second definition would replace it).
{ lib, pkgs, ... }:
let
  raw = s: { __raw = s; };
in
{
  programs.nixvim = {
    lsp.servers = {
      tailwindcss = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.tailwindcss-language-server;
        # LazyVim: markdown excluded, Phoenix includeLanguages.
        config = {
          filetypes_exclude = [ "markdown" ];
          settings.tailwindCSS.includeLanguages = {
            elixir = "html-eex";
            eelixir = "html-eex";
            heex = "html-eex";
          };
        };
      };
      astro = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.astro-language-server;
        # astro-ls needs a tsserverlibrary.js, which TypeScript 7 dropped
        # (tsc/biome in typescript.nix use the 7 binary); use TS 5 as tsdk.
        config.init_options.typescript.tsdk = "${pkgs.typescript_5}/lib/node_modules/typescript/lib";
      };
      svelte = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.svelte-language-server;
      };
    };

    plugins.conform-nvim.settings.formatters_by_ft = {
      astro = lib.mkDefault [ "prettier" ];
      svelte = lib.mkDefault [ "prettier" ];
    };

    keymaps = [
      {
        key = "<leader>co";
        action = raw ''
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = { only = { "source.organizeImports" }, diagnostics = {} },
            })
          end
        '';
        options.desc = "Organize Imports";
      }
    ];

    # LazyVim's tailwindcss `filetypes_exclude` is applied before the
    # server starts: drop the excluded filetypes from lspconfig's defaults.
    extraConfigLuaPost = ''
      do
        local cfg = vim.lsp.config.tailwindcss
        local excl = cfg and cfg.filetypes_exclude
        if cfg and cfg.filetypes and excl then
          vim.lsp.config("tailwindcss", {
            filetypes = vim.tbl_filter(function(ft)
              return not vim.tbl_contains(excl, ft)
            end, cfg.filetypes),
          })
        end
      end
    '';
  };
}
