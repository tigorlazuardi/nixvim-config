# Formatting (#25): conform.nvim, lazy (ConformInfo, <leader>cf/cF, first
# BufWritePre). Format on save is our own BufWritePre autocmd instead of
# conform's format_on_save: conform is not on rtp until loaded, and an
# autocmd defined mid-event would miss the save that loaded it.
# Toggle state follows LazyVim: vim.g.autoformat (global, <leader>uf) and
# vim.b.autoformat (buffer, <leader>uF); buffer wins, unset = enabled.
# Binaries: nixvim `autoInstall` maps formatter names to nixpkgs packages.
# Only nix is wired here; language slices add their formatters_by_ft.
{ lib, pkgs, mkPlugin, ... }:
{
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = lib.mkDefault true;
      package = mkPlugin "conform.nvim" { };
      autoInstall.enable = lib.mkDefault true;
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [ "ConformInfo" ];
          keys = [
            {
              __unkeyed-1 = "<leader>cf";
              __unkeyed-2.__raw = ''function() require("conform").format({ timeout_ms = 3000, lsp_format = "fallback" }) end'';
              mode = [ "n" "x" ];
              desc = "Format";
            }
            {
              __unkeyed-1 = "<leader>cF";
              __unkeyed-2.__raw = ''function() require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 }) end'';
              mode = [ "n" "x" ];
              desc = "Format Injected Langs";
            }
          ];
        };
      };
      settings = {
        default_format_opts = {
          timeout_ms = lib.mkDefault 3000;
          lsp_format = lib.mkDefault "fallback";
        };
        formatters_by_ft.nix = lib.mkDefault [ "nixfmt" ];
        formatters = {
          injected.options.ignore_errors = lib.mkDefault true;
          # LazyVim prettier extra with lazyvim_prettier_needs_config=true:
          # run only when a prettier config exists and a parser is known.
          # Language slices just add "prettier" to formatters_by_ft.
          prettier.condition.__raw = ''
            function(_, ctx)
              if vim.fn.executable("prettier") == 0 then return false end
              local info = vim.fn.system({ "prettier", "--file-info", ctx.filename })
              local ok, parser = pcall(function() return vim.fn.json_decode(info).inferredParser end)
              if not (ok and parser and parser ~= vim.NIL) then return false end
              vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
              return vim.v.shell_error == 0
            end
          '';
        };
      };
    };

    # prettier's condition shells out to the binary; keep it on PATH.
    extraPackages = [ pkgs.prettier ];

    autoCmd = [
      {
        event = "BufWritePre";
        group = "LazyFormat";
        callback.__raw = ''
          function(args)
            local b = vim.b[args.buf].autoformat
            local on = b
            if on == nil then on = vim.g.autoformat end
            if on == nil then on = true end
            if not on then return end
            require("lz.n").trigger_load("conform.nvim")
            require("conform").format({ bufnr = args.buf, timeout_ms = 3000, lsp_format = "fallback", quiet = true })
          end
        '';
      }
    ];

    autoGroups.LazyFormat = { };

    extraConfigLuaPost = ''
      if _G.Snacks then
        Snacks.toggle({
          name = "Auto Format (Global)",
          get = function() return vim.g.autoformat == nil or vim.g.autoformat end,
          set = function(state) vim.g.autoformat = state; vim.b.autoformat = nil end,
        }):map("<leader>uf")
        Snacks.toggle({
          name = "Auto Format (Buffer)",
          get = function()
            local b = vim.b.autoformat
            if b ~= nil then return b end
            return vim.g.autoformat == nil or vim.g.autoformat
          end,
          set = function(state) vim.b.autoformat = state end,
        }):map("<leader>uF")
      end
    '';
  };
}
