# Test runner (#34): neotest + nvim-nio + neotest-golang, lazy on the
# <leader>t keys. nvim-nio and plenary.nvim (go.nix) are libraries and
# stay eager (lz.n does not auto-load deps); the adapter sits in
# pack/start too but is only `require`d from neotest's setup.
# Not ported: LazyVim's trouble consumer (trouble lands in #28) and the
# dap strategy / <leader>td (no DAP plugin is curated, so
# dap_go_enabled = false). Quickfix opens with :copen.
{ lib, mkPlugin, ... }:
let
  nio = mkPlugin "nvim-nio" { };
  neotest = mkPlugin "neotest" { dependencies = [ nio plenary ]; };
  plenary = mkPlugin "plenary.nvim" { nvimSkipModules = [ "plenary.neorocks.init" ]; };
  key = lhs: fn: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2.__raw = "function() ${fn} end";
    inherit desc;
  };
in
{
  programs.nixvim = {
    extraPlugins = [ nio ];

    plugins.neotest = {
      enable = lib.mkDefault true;
      # Libraries are eager at runtime; the require-check needs them too.
      package = neotest;
      adapters.golang = {
        enable = lib.mkDefault true;
        package = mkPlugin "neotest-golang" { dependencies = [ nio plenary neotest ]; };
        settings.dap_go_enabled = lib.mkDefault false;
      };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.keys = [
          (key "<leader>ta" ''require("neotest").run.attach()'' "Attach to Test (Neotest)")
          (key "<leader>tt" ''require("neotest").run.run(vim.fn.expand("%"))'' "Run File (Neotest)")
          (key "<leader>tT" ''require("neotest").run.run(vim.uv.cwd())'' "Run All Test Files (Neotest)")
          (key "<leader>tr" ''require("neotest").run.run()'' "Run Nearest (Neotest)")
          (key "<leader>tl" ''require("neotest").run.run_last()'' "Run Last (Neotest)")
          (key "<leader>ts" ''require("neotest").summary.toggle()'' "Toggle Summary (Neotest)")
          (key "<leader>to" ''require("neotest").output.open({ enter = true, auto_close = true })'' "Show Output (Neotest)")
          (key "<leader>tO" ''require("neotest").output_panel.toggle()'' "Toggle Output Panel (Neotest)")
          (key "<leader>tS" ''require("neotest").run.stop()'' "Stop (Neotest)")
          (key "<leader>tw" ''require("neotest").watch.toggle(vim.fn.expand("%"))'' "Toggle Watch (Neotest)")
        ];
      };
      settings = {
        status.virtual_text = lib.mkDefault true;
        output.open_on_run = lib.mkDefault true;
        quickfix.open.__raw = ''function() vim.cmd("copen") end'';
      };
      luaConfig.pre = ''
        -- Compact one-line neotest diagnostics (LazyVim).
        vim.diagnostic.config({
          virtual_text = {
            format = function(d)
              return (d.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", ""))
            end,
          },
        }, vim.api.nvim_create_namespace("neotest"))
      '';
    };

    # Group label for which-key; the keys themselves are lz.n triggers.
    plugins.which-key.settings.spec = [
      {
        __unkeyed-1 = "<leader>t";
        group = "test";
      }
    ];
  };
}
