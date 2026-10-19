# LazyVim textobjects. which-key registration (LazyVim.mini.ai_whichkey)
# is deferred to the which-key ticket (#11).
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.mini-ai = {
    enable = lib.mkDefault true;
    package = mkPlugin "mini.ai" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.event = [ "DeferredUIEnter" ];
    };
    settings = {
      n_lines = lib.mkDefault 500;
      custom_textobjects = lib.mkDefault {
        o.__raw = ''
          require("mini.ai").gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          })
        '';
        f.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })'';
        c.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })'';
        t = [
          "<([%p%w]-)%f[^<%w][^<>]->.-</%1>"
          "^<.->().*()</[^/]->$"
        ];
        d = [ "%f[%d]%d+" ];
        e = [
          [
            "%u[%l%d]+%f[^%l%d]"
            "%f[%S][%l%d]+%f[^%l%d]"
            "%f[%P][%l%d]+%f[^%l%d]"
            "^[%l%d]+%f[^%l%d]"
          ]
          "^().*()$"
        ];
        g.__raw = ''
          function(ai_type)
            local start_line, end_line = 1, vim.fn.line("$")
            if ai_type == "i" then
              local first, last = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
              if first == 0 or last == 0 then
                return { from = { line = start_line, col = 1 } }
              end
              start_line, end_line = first, last
            end
            local to_col = math.max(vim.fn.getline(end_line):len(), 1)
            return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
          end
        '';
        u.__raw = ''require("mini.ai").gen_spec.function_call()'';
        U.__raw = ''require("mini.ai").gen_spec.function_call({ name_pattern = "[%w_]" })'';
      };
    };
  };
}
