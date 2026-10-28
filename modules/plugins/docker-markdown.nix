# Docker + Markdown (#38). Linters (hadolint, markdownlint-cli2) are already
# wired in nvim-lint (#26); the dockerfile grammar comes from #10.
# - dockerls + docker_compose_language_service from nixpkgs.
# - marksman stays off: nothing enables it (the owner's old config disabled it).
# - render-markdown (own input, lazy ft) with the LazyVim opts and a
#   <leader>um Snacks.toggle.
# - markdown-preview (nixpkgs package: it ships a prebuilt node app, so it is a
#   per-plugin pinning exception), lazy on its commands; <leader>cp on markdown.
# - conform: prettier -> markdownlint-cli2 -> markdown-toc as in the LazyVim
#   markdown extra. markdownlint-cli2 only runs when markdownlint diagnostics
#   exist; lspconfig.nix turns diagnostics off for markdown buffers (owner
#   preference), so in practice it stays idle there.
{
  lib,
  pkgs,
  mkPlugin,
  ...
}:
let
  mdFts = [
    "markdown"
    "markdown.mdx"
  ];
in
{
  programs.nixvim = {
    lsp.servers = {
      dockerls = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.dockerfile-language-server;
      };
      docker_compose_language_service = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.docker-compose-language-service;
      };
    };

    filetype = {
      extension.mdx = lib.mkDefault "markdown.mdx";
      # Neovim has no compose detection; the compose language server only
      # attaches to yaml.docker-compose (yamlls handles that ft too).
      filename = lib.genAttrs [
        "docker-compose.yml"
        "docker-compose.yaml"
        "compose.yml"
        "compose.yaml"
      ] (_: lib.mkDefault "yaml.docker-compose");
    };

    plugins.render-markdown = {
      enable = lib.mkDefault true;
      package = mkPlugin "render-markdown.nvim" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.ft = [
          "markdown"
          "norg"
          "rmd"
          "org"
          "codecompanion"
        ];
      };
      settings = {
        code = {
          sign = false;
          width = "block";
          right_pad = 1;
        };
        heading = {
          sign = false;
          icons = [ ];
        };
        checkbox.enabled = false;
      };
      luaConfig.post = ''
        Snacks.toggle({
          name = "Render Markdown",
          get = require("render-markdown").get,
          set = require("render-markdown").set,
        }):map("<leader>um")
      '';
    };

    plugins.markdown-preview = {
      enable = lib.mkDefault true;
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [
            "MarkdownPreviewToggle"
            "MarkdownPreview"
            "MarkdownPreviewStop"
          ];
          keys = [
            {
              __unkeyed-1 = "<leader>cp";
              __unkeyed-2 = "<cmd>MarkdownPreviewToggle<cr>";
              ft = "markdown";
              desc = "Markdown Preview";
            }
          ];
        };
      };
    };

    plugins.conform-nvim.settings = {
      formatters_by_ft = lib.genAttrs mdFts (_: lib.mkDefault [
        "prettier"
        "markdownlint-cli2"
        "markdown-toc"
      ]);
      formatters = {
        markdown-toc.condition.__raw = ''
          function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then return true end
            end
          end
        '';
        markdownlint-cli2.condition.__raw = ''
          function(_, ctx)
            local diag = vim.tbl_filter(function(d) return d.source == "markdownlint" end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end
        '';
      };
    };

    # markdown-toc / markdownlint-cli2 binaries for conform.
    extraPackages = [
      pkgs.markdown-toc
      pkgs.markdownlint-cli2
    ];
  };
}
