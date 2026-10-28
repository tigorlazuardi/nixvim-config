# One file per plugin. Add a plugin: (1) modules/plugins/<name>.input.nix
# (flake-file.inputs.*; flake.nix is GENERATED, never edit it - regenerate:
# nix-shell https://github.com/denful/flake-file/archive/main.tar.gz -A flake-file.sh --run bootstrap),
# (2) modules/plugins/<name>.nix + <name>.check.nix (behaviour check, picked
# up automatically by flake.nix), (3) list the module here.
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
    ./typescript.nix
    ./go.nix
    ./neotest.nix
    ./web.nix
    ./lazydev.nix
    ./trouble.nix
    ./gitsigns.nix
    ./session.nix
    ./helper-edit.nix
    ./data-formats.nix
    ./docker-markdown.nix
    ./dotfiles.nix
  ];
}
