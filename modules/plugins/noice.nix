# Messages/cmdline/popupmenu UI. lsp.override moved to #14 (no LSP yet).
# Route: long notify -> split (user override); msg_show write/scroll noise
# -> mini (LazyVim default).
# "No information available" skip routes added in #36 (tailwind hover).
{ lib, mkPlugin, ... }:
let
  key = lhs: rhs: mode: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2.__raw = "function() ${rhs} end";
    inherit mode desc;
  };
in
{
  programs.nixvim.plugins.noice = {
    enable = lib.mkDefault true;
    package = mkPlugin "noice.nvim" {
      # noice imports these backends lazily; nixvim's require-check can't
      # resolve them statically (they need notify/snacks/nui at import time).
      nvimSkipModules = [
        "noice.message.init"
        "noice.text.block"
        "noice.text.init"
        "noice.ui.cmdline"
        "noice.util.nui"
        "noice.view.backend.mini"
        "noice.view.backend.notify"
        "noice.view.backend.notify_send"
        "noice.view.backend.snacks"
        "noice.view.backend.virtualtext"
        "noice.view.init"
        "noice.view.nui"
        "noice.view.scrollbar"
      ];
    };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings = {
        event = [ "DeferredUIEnter" ];
        keys = [
          { __unkeyed-1 = "<leader>sn"; __unkeyed-2 = ""; mode = "n"; desc = "+noice"; }
          (key "<S-Enter>" ''require("noice").redirect(vim.fn.getcmdline())'' "c" "Redirect Cmdline")
          (key "<leader>snl" ''require("noice").cmd("last")'' "n" "Noice Last Message")
          (key "<leader>snh" ''require("noice").cmd("history")'' "n" "Noice History")
          (key "<leader>sna" ''require("noice").cmd("all")'' "n" "Noice All")
          (key "<leader>snd" ''require("noice").cmd("dismiss")'' "n" "Dismiss All")
          (key "<leader>snt" ''require("noice").cmd("pick")'' "n" "Noice Picker (Telescope/FzfLua)")
          (key "<c-f>" ''if not require("noice.lsp").scroll(4) then return "<c-f>" end'' [ "i" "n" "s" ] "Scroll Forward")
          (key "<c-b>" ''if not require("noice.lsp").scroll(-4) then return "<c-b>" end'' [ "i" "n" "s" ] "Scroll Backward")
        ];
      };
    };
    settings = lib.mkDefault {
      routes = [
        {
          filter = {
            event = "notify";
            min_height = 15;
          };
          view = "split";
        }
        {
          filter = {
            event = "msg_show";
            any = [
              { find = "%d+L, %d+B"; }
              { find = "; after #%d+"; }
              { find = "; before #%d+"; }
            ];
          };
          view = "mini";
        }
        # tailwindcss-language-server hover noise (owner's old route).
        {
          filter = {
            event = "notify";
            find = "No information available";
          };
          opts.skip = true;
        }
        {
          filter = {
            event = "lsp";
            kind = "message";
            find = "No information available";
          };
          opts.skip = true;
        }
      ];
      presets = {
        bottom_search = true;
        command_palette = true;
        long_message_to_split = true;
        inc_rename = true;
      };
    };
  };
}
