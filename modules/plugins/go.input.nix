# Flake inputs for modules/plugins/go.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    "goimpl.nvim" = {
      url = "github:edolphin-ydf/goimpl.nvim";
      flake = false;
    };
    "telescope.nvim" = {
      url = "github:nvim-telescope/telescope.nvim";
      flake = false;
    };
  };
}
