# Dart + Flutter: flutter-tools.nvim (lazy on ft=dart) owns the Dart analysis
# server (dartls) and the :Flutter* commands (run, devices, reload, restart,
# outline, DevTools). The nixvim module puts nixpkgs `flutter` (bundles the
# Dart SDK) on PATH. LazyVim lang.dart equivalent: dartls settings below.
# Treesitter dart grammar lives in treesitter.nix. Formatting = dartls
# (conform lsp_format = "fallback").
# plenary.nvim is a library and eager (go.nix / neotest.nix); not repeated
# in extraPlugins, only on the require-check rtp.
# ponytail: no DAP (`debugger.enable`); add when a DAP plugin is curated.
{ lib, mkPlugin, ... }:
let
  plenary = mkPlugin "plenary.nvim" { nvimSkipModules = [ "plenary.neorocks.init" ]; };
in
{
  programs.nixvim.plugins.flutter-tools = {
    enable = lib.mkDefault true;
    package = mkPlugin "flutter-tools.nvim" {
      dependencies = [ plenary ];
      # requires nvim-dap, which is not curated here
      nvimSkipModules = [ "flutter-tools.runners.debugger_runner" ];
    };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.ft = [ "dart" ];
    };
    settings = {
      lsp = {
        color.enabled = lib.mkDefault true;
        settings = {
          showTodos = lib.mkDefault true;
          completeFunctionCalls = lib.mkDefault true;
          renameFilesWithClasses = lib.mkDefault "prompt";
          enableSnippets = lib.mkDefault true;
          updateImportsOnRename = lib.mkDefault true;
        };
      };
      widget_guides.enabled = lib.mkDefault false;
    };
  };
}
