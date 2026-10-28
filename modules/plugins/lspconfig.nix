# LSP core (#24): nvim-lspconfig (default server configs) + Neovim's
# builtin LSP via nixvim's `lsp.*`. Eager: LSP is global core.
# Per-language servers belong to their language tickets; this module only
# ships `nil_ls` (Nix) as the first, demonstrable server.
# Not ported: LazyVim LSP folds (treesitter foldexpr from #10 already
# covers it); codelens stays off, only the run keys exist.
{ lib, mkPlugin, ... }:
let
  raw = s: { __raw = s; };
  # Next/prev diagnostic by priority error → warn → info → hint.
  jump =
    dir: ''
      function()
        for _, sev in ipairs({
          vim.diagnostic.severity.ERROR,
          vim.diagnostic.severity.WARN,
          vim.diagnostic.severity.INFO,
          vim.diagnostic.severity.HINT,
        }) do
          local d = vim.diagnostic.get_${dir}({ severity = sev })
          if d then
            vim.diagnostic.jump({ diagnostic = d })
            return
          end
        end
      end
    '';
  nmap = key: action: desc: {
    inherit key action;
    mode = "n";
    options.desc = desc;
  };
in
{
  programs.nixvim = {
    plugins.lspconfig = {
      enable = lib.mkDefault true;
      package = mkPlugin "nvim-lspconfig" { };
    };

    lsp = {
      servers = {
        # Defaults shared by every server: willRename/didRename for <leader>cR.
        "*".config.capabilities.workspace.fileOperations = {
          didRename = true;
          willRename = true;
        };
        nil_ls.enable = lib.mkDefault true;
      };

      # Inlay hints on everywhere except vue (LazyVim default).
      onAttach = ''
        if client:supports_method("textDocument/inlayHint", bufnr)
          and vim.bo[bufnr].filetype ~= "vue" then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      '';

      keymaps = [
        {
          key = "gd";
          action = raw "function() Snacks.picker.lsp_definitions() end";
          options.desc = "Goto Definition";
        }
        {
          key = "gr";
          action = raw "function() Snacks.picker.lsp_references() end";
          options.desc = "References";
        }
        {
          key = "gI";
          action = raw "function() Snacks.picker.lsp_implementations() end";
          options.desc = "Goto Implementation";
        }
        {
          key = "gy";
          action = raw "function() Snacks.picker.lsp_type_definitions() end";
          options.desc = "Goto T[y]pe Definition";
        }
        {
          key = "gD";
          lspBufAction = "declaration";
          options.desc = "Goto Declaration";
        }
        {
          key = "K";
          lspBufAction = "hover";
          options.desc = "Hover";
        }
        {
          key = "gK";
          lspBufAction = "signature_help";
          options.desc = "Signature Help";
        }
        {
          key = "<c-k>";
          mode = "i";
          lspBufAction = "signature_help";
          options.desc = "Signature Help";
        }
        {
          key = "<leader>ca";
          mode = [
            "n"
            "x"
          ];
          lspBufAction = "code_action";
          options.desc = "Code Action";
        }
        # <leader>cr (rename) lives in helper-edit.nix (inc-rename).
        {
          key = "<leader>cA";
          action = raw ''
            function()
              vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
            end
          '';
          options.desc = "Source Action";
        }
        {
          key = "<leader>cl";
          action = "<cmd>checkhealth vim.lsp<cr>";
          options.desc = "Lsp Info";
        }
      ];
    };

    keymaps = [
      (nmap "]]" (raw (jump "next")) "Next Diagnostic (error → hint)")
      (nmap "[[" (raw (jump "prev")) "Previous Diagnostic (error → hint)")
      (nmap "<leader>cR" (raw "function() Snacks.rename.rename_file() end") "Rename File")
      (nmap "<leader>cd" (raw "vim.diagnostic.open_float") "Line Diagnostics")
      (nmap "<leader>uh" (raw ''
        function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end
      '') "Toggle Inlay Hints")
      (nmap "<leader>cc" (raw "vim.lsp.codelens.run") "Run Codelens")
    ];

    # tiny-inline-diagnostic owns inline text, so virtual_text stays off.
    diagnostic.settings = lib.mkDefault {
      underline = true;
      update_in_insert = false;
      virtual_text = false;
      severity_sort = true;
      signs.text.__raw = ''
        {
          [vim.diagnostic.severity.ERROR] = " ",
          [vim.diagnostic.severity.WARN] = " ",
          [vim.diagnostic.severity.HINT] = " ",
          [vim.diagnostic.severity.INFO] = " ",
        }
      '';
    };

    # No diagnostics noise in .env*, markdown and dockerfile buffers.
    autoCmd = [
      {
        event = [
          "BufNewFile"
          "BufRead"
        ];
        pattern = ".env*";
        callback = raw "function(a) vim.diagnostic.enable(false, { bufnr = a.buf }) end";
        desc = "Diagnostics off for .env*";
      }
      {
        event = "FileType";
        pattern = [
          "markdown"
          "dockerfile"
        ];
        callback = raw "function(a) vim.diagnostic.enable(false, { bufnr = a.buf }) end";
        desc = "Diagnostics off for markdown/dockerfile";
      }
    ];
  };
}
