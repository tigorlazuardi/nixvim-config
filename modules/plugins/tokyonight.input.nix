# Flake inputs for modules/plugins/tokyonight.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    # --- Plugins (granular pinning, ADR-0001) ---
    # One input per plugin, `flake = false`. Input name == repo name == the
    # `pack/opt/<name>` folder lz.n loads. Update one: nix flake update <name>
    "tokyonight.nvim" = {
      url = "github:folke/tokyonight.nvim";
      flake = false;
    };
  };
}
