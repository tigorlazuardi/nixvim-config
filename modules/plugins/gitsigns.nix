# gitsigns (#29): gutter signs, hunk nav/actions, blame, `ih` text object.
# Lazy on buffer read (LazyVim's LazyFile). Keymaps are buffer-local via
# on_attach (LazyVim), so they only exist in tracked files.
# Note: lualine's diff component (lualine.nix) already reads
# vim.b.gitsigns_status_dict, and catppuccin has the gitsigns integration.
{ lib, mkPlugin, ... }:
let
  sign = text: { inherit text; };
in
{
  programs.nixvim.plugins.gitsigns = {
    enable = lib.mkDefault true;
    package = mkPlugin "gitsigns.nvim" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [ "BufReadPost" "BufNewFile" "BufWritePre" ];
    };
    settings = lib.mkDefault {
      signs = {
        add = sign "▎";
        change = sign "▎";
        delete = sign "";
        topdelete = sign "";
        changedelete = sign "▎";
        untracked = sign "▎";
      };
      signs_staged = {
        add = sign "▎";
        change = sign "▎";
        delete = sign "";
        topdelete = sign "";
        changedelete = sign "▎";
      };
      on_attach.__raw = ''
        function(buffer)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
          end
          map("n", "]h", function()
            if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end
          end, "Next Hunk")
          map("n", "[h", function()
            if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end
          end, "Prev Hunk")
          map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
          map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
          map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
          map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
          map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
          map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
          map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
          map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
          map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
          map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
          map("n", "<leader>ghd", gs.diffthis, "Diff This")
          map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
        end
      '';
    };
  };
}
