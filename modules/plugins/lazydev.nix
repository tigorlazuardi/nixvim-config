# lazydev (#27): lua_ls knows the Neovim API and loaded plugins while
# editing Lua. lazy on ft=lua / :LazyDev. Also enables lua_ls itself
# (nixpkgs binary) with LazyVim's default settings, and registers lazydev
# as a blink.cmp source for Lua buffers.
# Not ported: LazyVim's `LazyVim`/`lazy.nvim` library entries (neither is
# present here).
{ lib, pkgs, mkPlugin, ... }:
{
  programs.nixvim = {
    lsp.servers.lua_ls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.lua-language-server;
      config.settings.Lua = {
        workspace.checkThirdParty = false;
        codeLens.enable = true;
        completion.callSnippet = "Replace";
        doc.privateName = [ "^_" ];
        hint = {
          enable = true;
          setType = false;
          paramType = true;
          paramName = "Disable";
          semicolon = "Disable";
          arrayIndex = "Disable";
        };
      };
    };

    plugins.lazydev = {
      enable = lib.mkDefault true;
      package = mkPlugin "lazydev.nvim" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          ft = [ "lua" ];
          cmd = [ "LazyDev" ];
        };
      };
      settings.library = [
        {
          path = "\${3rd}/luv/library";
          words = [ "vim%.uv" ];
        }
        {
          path = "snacks.nvim";
          words = [ "Snacks" ];
        }
        {
          path = "nvim-lspconfig";
          words = [ "lspconfig.settings" ];
        }
      ];
    };

    plugins.blink-cmp.settings.sources = {
      per_filetype.lua = lib.mkDefault [
        "lazydev"
        "lsp"
        "path"
        "snippets"
        "buffer"
      ];
      providers.lazydev = {
        name = lib.mkDefault "LazyDev";
        module = lib.mkDefault "lazydev.integrations.blink";
        # Top priority for Lua (LazyVim).
        score_offset = lib.mkDefault 100;
      };
    };
  };
}
