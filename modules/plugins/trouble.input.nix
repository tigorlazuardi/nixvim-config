# Flake inputs for modules/plugins/trouble.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    "trouble.nvim" = {
      url = "github:folke/trouble.nvim";
      flake = false;
    };
    "todo-comments.nvim" = {
      url = "github:folke/todo-comments.nvim";
      flake = false;
    };
  };
}
