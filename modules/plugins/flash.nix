{ lib, mkPlugin, ... }:
let
  key = lhs: rhs: mode: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2.__raw = "function() ${rhs} end";
    inherit mode desc;
  };
in
{
  programs.nixvim.plugins.flash = {
    enable = lib.mkDefault true;
    package = mkPlugin "flash.nvim" { nvimSkipModules = [ "flash.docs" ]; };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.keys = [
        (key "s" ''require("flash").jump()'' [ "n" "x" "o" ] "Flash")
        (key "S" ''require("flash").treesitter()'' [ "n" "o" "x" ] "Flash Treesitter")
        (key "r" ''require("flash").remote()'' "o" "Remote Flash")
        (key "R" ''require("flash").treesitter_search()'' [ "o" "x" ] "Treesitter Search")
        (key "<c-s>" ''require("flash").toggle()'' "c" "Toggle Flash Search")
        (key "<c-space>" ''
          require("flash").treesitter({ actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" } })
        '' [ "n" "o" "x" ] "Treesitter Incremental Selection")
      ];
    };
  };
}
