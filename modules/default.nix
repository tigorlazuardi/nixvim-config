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
    ./lazyvim-defaults.nix
    ./clipboard.nix
    ./git.nix
    ./neovide.nix
    ./plugins
  ];

  # Granular pinning (ADR-0001): build a plugin from its own flake input.
  # `name` is the input name AND the pack/opt folder (pname) lz.n loads.
  # `extra` merges into buildVimPlugin (nvimSkipModules, checkInputs, ...);
  # nixpkgs vimPlugins overrides don't apply to our own inputs, so mirror
  # the relevant ones per plugin.
  _module.args.mkPlugin =
    name: extra:
    pkgs.vimUtils.buildVimPlugin (
      {
        pname = name;
        version = inputs.${name}.shortRev or inputs.${name}.lastModifiedDate or "dirty";
        src = inputs.${name};
      }
      // extra
    );

  _module.args.craneLib = inputs.crane.mkLib pkgs;

  programs.nixvim = {
    enable = lib.mkDefault true;
    nixpkgs.pkgs = lib.mkDefault pkgs;
    defaultEditor = lib.mkDefault true;
    # Bake the generated init into the wrapped nvim package itself, so
    # packages.default is self-contained (init otherwise lands in the
    # consumer's xdg.configFile only).
    wrapRc = lib.mkDefault true;

    extraPackages = lib.mkDefault (with pkgs; [
      ripgrep
      fd
      wgo
    ]);

    # Structural (not mkDefault): leader breaks subtly without the Space
    # NOP, autocmds index _M unconditionally, and autoGroups must exist
    # before any autocmd references them (init.lua evaluates in file order).
    extraConfigLuaPre = ''
      -- Shared platform-info table; neovide.nix sets _M.platform under
      -- Neovide. Pre-create so `_M.platform or "nvim"` never indexes nil.
      _M = _M or {}

      -- Space key has to be set to NOP for setting leader key to space to work.
      vim.keymap.set("", "<Space>", "<Nop>", {})

      -- Pre-create autoGroups here: nixvim emits group definitions after
      -- autocmds in init.lua, but nvim_create_autocmd validates eagerly.
      for _, group in ipairs({ "CheckTime", "ResizeSplits", "LastLoc", "CloseWithQ", "ManUnlisted", "WrapText", "AutoCreateDir", "WindowTitle", "LazyFormat", "HighlightYank" }) do
        vim.api.nvim_create_augroup(group, { clear = false })
      end

      -- Highlight-group fg helper for lualine colors (LazyVim uses
      -- Snacks.util.color; snacks lives in ticket #12).
      function _G.__nvim_hl_fg(name)
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        if not ok or not hl or not hl.fg then
          return nil
        end
        return string.format("#%06x", hl.fg)
      end
    '';

    # mkDefault per key: wrapping the whole attrset is dropped as soon as any
    # other module (lz-n sets globals.lz_n) defines `globals` at normal priority.
    globals = {
      mapleader = lib.mkDefault " ";
      maplocalleader = lib.mkDefault "\\";
    };
  };
}
