# Keymap popup. spec groups ported from LazyVim; proxy <leader>w -> <c-w>
# works (c-w maps exist in keymaps.nix). expand buf/win needs which-key >= 3.
{ lib, mkPlugin, ... }:
let
  group = lhs: desc: extra: { __unkeyed-1 = lhs; group = desc; } // extra;
in
{
  programs.nixvim.plugins.which-key = {
    enable = lib.mkDefault true;
    package = mkPlugin "which-key.nvim" {
      nvimSkipModules = [ "which-key.docs" ];
    };
    lazyLoad.enable = lib.mkDefault true;
    lazyLoad.settings.event = [ "DeferredUIEnter" ];
    settings = lib.mkDefault {
      preset = "helix";
      spec = [
        {
          mode = [
            "n"
            "x"
          ];
          __unkeyed-1 = group "<leader><tab>" "tabs" { };
          __unkeyed-2 = group "<leader>c" "code" { };
          __unkeyed-3 = group "<leader>d" "debug" { };
          __unkeyed-4 = group "<leader>dp" "profiler" { };
          __unkeyed-5 = group "<leader>f" "file/find" { };
          __unkeyed-6 = group "<leader>g" "git" { };
          __unkeyed-7 = group "<leader>gh" "hunks" { };
          __unkeyed-8 = group "<leader>q" "quit/session" { };
          __unkeyed-9 = group "<leader>s" "search" { };
          __unkeyed-10 = group "<leader>u" "ui" { };
          __unkeyed-11 = group "<leader>x" "diagnostics/quickfix" { };
          __unkeyed-12 = group "[" "prev" { };
          __unkeyed-13 = group "]" "next" { };
          __unkeyed-14 = group "g" "goto" { };
          __unkeyed-15 = group "gs" "surround" { };
          __unkeyed-16 = group "z" "fold" { };
          __unkeyed-17 = {
            __unkeyed-1 = "<leader>b";
            group = "buffer";
            expand.__raw = ''function() return require("which-key.extras").expand.buf() end'';
          };
          __unkeyed-18 = {
            __unkeyed-1 = "<leader>w";
            group = "windows";
            proxy = "<c-w>";
            expand.__raw = ''function() return require("which-key.extras").expand.win() end'';
          };
          __unkeyed-19 = {
            __unkeyed-1 = "gx";
            desc = "Open with system app";
          };
        }
      ];
    };
    luaConfig.post = ''
      vim.keymap.set("n", "<leader>?", function()
        require("which-key").show({ global = false })
      end, { desc = "Buffer Keymaps (which-key)" })
      vim.keymap.set("n", "<c-w><space>", function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end, { desc = "Window Hydra Mode (which-key)" })
    '';
  };
}
