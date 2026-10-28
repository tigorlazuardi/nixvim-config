# persistence.nvim + nvim-sops (#30), both lazy.
# persistence: loads on BufReadPre (LazyVim), which also starts session
# recording; saved per directory (and branch) in stdpath("state")/sessions
# on exit. Keys <leader>qs/qS/ql/qd are lz.n keys.
# nvim-sops: wraps the `sops` CLI (nixpkgs binary on PATH). No nixvim
# module, so a manual lz.n spec. Lazy on :SopsEncrypt/:SopsDecrypt; the
# plugin's own plugin/ file defines the commands and runs setup on packadd.
# ponytail: no sops keymaps; the README's <leader>ef/<leader>df collide
# with <leader>e (snacks explorer). Add when the owner picks keys.
{ lib, pkgs, mkPlugin, ... }:
let
  key = lhs: fn: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2.__raw = "function() ${fn} end";
    inherit desc;
  };
in
{
  programs.nixvim = {
    plugins.persistence = {
      enable = lib.mkDefault true;
      package = mkPlugin "persistence.nvim" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          event = [ "BufReadPre" ];
          keys = [
            (key "<leader>qs" ''require("persistence").load()'' "Restore Session")
            (key "<leader>qS" ''require("persistence").select()'' "Select Session")
            (key "<leader>ql" ''require("persistence").load({ last = true })'' "Restore Last Session")
            (key "<leader>qd" ''require("persistence").stop()'' "Don't Save Current Session")
          ];
        };
      };
    };

    extraPackages = [ pkgs.sops ];
    extraPlugins = [
      {
        plugin = mkPlugin "nvim-sops" { };
        optional = true;
      }
    ];
    plugins.lz-n.plugins = [
      {
        __unkeyed-1 = "nvim-sops";
        cmd = [ "SopsEncrypt" "SopsDecrypt" ];
      }
    ];
  };
}
