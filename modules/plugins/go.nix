# Go (#33): gopls (LazyVim lang.go defaults + the owner's overrides: no
# placeholders, hints off, ST1xxx/shadow analyses off), delve on PATH,
# goimpl.nvim (own flake input) for interface stubs, formatters
# goimports+gofumpt. golangci-lint stays off (Go linters are empty in
# nvim-lint.nix). Treesitter go* grammars come from #10.
# goimpl.nvim is only a telescope extension, so telescope.nvim (lazy, loaded
# by goimpl's `before`) and plenary.nvim (library, eager) are own inputs too.
{
  lib,
  pkgs,
  mkPlugin,
  ...
}:
let
  off = lib.genAttrs [
    "ST1000"
    "ST1003"
    "ST1005"
    "ST1006"
    "ST1012"
    "ST1016"
    "ST1017"
    "ST1018"
    "ST1019"
    "ST1020"
    "ST1021"
    "ST1022"
    "ST1023"
    "shadow"
  ] (_: false);
  # plenary.neorocks needs luarocks at require time; unused here.
  plenarySkip = {
    nvimSkipModules = [ "plenary.neorocks.init" ];
  };
in
{
  programs.nixvim = {
    lsp.servers.gopls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.gopls;
      config = {
        init_options.semanticTokens = true;
        settings.gopls = {
          gofumpt = true;
          codelenses = {
            gc_details = false;
            generate = true;
            regenerate_cgo = true;
            run_govulncheck = true;
            test = true;
            tidy = true;
            upgrade_dependency = true;
            vendor = true;
          };
          # Owner override: every hint off, no placeholders.
          usePlaceholders = false;
          hints = lib.genAttrs [
            "assignVariableTypes"
            "compositeLiteralFields"
            "compositeLiteralTypes"
            "constantValues"
            "functionTypeParameters"
            "parameterNames"
            "rangeVariableTypes"
          ] (_: false);
          analyses = {
            nilness = true;
            unusedparams = true;
            unusedwrite = true;
            useany = true;
          } // off;
          completeUnimported = true;
          staticcheck = true;
          directoryFilters = [
            "-.git"
            "-.vscode"
            "-.idea"
            "-.vscode-test"
            "-node_modules"
          ];
        };
      };
    };

    # LazyVim workaround: gopls does not advertise semanticTokensProvider
    # (golang/go#54531), so fill it from the client capabilities.
    lsp.onAttach = ''
      if client.name == "gopls"
        and client.config.init_options
        and client.config.init_options.semanticTokens
        and not client.server_capabilities.semanticTokensProvider then
        local semantic = client.config.capabilities.textDocument.semanticTokens
        client.server_capabilities.semanticTokensProvider = {
          full = true,
          legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
          range = true,
        }
      end
    '';

    plugins.conform-nvim.settings.formatters_by_ft.go = lib.mkDefault [
      "goimports"
      "gofumpt"
    ];

    # gopls shells out to `go`; delve for debugging; impl is goimpl's backend;
    # goimports/gofumpt for conform.
    extraPackages = [
      pkgs.go
      pkgs.gotools
      pkgs.gofumpt
      pkgs.delve
      pkgs.impl
    ];

    # Library plugins must be eager (lz.n does not auto-load deps).
    extraPlugins = [
      (mkPlugin "plenary.nvim" plenarySkip)
      {
        plugin = mkPlugin "goimpl.nvim" { };
        optional = true;
      }
    ];

    # goimpl.nvim has no nixvim module: lz.n spec by hand. Loads on Go
    # filetypes, pulls telescope in first and registers the extension.
    # <leader>im / :GoImpl open the interface picker (Telescope goimpl).
    plugins.lz-n.plugins = [
      {
        __unkeyed-1 = "goimpl.nvim";
        ft = [ "go" ];
        before.__raw = ''
          function() require("lz.n").trigger_load("telescope.nvim") end
        '';
        after.__raw = ''
          function()
            require("telescope").load_extension("goimpl")
            vim.api.nvim_create_user_command("GoImpl", function()
              require("telescope").extensions.goimpl.goimpl({})
            end, { desc = "Generate interface stubs (goimpl)" })
            vim.keymap.set("n", "<leader>im", "<cmd>GoImpl<cr>", { desc = "Go: implement interface" })
          end
        '';
      }
    ];

    plugins.telescope = {
      enable = lib.mkDefault true;
      package = mkPlugin "telescope.nvim" {
        # The require-check needs plenary on the rtp; at runtime it is the
        # eager plenary.nvim from extraPlugins.
        dependencies = [ (mkPlugin "plenary.nvim" plenarySkip) ];
      };
      # No keys/cmd of its own here: goimpl loads it on demand.
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.cmd = [ "Telescope" ];
      };
    };

  };
}
