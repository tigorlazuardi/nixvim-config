# nvim-treesitter stays on nixpkgs (NOT its own flake input): grammars are
# built by nixpkgs and must match the queries of the same nvim-treesitter
# rev, so plugin + grammars move together with the nixpkgs bump.
# Eager (not lz.n): FileType for the first buffer fires before any lazy
# event could load it, so highlight would miss the first file.
{ config, lib, ... }:
let
  ts = config.programs.nixvim.plugins.treesitter.package.builtGrammars;
in
{
  programs.nixvim = {
    plugins.treesitter = {
      enable = lib.mkDefault true;
      highlight.enable = lib.mkDefault true;
      indent.enable = lib.mkDefault true;
      folding.enable = lib.mkDefault true;
      # LazyVim ensure_installed + curated languages (#5).
      grammarPackages = lib.mkDefault (
        with ts;
        [
          astro
          bash
          c
          css
          diff
          dockerfile
          fish
          git_config
          git_rebase
          gitattributes
          gitcommit
          gitignore
          go
          gomod
          gosum
          gotmpl
          gowork
          html
          hyprlang
          javascript
          jsdoc
          json
          lua
          luadoc
          luap
          make
          markdown
          markdown_inline
          nix
          printf
          python
          query
          rasi
          regex
          toml
          svelte
          tsx
          typescript
          vim
          vimdoc
          xml
          yaml
        ]
      );
    };

    opts.foldlevelstart = lib.mkDefault 99;
  };
}
