# JSON + YAML + TOML (#37): jsonls, yamlls (SchemaStore schemas) and taplo.
# Binaries from nixpkgs. Settings follow the LazyVim json/yaml/toml extras.
# SchemaStore.nvim has no nixvim-free eager need: it is an optional pack
# plugin with an empty lz.n spec, loaded by the servers' before_init (like
# LazyVim's lazy = true), so the big catalog is only required when a JSON or
# YAML buffer starts a server. nixvim's own schemastore module is not used
# because it requires the plugin while the LSP config is generated (eager).
{
  lib,
  pkgs,
  mkPlugin,
  ...
}:
let
  raw = s: { __raw = s; };
  load = ''require("lz.n").trigger_load("SchemaStore.nvim")'';
in
{
  programs.nixvim = {
    lsp.servers = {
      jsonls = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.vscode-langservers-extracted;
        config = {
          before_init = raw ''
            function(_, new_config)
              ${load}
              new_config.settings.json.schemas = new_config.settings.json.schemas or {}
              vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
            end
          '';
          settings.json = {
            format.enable = true;
            validate.enable = true;
          };
        };
      };

      yamlls = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.yaml-language-server;
        config = {
          # yamlls must know that line folding is supported.
          capabilities.textDocument.foldingRange = {
            dynamicRegistration = false;
            lineFoldingOnly = true;
          };
          before_init = raw ''
            function(_, new_config)
              ${load}
              new_config.settings.yaml.schemas = vim.tbl_deep_extend(
                "force",
                new_config.settings.yaml.schemas or {},
                require("schemastore").yaml.schemas()
              )
            end
          '';
          settings = {
            redhat.telemetry.enabled = false;
            yaml = {
              keyOrdering = false;
              format.enable = true;
              validate = true;
              # Use SchemaStore.nvim schemas instead of the built-in support.
              schemaStore = {
                enable = false;
                url = "";
              };
            };
          };
        };
      };

      taplo = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.taplo;
      };
    };

    extraPlugins = [
      {
        plugin = mkPlugin "SchemaStore.nvim" { };
        optional = true;
      }
    ];
    plugins.lz-n.plugins = [ { __unkeyed-1 = "SchemaStore.nvim"; } ];
  };
}
