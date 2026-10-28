# Linting (#26): nvim-lint, lazy on first buffer. Dispatcher mirrors
# LazyVim's (debounced; ft → linters via nvim-lint's own resolver, plus
# "_" fallback and "*" global lists, plus per-linter `condition`) and
# replaces nixvim's default BufWritePost-only autocmd.
# Binaries come from nixvim `autoInstall` (nixpkgs); zero mason.
# golangci-lint stays off: Go = {} is set explicitly (nixvim drops empty
# lists) so nothing re-adds LazyVim's default.
{ lib, mkPlugin, ... }:
{
  programs.nixvim = {
    plugins.lint = {
      enable = lib.mkDefault true;
      package = mkPlugin "nvim-lint" { };
      autoInstall.enable = lib.mkDefault true;
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.event = lib.mkDefault [
          "BufReadPost"
          "BufNewFile"
        ];
      };
      lintersByFt = {
        nix = lib.mkDefault [ "statix" ];
        sh = lib.mkDefault [ "shellcheck" ];
        markdown = lib.mkDefault [ "markdownlint-cli2" ];
        dockerfile = lib.mkDefault [ "hadolint" ];
        # nixvim drops empty lists; `go = {}` is set explicitly in luaConfig.post.
      };
      # Replace the default BufWritePost-only trigger with ours below.
      autoCmd = null;
      # Runs once when the plugin loads (first buffer). `condition` is a
      # LazyVim extension: a linter table may carry condition(ctx).
      luaConfig.post = ''
        local lint = require("lint")
        lint.linters_by_ft.go = lint.linters_by_ft.go or {}
        local timer = vim.uv.new_timer()
        local function run()
          local names = lint._resolve_linter_by_ft(vim.bo.filetype)
          names = vim.list_extend({}, names)
          if #names == 0 then vim.list_extend(names, lint.linters_by_ft["_"] or {}) end
          vim.list_extend(names, lint.linters_by_ft["*"] or {})
          local ctx = { filename = vim.api.nvim_buf_get_name(0) }
          ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
          names = vim.tbl_filter(function(name)
            local l = lint.linters[name]
            return l and not (type(l) == "table" and l.condition and not l.condition(ctx))
          end, names)
          if #names > 0 then lint.try_lint(names) end
        end
        local function debounced()
          timer:start(100, 0, function()
            timer:stop()
            vim.schedule(run)
          end)
        end
        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
          group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
          callback = debounced,
        })
        -- The load was triggered by the first buffer event; lint it now.
        debounced()
      '';
    };
  };
}
