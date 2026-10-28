# Flake inputs for modules/plugins/blink-cmp.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    # Nix-only library (no plugins): splits Rust deps into their own
    # derivation so a plugin bump does not recompile every crate.
    crane.url = "github:ipetkov/crane";
    "blink.cmp" = {
      url = "github:saghen/blink.cmp/v1"; # v2 (main) needs blink.lib; v1 = LazyVim/nixpkgs line
      flake = false;
    };
  };
}
