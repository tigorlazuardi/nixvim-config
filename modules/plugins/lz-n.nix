# Lazy-load provider. nixvim loads it first (extraConfigLuaPre) so triggers
# are honoured. Never mix with plugins.lazy (lazy.nvim).
{ lib, ... }:
{
  programs.nixvim.plugins.lz-n.enable = lib.mkDefault true;
}
