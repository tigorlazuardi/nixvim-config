# Shared flake inputs (plenary.nvim is a dependency of go, neotest, trouble).
{
  flake-file.inputs = {
    "plenary.nvim" = {
      url = "github:nvim-lua/plenary.nvim";
      flake = false;
    };
  };
}
