# Tabline. LazyVim's close_command/right_mouse_command use Snacks.bufdelete —
# deferred to #12 (they fall back to defaults until then).
{ lib, mkPlugin, ... }:
let
  cmd = lhs: command: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2 = command;
    mode = "n";
    inherit desc;
  };
in
{
  programs.nixvim.plugins.bufferline = {
    enable = lib.mkDefault true;
    # Mirror of nixpkgs vimPlugins fixes for a self-built bufferline.
    package = mkPlugin "bufferline.nvim" {
      nvimSkipModules = [
        "bufferline.utils"
        "bufferline.commands"
      ];
    };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings = {
        event = [ "DeferredUIEnter" ];
        keys = [
          (cmd "<leader>bp" "<Cmd>BufferLineTogglePin<CR>" "Toggle Pin")
          (cmd "<leader>bP" "<Cmd>BufferLineGroupClose ungrouped<CR>" "Delete Non-Pinned Buffers")
          (cmd "<leader>br" "<Cmd>BufferLineCloseRight<CR>" "Delete Buffers to the Right")
          (cmd "<leader>bl" "<Cmd>BufferLineCloseLeft<CR>" "Delete Buffers to the Left")
          (cmd "[b" "<Cmd>BufferLineCyclePrev<CR>" "Prev Buffer")
          (cmd "]b" "<Cmd>BufferLineCycleNext<CR>" "Next Buffer")
          (cmd "[B" "<Cmd>BufferLineMovePrev<CR>" "Move buffer prev")
          (cmd "]B" "<Cmd>BufferLineMoveNext<CR>" "Move buffer next")
          (cmd "<leader>bj" "<Cmd>BufferLinePick<CR>" "Pick Buffer")
        ];
      };
    };
    settings = lib.mkDefault {
      options = {
        diagnostics = "nvim_lsp";
        always_show_bufferline = false;
        offsets = [
          {
            filetype = "snacks_layout_box";
          }
        ];
      };
    };
    # Fix bufferline when restoring a session (LazyVim autocmd).
    luaConfig.post = ''
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    '';
  };
}
