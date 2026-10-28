# Dotfiles + git filetypes + mini.hipatterns (#39).
# - bashls (nixpkgs) + shellcheck on PATH; filetype rules from the LazyVim
#   util.dot extra (rasi, waybar jsonc, mako dosini, kitty, hypr, .env.*).
#   Grammars (git_*, hyprlang, rasi, fish, bash) come from #10; nvim-lint's
#   shellcheck entry for sh is in nvim-lint.nix (#26).
# - cmp-git is not ported (nvim-cmp unused).
# - mini.hipatterns (own input, lazy on buffer read): hex colors, #rgb
#   shorthand and Tailwind classes, as in LazyVim's util.mini-hipatterns.
#   The palette lives in tailwind-colors.lua (global _G.__tailwind_colors).
# - SQL/dadbod is not carried over (owner decision).
{
  lib,
  pkgs,
  mkPlugin,
  ...
}:
let
  raw = s: { __raw = s; };
  tailwindFts = [
    "astro"
    "css"
    "heex"
    "html"
    "html-eex"
    "javascript"
    "javascriptreact"
    "rust"
    "svelte"
    "typescript"
    "typescriptreact"
    "vue"
  ];
in
{
  programs.nixvim = {
    lsp.servers.bashls = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.bash-language-server;
    };
    extraPackages = [ pkgs.shellcheck ];

    filetype = {
      extension = {
        rasi = lib.mkDefault "rasi";
        rofi = lib.mkDefault "rasi";
        wofi = lib.mkDefault "rasi";
      };
      filename.vifmrc = lib.mkDefault "vim";
      pattern = {
        ".*/waybar/config" = lib.mkDefault "jsonc";
        ".*/mako/config" = lib.mkDefault "dosini";
        ".*/kitty/.+%.conf" = lib.mkDefault "kitty";
        ".*/hypr/.+%.conf" = lib.mkDefault "hyprlang";
        "%.env%.[%w_.-]+" = lib.mkDefault "sh";
      };
    };
    extraConfigLuaPost = ''
      vim.treesitter.language.register("bash", "kitty")
    '';

    extraConfigLuaPre = builtins.readFile ./tailwind-colors.lua + "\n_G.__tailwind_hl = {}\n";

    plugins.mini-hipatterns = {
      enable = lib.mkDefault true;
      package = mkPlugin "mini.hipatterns" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.event = [
          "BufReadPost"
          "BufNewFile"
        ];
      };
      settings.highlighters = {
        hex_color = raw ''require("mini.hipatterns").gen_highlighter.hex_color({ priority = 2000 })'';
        shorthand = {
          pattern = "()#%x%x%x()%f[^%x%w]";
          group = raw ''
            function(_, _, data)
              local match = data.full_match
              if match == "#add" then return end
              local r, g, b = match:sub(2, 2), match:sub(3, 3), match:sub(4, 4)
              return MiniHipatterns.compute_hex_color_group("#" .. r .. r .. g .. g .. b .. b, "bg")
            end
          '';
          extmark_opts.priority = 2000;
        };
        # Tailwind: full class highlighted (LazyVim style = "full").
        tailwind = {
          pattern = raw ''
            function()
              if not vim.tbl_contains({ ${lib.concatMapStringsSep ", " (f: "\"${f}\"") tailwindFts} }, vim.bo.filetype) then return end
              return "%f[%w:-]()[%w:-]+%-[a-z%-]+%-%d+()%f[^%w:-]"
            end
          '';
          group = raw ''
            function(_, _, m)
              local color, shade = m.full_match:match("[%w-]+%-([a-z%-]+)%-(%d+)")
              shade = tonumber(shade)
              local bg = vim.tbl_get(_G.__tailwind_colors, color, shade)
              if bg then
                local hl = "MiniHipatternsTailwind" .. color .. shade
                if not _G.__tailwind_hl[hl] then
                  _G.__tailwind_hl[hl] = true
                  local bg_shade = shade == 500 and 950 or shade < 500 and 900 or 100
                  local fg = vim.tbl_get(_G.__tailwind_colors, color, bg_shade)
                  vim.api.nvim_set_hl(0, hl, { bg = "#" .. bg, fg = "#" .. fg })
                end
                return hl
              end
            end
          '';
          extmark_opts.priority = 2000;
        };
      };
      luaConfig.post = ''
        vim.api.nvim_create_autocmd("ColorScheme", {
          callback = function() _G.__tailwind_hl = {} end,
        })
      '';
    };
  };
}
