# Entry point: `import ./modules inputs` → one Home Manager module.
#
# Consumer usage:
#   imports = [ inputs.nixvim-config.homeManagerModules.default ];
#
# Every consumer-tunable value is wrapped in mkDefault (ADR-0001):
# this repo's value wins when the consumer stays silent; the consumer
# wins by setting the same `programs.nixvim.*` path.
inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./opts.nix
    ./keymaps.nix
    ./autocmds.nix
    ./clipboard.nix
    ./git.nix
    ./neovide.nix
  ];

  programs.nixvim = {
    enable = lib.mkDefault true;
    nixpkgs.pkgs = lib.mkDefault pkgs;
    defaultEditor = lib.mkDefault true;

    extraPackages = lib.mkDefault (with pkgs; [
      ripgrep
      fd
      wgo
    ]);

    # Structural (not mkDefault): leader breaks subtly without the Space
    # NOP, and autocmds index _M unconditionally.
    extraConfigLuaPre = ''
      -- Shared platform-info table; neovide.nix sets _M.platform under
      -- Neovide. Pre-create so `_M.platform or "nvim"` never indexes nil.
      _M = _M or {}

      -- Space key has to be set to NOP for setting leader key to space to work.
      vim.keymap.set("", "<Space>", "<Nop>", {})
    '';

    globals = lib.mkDefault {
      # Set leader key to space.
      mapleader = " ";
      maplocalleader = "\\";
    };
  };
}
