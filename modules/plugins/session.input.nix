# Flake inputs for modules/plugins/session.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    "persistence.nvim" = {
      url = "github:folke/persistence.nvim";
      flake = false;
    };
    "nvim-sops" = {
      url = "github:prismatic-koi/nvim-sops";
      flake = false;
    };
  };
}
