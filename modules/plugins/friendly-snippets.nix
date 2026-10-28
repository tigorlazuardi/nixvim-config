# Snippet collection for blink.cmp (#32). Data-only plugin: eager, because
# blink finds snippets through runtimepath and lz.n does not load deps.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.friendly-snippets = {
    enable = lib.mkDefault true;
    package = mkPlugin "friendly-snippets" { };
  };
}
