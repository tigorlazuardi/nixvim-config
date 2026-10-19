# One file per plugin. Add a plugin: (1) flake input in flake.nix,
# (2) modules/plugins/<name>.nix, (3) list it here.
{
  imports = [
    ./lz-n.nix
    ./tokyonight.nix
  ];
}
