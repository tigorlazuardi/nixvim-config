# trouble + todo-comments (#28). Both lazy: trouble on :Trouble and its
# keys, todo-comments on buffer read plus its keys/commands.
# - snacks' profiler extension (trouble.sources.profiler) works now that
#   trouble is a build dependency of snacks (see snacks.nix).
# - <leader>st / <leader>sT use the snacks picker source `todo_comments`
#   that todo-comments registers in setup (LazyVim snacks_picker extra), not
#   telescope (telescope is only a goimpl dependency here). The keys are
#   lz.n keys, so they load todo-comments first.
# Not ported: lualine trouble symbols component (vim.g.trouble_lualine).
{ lib, mkPlugin, ... }:
let
  plenary = mkPlugin "plenary.nvim" { nvimSkipModules = [ "plenary.neorocks.init" ]; };
  trouble = mkPlugin "trouble.nvim" { nvimSkipModules = [ "trouble.docs" ]; };
  key = lhs: action: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2 = action;
    inherit desc;
  };
  cmd = lhs: c: desc: key lhs "<cmd>${c}<cr>" desc;
  fn = lhs: f: desc: key lhs { __raw = "function() ${f} end"; } desc;
  step = dir: cfun: ''
    if require("trouble").is_open() then
      require("trouble").${dir}({ skip_groups = true, jump = true })
    else
      local ok, err = pcall(vim.cmd.${cfun})
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end
  '';
in
{
  programs.nixvim.plugins = {
    trouble = {
      enable = lib.mkDefault true;
      package = trouble;
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [ "Trouble" ];
          keys = [
            (cmd "<leader>xx" "Trouble diagnostics toggle" "Diagnostics (Trouble)")
            (cmd "<leader>xX" "Trouble diagnostics toggle filter.buf=0" "Buffer Diagnostics (Trouble)")
            (cmd "<leader>cs" "Trouble symbols toggle" "Symbols (Trouble)")
            (cmd "<leader>cS" "Trouble lsp toggle" "LSP references/definitions/... (Trouble)")
            (cmd "<leader>xL" "Trouble loclist toggle" "Location List (Trouble)")
            (cmd "<leader>xQ" "Trouble qflist toggle" "Quickfix List (Trouble)")
            (fn "[q" (step "prev" "cprev") "Previous Trouble/Quickfix Item")
            (fn "]q" (step "next" "cnext") "Next Trouble/Quickfix Item")
          ];
        };
      };
      settings.modes.lsp.win.position = lib.mkDefault "right";
    };

    todo-comments = {
      enable = lib.mkDefault true;
      package = mkPlugin "todo-comments.nvim" {
        dependencies = [ plenary ];
        nvimSkipModules = [ "todo-comments.fzf" "todo-comments.snacks" "trouble.sources.todo" "trouble.providers.todo" ];
      };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [ "TodoTrouble" "TodoQuickFix" "TodoLocList" ];
          event = [ "BufReadPost" "BufNewFile" ];
          keys = [
            (fn "]t" ''require("todo-comments").jump_next()'' "Next Todo Comment")
            (fn "[t" ''require("todo-comments").jump_prev()'' "Previous Todo Comment")
            (cmd "<leader>xt" "Trouble todo toggle" "Todo (Trouble)")
            (cmd "<leader>xT" "Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}" "Todo/Fix/Fixme (Trouble)")
            (fn "<leader>st" ''Snacks.picker.pick("todo_comments")'' "Todo")
            (fn "<leader>sT" ''Snacks.picker.pick("todo_comments", { keywords = { "TODO", "FIX", "FIXME" } })'' "Todo/Fix/Fixme")
          ];
        };
      };
    };
  };
}
