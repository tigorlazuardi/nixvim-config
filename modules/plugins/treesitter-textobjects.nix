# Move keys ]f [f ]c [c ]a [a (+ end variants), buffer-local per filetype
# that has a textobjects query — ported from LazyVim.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.treesitter-textobjects = {
    enable = lib.mkDefault true;
    package = mkPlugin "nvim-treesitter-textobjects" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings = {
        event = [ "DeferredUIEnter" ];
        # `after` replaces generated setup (callSetup is off for this plugin).
        after.__raw = ''
          function()
            require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
            local moves = {
              goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
              goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
              goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
              goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
            }
            local function attach(buf)
              local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
              if not (lang and vim.treesitter.query.get(lang, "textobjects")) then
                return
              end
              for method, keymaps in pairs(moves) do
                for key, query in pairs(keymaps) do
                  local name = query:gsub("@", ""):gsub("%..*", "")
                  local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ")
                    .. name:sub(1, 1):upper() .. name:sub(2)
                    .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
                  vim.keymap.set({ "n", "x", "o" }, key, function()
                    if vim.wo.diff and key:find("[cC]") then
                      return vim.cmd("normal! " .. key)
                    end
                    require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
                  end, { buffer = buf, desc = desc, silent = true })
                end
              end
            end
            vim.api.nvim_create_autocmd("FileType", {
              group = vim.api.nvim_create_augroup("TextobjectsMoves", { clear = true }),
              callback = function(ev) attach(ev.buf) end,
            })
            vim.tbl_map(attach, vim.api.nvim_list_bufs())
          end
        '';
      };
    };
  };
}
