# Helper edit plugins (#31), all lazy: grug-far (project search/replace),
# dial (smart increment), inc-rename (incremental LSP rename), yanky (yank
# ring). Keymaps are lz.n keys, so first use loads the plugin.
# - <leader>cr = inc-rename (LazyVim inc-rename extra). It replaces the LSP
#   on-attach <leader>cr (a buffer-local map would shadow it); <F2> in
#   keymaps.nix keeps the plain vim.lsp.buf.rename(), so both exist.
# - noice preset inc_rename = true (noice.nix) for the live preview.
# - yanky: <leader>p opens the snacks picker (`yanky` source registered by
#   yanky's setup), not telescope. y/p/P/... are yanky's <Plug> maps.
{ lib, mkPlugin, ... }:
let
  raw = s: { __raw = s; };
  key = lhs: action: desc: extra: {
    __unkeyed-1 = lhs;
    __unkeyed-2 = action;
    inherit desc;
  } // extra;
  fn = lhs: f: desc: extra: key lhs (raw "function() ${f} end") desc extra;
  plug = lhs: p: desc: extra: key lhs "<Plug>(${p})" desc extra;
  nx = { mode = [ "n" "x" ]; };
  dial = inc: g: ''
    local mode = vim.fn.mode(true)
    local is_visual = mode == "v" or mode == "V" or mode == "\22"
    local func = "${if inc then "inc" else "dec"}" .. "${if g then "_g" else "_"}" .. (is_visual and "visual" or "normal")
    local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
    return require("dial.map")[func](group)
  '';
in
{
  programs.nixvim.plugins = {
    grug-far = {
      enable = lib.mkDefault true;
      package = mkPlugin "grug-far.nvim" { };
      settings.headerMaxWidth = lib.mkDefault 80;
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [ "GrugFar" "GrugFarWithin" ];
          keys = [
            (fn "<leader>sr" ''
              local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
              require("grug-far").open({
                transient = true,
                prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
              })
            '' "Search and Replace" nx)
          ];
        };
      };
    };

    inc-rename = {
      enable = lib.mkDefault true;
      package = mkPlugin "inc-rename.nvim" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          cmd = [ "IncRename" ];
          keys = [
            (fn "<leader>cr" ''
              return ":" .. require("inc_rename").config.cmd_name .. " " .. vim.fn.expand("<cword>")
            '' "Rename (inc-rename.nvim)" { expr = true; })
          ];
        };
      };
    };

    dial = {
      enable = lib.mkDefault true;
      package = mkPlugin "dial.nvim" { };
      lazyLoad = {
        enable = lib.mkDefault true;
        settings.keys = [
          (fn "<C-a>" (dial true false) "Increment" { mode = [ "n" "v" ]; expr = true; })
          (fn "<C-x>" (dial false false) "Decrement" { mode = [ "n" "v" ]; expr = true; })
          (fn "g<C-a>" (dial true true) "Increment" { mode = [ "n" "x" ]; expr = true; })
          (fn "g<C-x>" (dial false true) "Decrement" { mode = [ "n" "x" ]; expr = true; })
        ];
      };
      # LazyVim dial extra: groups + per-filetype choice.
      luaConfig.content = ''
        local augend = require("dial.augend")
        local logical_alias = augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true })
        local ordinal_numbers = augend.constant.new({
          elements = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" },
          word = false,
          cyclic = true,
        })
        local months = augend.constant.new({
          elements = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },
          word = true,
          cyclic = true,
        })
        local groups = {
          default = {
            augend.integer.alias.decimal,
            augend.integer.alias.decimal_int,
            augend.integer.alias.hex,
            augend.date.alias["%Y/%m/%d"],
            augend.constant.alias.en_weekday,
            augend.constant.alias.en_weekday_full,
            ordinal_numbers,
            months,
            augend.constant.alias.bool,
            augend.constant.alias.Bool,
            logical_alias,
          },
          vue = {
            augend.constant.new({ elements = { "let", "const" } }),
            augend.hexcolor.new({ case = "lower" }),
            augend.hexcolor.new({ case = "upper" }),
          },
          typescript = { augend.constant.new({ elements = { "let", "const" } }) },
          css = { augend.hexcolor.new({ case = "lower" }), augend.hexcolor.new({ case = "upper" }) },
          markdown = {
            augend.constant.new({ elements = { "[ ]", "[x]" }, word = false, cyclic = true }),
            augend.misc.alias.markdown_header,
          },
          json = { augend.semver.alias.semver },
          lua = { augend.constant.new({ elements = { "and", "or" }, word = true, cyclic = true }) },
          python = { augend.constant.new({ elements = { "and", "or" } }) },
        }
        for name, group in pairs(groups) do
          if name ~= "default" then vim.list_extend(group, groups.default) end
        end
        require("dial.config").augends:register_group(groups)
        vim.g.dials_by_ft = {
          css = "css", vue = "vue", javascript = "typescript", typescript = "typescript",
          typescriptreact = "typescript", javascriptreact = "typescript", json = "json",
          lua = "lua", markdown = "markdown", sass = "css", scss = "css", python = "python",
        }
      '';
    };

    yanky = {
      enable = lib.mkDefault true;
      package = mkPlugin "yanky.nvim" { nvimSkipModules = [ "yanky.telescope.mapping" "yanky.telescope.yank_history" ]; };
      # The nixvim module also requires yanky.telescope.mapping whenever
      # plugins.telescope is enabled (goimpl dependency, lazy), which fails at
      # load. Plain setup instead; the picker is snacks.
      luaConfig.content = lib.mkForce ''
        require("yanky").setup({
          system_clipboard = { sync_with_ring = not vim.env.SSH_CONNECTION },
          highlight = { timer = 150 },
        })
      '';
      lazyLoad = {
        enable = lib.mkDefault true;
        settings = {
          event = [ "BufReadPost" "BufNewFile" ];
          keys = [
            (fn "<leader>p" ''Snacks.picker.yanky()'' "Open Yank History" nx)
            (plug "y" "YankyYank" "Yank Text" nx)
            (plug "p" "YankyPutAfter" "Put Text After Cursor" nx)
            (plug "P" "YankyPutBefore" "Put Text Before Cursor" nx)
            (plug "gp" "YankyGPutAfter" "Put Text After Selection" nx)
            (plug "gP" "YankyGPutBefore" "Put Text Before Selection" nx)
            (plug "[y" "YankyCycleForward" "Cycle Forward Through Yank History" { })
            (plug "]y" "YankyCycleBackward" "Cycle Backward Through Yank History" { })
            (plug "]p" "YankyPutIndentAfterLinewise" "Put Indented After Cursor (Linewise)" { })
            (plug "[p" "YankyPutIndentBeforeLinewise" "Put Indented Before Cursor (Linewise)" { })
            (plug "]P" "YankyPutIndentAfterLinewise" "Put Indented After Cursor (Linewise)" { })
            (plug "[P" "YankyPutIndentBeforeLinewise" "Put Indented Before Cursor (Linewise)" { })
            (plug ">p" "YankyPutIndentAfterShiftRight" "Put and Indent Right" { })
            (plug "<p" "YankyPutIndentAfterShiftLeft" "Put and Indent Left" { })
            (plug ">P" "YankyPutIndentBeforeShiftRight" "Put Before and Indent Right" { })
            (plug "<P" "YankyPutIndentBeforeShiftLeft" "Put Before and Indent Left" { })
            (plug "=p" "YankyPutAfterFilter" "Put After Applying a Filter" { })
            (plug "=P" "YankyPutBeforeFilter" "Put Before Applying a Filter" { })
          ];
        };
      };
    };
  };
}
