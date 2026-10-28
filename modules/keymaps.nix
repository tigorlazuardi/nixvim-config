# Global keymaps + LSP default-mapping cleanup (]] [[ live in plugins/lspconfig.nix).
#
# `keymaps`/`autoCmd` are lists: left un-mkDefault on purpose. Lists from
# different modules with equal priority concatenate, so a consumer adding
# keymaps appends; full replacement stays possible via lib.mkForce.
{
  ...
}:
{
  programs.nixvim = {
    # Delete default lsp mappings
    extraConfigLua = ''
      vim.keymap.del("n", "grn")
      vim.keymap.del({ "n", "v" }, "gra")
      vim.keymap.del("n", "grr")
      vim.keymap.del("n", "gri")
      vim.keymap.del("n", "gO")
      vim.keymap.del("i", "<c-s>")
      vim.keymap.del("n", "grt")
    '';
    keymaps =
      let
        map = mode: key: action: options: {
          inherit
            key
            action
            mode
            options
            ;
        };
      in
      [
        {
          action = "<gv";
          key = "<";
          mode = "v";
          options.desc = "Indent Left";
        }
        {
          action = ">gv";
          key = ">";
          mode = "v";
          options.desc = "Indent Right";
        }
        # Add undo breakpoints on typing , . ;
        {
          key = ",";
          action = ",<c-g>u";
          mode = "i";
        }
        {
          key = ".";
          action = ".<c-g>u";
          mode = "i";
        }
        {
          key = ";";
          action = ";<c-g>u";
          mode = "i";
        }
        {
          key = "<esc>";
          action.__raw = ''
            function()
              vim.cmd("noh")
              if vim.snippet.active() then vim.snippet.stop() end
              return "<esc>"
            end
          '';
          mode = [
            "i"
            "n"
            "s"
          ];
          options = {
            expr = true;
            desc = "Escape and Clear HLSearch";
          };
        }

        # Better moving up / down
        {
          key = "j";
          action = "v:count == 0 ? 'gj' : 'j'";
          mode = [
            "n"
            "x"
          ];
          options = {
            desc = "Down";
            expr = true;
            silent = true;
          };
        }
        {
          key = "<Down>";
          action = "v:count == 0 ? 'gj' : 'j'";
          mode = [
            "n"
            "x"
          ];
          options = {
            desc = "Down";
            expr = true;
            silent = true;
          };
        }
        {
          key = "k";
          action = "v:count == 0 ? 'gk' : 'k'";
          mode = [
            "n"
            "x"
          ];
          options = {
            desc = "Up";
            expr = true;
            silent = true;
          };
        }
        {
          key = "<Up>";
          action = "v:count == 0 ? 'gk' : 'k'";
          mode = [
            "n"
            "x"
          ];
          options = {
            desc = "Up";
            expr = true;
            silent = true;
          };
          # Jump to buffers.
        }
        {
          key = "<s-h>";
          action = "<cmd>bprevious<cr>";
          mode = [ "n" ];
          options.desc = "Prev Buffer";
        }
        {
          key = "<s-l>";
          action = "<cmd>bnext<cr>";
          mode = [ "n" ];
          options.desc = "Next Buffer";
        }
        # Jump Windows
        (map [ "n" ] "<c-h>" "<c-w>h" {
          desc = "Go to Left Window";
          remap = true;
        })
        (map [ "n" ] "<c-l>" "<c-w>l" {
          desc = "Go to Right Window";
          remap = true;
        })
        (map [ "n" ] "<c-k>" "<c-w>k" {
          desc = "Go to Up Window";
          remap = true;
        })
        (map [ "n" ] "<c-j>" "<c-w>j" {
          desc = "Go to Down Window";
          remap = true;
        })
        (map [ "t" ] "<c-j>" "<c-\\><c-n><c-w>j" {
          desc = "Go to Down Window";
          remap = true;
        })
        (map [ "t" ] "<c-k>" "<c-\\><c-n><c-w>k" {
          desc = "Go to Up Window";
          remap = true;
        })
        (map [ "t" ] "<c-h>" "<c-\\><c-n><c-w>h" {
          desc = "Go to Left Window";
          remap = true;
        })
        (map [ "t" ] "<c-l>" "<c-\\><c-n><c-w>l" {
          desc = "Go to Right Window";
          remap = true;
        })

        # Basic LSP
        (map [ "n" ] "<F2>" "<cmd>lua vim.lsp.buf.rename()<cr>" {
          desc = "Rename Symbol";
        })
        (map [ "n" ] "<tab>" "<cmd>b#<cr>" {
          desc = "Switch to Last Buffer";
        })
      ];
  };
}
