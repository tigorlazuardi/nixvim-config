# Flake inputs for modules/plugins/neotest.nix (assembled into flake.nix by flake-file).
{
  flake-file.inputs = {
    "neotest" = {
      url = "github:nvim-neotest/neotest";
      flake = false;
    };
    "nvim-nio" = {
      url = "github:nvim-neotest/nvim-nio";
      flake = false;
    };
    "neotest-golang" = {
      url = "github:fredrikaverpil/neotest-golang";
      flake = false;
    };
  };
}
