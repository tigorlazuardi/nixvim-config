# One file per plugin. Add a plugin: (1) flake input in flake.nix,
# (2) modules/plugins/<name>.nix, (3) list it here.
{
  imports = [
    ./lz-n.nix
    ./tokyonight.nix
    ./treesitter.nix
    ./treesitter-textobjects.nix
    ./ts-comments.nix
    ./mini-ai.nix
    ./mini-pairs.nix
    ./flash.nix
    ./bufferline.nix
    ./lualine.nix
    ./which-key.nix
    ./noice.nix
    ./nui.nix
    ./mini-icons.nix
    ./indent-blankline.nix
    ./treesitter-context.nix
    ./catppuccin.nix
    ./tiny-inline-diagnostic.nix
    ./snacks.nix
    ./mini-files.nix
    ./lspconfig.nix
    ./blink-cmp.nix
    ./friendly-snippets.nix
    ./conform.nix
    ./nvim-lint.nix
  ];
}
