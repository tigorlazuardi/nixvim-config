# TS/JS (#35): `tsc` LSP (TypeScript 7 native `tsc --lsp`) for type
# diagnostics, biome as LSP + formatter, tabstop 4. vtsls and tsgo stay
# off (LazyVim defaults off here; nothing enables them). Binaries from
# nixpkgs (`typescript` >= 7 provides `tsc --lsp`).
{ lib, pkgs, ... }:
let
  fts = [
    "javascript"
    "javascriptreact"
    "typescript"
    "typescriptreact"
  ];
in
{
  programs.nixvim = {
    lsp.servers = {
      tsc = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.typescript;
        config.settings."js/ts".inlayHints = {
          enumMemberValues.enabled = true;
          functionLikeReturnTypes.enabled = false;
          parameterNames = {
            enabled = "literals";
            suppressWhenArgumentMatchesName = true;
          };
          parameterTypes.enabled = true;
          propertyDeclarationTypes.enabled = true;
          variableTypes.enabled = false;
        };
      };
      biome = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.biome;
      };
    };

    plugins.conform-nvim.settings = {
      formatters_by_ft = lib.genAttrs fts (_: lib.mkDefault [ "biome-check" ]);
      # Only where a biome config exists, so prettier projects stay on prettier.
      formatters."biome-check".require_cwd = lib.mkDefault true;
    };

    autoCmd = [
      {
        event = "FileType";
        pattern = fts;
        callback.__raw = ''
          function()
            vim.opt_local.tabstop = 4
            vim.opt_local.shiftwidth = 4
            vim.opt_local.expandtab = true
          end
        '';
        desc = "TS/JS use 4 spaces";
      }
    ];
  };
}
