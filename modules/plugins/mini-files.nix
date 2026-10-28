# mini.files = FOCUSED view, complementary to snacks.explorer (bird's-eye).
# By design it shows EVERYTHING in the directory (no gitignore/hidden
# filtering, owner decision) — g. toggles dotfiles visibility anyway.
# `-` opens scoped to the current file's directory; preview column on.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.mini-files = {
    enable = lib.mkDefault true;
    package = mkPlugin "mini.files" { };
    lazyLoad = {
      enable = lib.mkDefault true;
      settings.keys = [
        {
          __unkeyed-1 = "-";
          __unkeyed-2.__raw = ''
            function()
              require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
            end
          '';
          mode = "n";
          desc = "mini.files (Directory of Current File)";
        }
        {
          __unkeyed-1 = "<leader>fM";
          __unkeyed-2.__raw = ''
            function()
              require("mini.files").open(vim.uv.cwd(), true)
            end
          '';
          mode = "n";
          desc = "mini.files (cwd)";
        }
      ];
    };
    settings = lib.mkDefault {
      windows = {
        preview = true;
        width_focus = 30;
        width_preview = 30;
      };
      options.use_as_default_explorer = false; # snacks.explorer stays default
    };
    # Buffer maps + rename hook, ported from LazyVim mini-files extra.
    luaConfig.post = ''
      local show_dotfiles = true
      local function filter_show(_)
        return true
      end
      local function filter_hide(fs_entry)
        return not vim.startswith(fs_entry.name, ".")
      end
      local function toggle_dotfiles()
        show_dotfiles = not show_dotfiles
        require("mini.files").refresh({
          content = { filter = show_dotfiles and filter_show or filter_hide },
        })
      end

      local function map_split(buf_id, lhs, direction, close_on_file)
        local rhs = function()
          local new_target_window
          local cur_target_window = require("mini.files").get_explorer_state().target_window
          if cur_target_window ~= nil then
            vim.api.nvim_win_call(cur_target_window, function()
              vim.cmd("belowright " .. direction .. " split")
              new_target_window = vim.api.nvim_get_current_win()
            end)
            require("mini.files").set_target_window(new_target_window)
            require("mini.files").go_in({ close_on_file = close_on_file })
          end
        end
        local desc = "Open in " .. direction .. " split"
        if close_on_file then
          desc = desc .. " and close"
        end
        vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
      end

      local function files_set_cwd()
        local cur_entry_path = MiniFiles.get_fs_entry().path
        local cur_directory = vim.fs.dirname(cur_entry_path)
        if cur_directory ~= nil then
          vim.fn.chdir(cur_directory)
        end
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
          local buf_id = args.data.buf_id
          vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id, desc = "Toggle hidden files" })
          vim.keymap.set("n", "gc", files_set_cwd, { buffer = buf_id, desc = "Set cwd" })
          -- <CR>: directory -> enter, file -> open and close explorer.
          vim.keymap.set("n", "<CR>", function()
            require("mini.files").go_in({ close_on_file = true })
          end, { buffer = buf_id, desc = "Enter dir / open file and close" })
          map_split(buf_id, "<C-w>s", "horizontal", false)
          map_split(buf_id, "<C-w>v", "vertical", false)
          map_split(buf_id, "<C-w>S", "horizontal", true)
          map_split(buf_id, "<C-w>V", "vertical", true)
        end,
      })

      vim.api.nvim_create_autocmd("User", {
        pattern = "MiniFilesActionRename",
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })
    '';
  };
}
