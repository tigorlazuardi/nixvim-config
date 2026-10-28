# QoL bundle: picker/explorer/terminal/dashboard/notifier/input/scratch/
# lazygit/profiler/zen/dim/words/bigfile/quickfile/statuscolumn/scroll/
# toggle/rename/scope. Decisions vs LazyVim:
# - statuscolumn enabled (curation keep); LazyVim had it off.
# - words enabled (curation keep; independent of the ]] [[ diagnostic-nav
#   override).
# - image module off (not in curation).
# - smooth scrolling: scroll.enabled, not smooth (renamed upstream).
{ lib, mkPlugin, ... }:
let
  key = lhs: rhs: mode: desc: {
    __unkeyed-1 = lhs;
    __unkeyed-2.__raw = "function() ${rhs} end";
    inherit mode desc;
  };
  # Snacks is eager (start), so lz.n keys would be ignored: map directly.
  keys = [
    (key "<F3>" "Snacks.picker.pick()" "n" "Show Pickers")
    (key "<leader>z" ''
      Snacks.lazygit({ cwd = vim.fn.getcwd() })
    '' "n" "Lazygit (Root Dir)")
    (key "<leader>fe" ''
      Snacks.explorer({ cwd = vim.fn.getcwd() })
    '' "n" "Explorer Snacks (root dir)")
    (key "<leader>fE" "Snacks.explorer()" "n" "Explorer Snacks (cwd)")
    (key "<leader>e" "Snacks.explorer({ cwd = vim.fn.getcwd() })" "n" "Explorer Snacks (root dir)")
    (key "<leader>E" "Snacks.explorer()" "n" "Explorer Snacks (cwd)")
    # picker keys (LazyVim snacks_picker)
    (key "<leader>," "Snacks.picker.buffers()" "n" "Buffers")
    (key "<leader>/" "Snacks.picker.grep()" "n" "Grep (Root Dir)")
    (key "<leader>:" "Snacks.picker.command_history()" "n" "Command History")
    (key "<leader><space>" "Snacks.picker.files()" "n" "Find Files (Root Dir)")
    (key "<leader>n" "Snacks.picker.notifications()" "n" "Notification History")
    (key "<leader>un" "Snacks.notifier.hide()" "n" "Dismiss All Notifications")
    (key "<leader>fb" "Snacks.picker.buffers()" "n" "Buffers")
    (key "<leader>fB" ''
      Snacks.picker.buffers({ hidden = true, nofile = true })
    '' "n" "Buffers (all)")
    (key "<leader>fc" ''
      Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
    '' "n" "Find Config File")
    (key "<leader>ff" "Snacks.picker.files()" "n" "Find Files (Root Dir)")
    (key "<leader>fF" ''
      Snacks.picker.files({ root = false })
    '' "n" "Find Files (cwd)")
    (key "<leader>fg" "Snacks.picker.git_files()" "n" "Find Files (git-files)")
    (key "<leader>fr" "Snacks.picker.recent()" "n" "Recent")
    (key "<leader>fR" ''
      Snacks.picker.recent({ filter = { cwd = true } })
    '' "n" "Recent (cwd)")
    (key "<leader>fp" "Snacks.picker.projects()" "n" "Projects")
    (key "<leader>gd" "Snacks.picker.git_diff()" "n" "Git Diff (hunks)")
    (key "<leader>gs" "Snacks.picker.git_status()" "n" "Git Status")
    (key "<leader>gS" "Snacks.picker.git_stash()" "n" "Git Stash")
    (key "<leader>sb" "Snacks.picker.lines()" "n" "Buffer Lines")
    (key "<leader>sB" "Snacks.picker.grep_buffers()" "n" "Grep Open Buffers")
    (key "<leader>sg" "Snacks.picker.grep()" "n" "Grep (Root Dir)")
    (key "<leader>sG" ''
      Snacks.picker.grep({ root = false })
    '' "n" "Grep (cwd)")
    (key "<leader>sp" "Snacks.picker.lazy()" "n" "Search for Plugin Spec")
    (key "<leader>sw" "Snacks.picker.grep_word()" [
      "n"
      "x"
    ] "Visual selection or word (Root Dir)")
    (key "<leader>sW"
      ''
        Snacks.picker.grep_word({ root = false })
      ''
      [
        "n"
        "x"
      ]
      "Visual selection or word (cwd)"
    )
    (key "<leader>s\"" "Snacks.picker.registers()" "n" "Registers")
    (key "<leader>s/" "Snacks.picker.search_history()" "n" "Search History")
    (key "<leader>sa" "Snacks.picker.autocmds()" "n" "Autocmds")
    (key "<leader>sc" "Snacks.picker.command_history()" "n" "Command History")
    (key "<leader>sC" "Snacks.picker.commands()" "n" "Commands")
    (key "<leader>sd" "Snacks.picker.diagnostics()" "n" "Diagnostics")
    (key "<leader>sD" "Snacks.picker.diagnostics_buffer()" "n" "Buffer Diagnostics")
    (key "<leader>sh" "Snacks.picker.help()" "n" "Help Pages")
    (key "<leader>sH" "Snacks.picker.highlights()" "n" "Highlights")
    (key "<leader>si" "Snacks.picker.icons()" "n" "Icons")
    (key "<leader>sj" "Snacks.picker.jumps()" "n" "Jumps")
    (key "<leader>sk" "Snacks.picker.keymaps()" "n" "Keymaps")
    (key "<leader>sl" "Snacks.picker.loclist()" "n" "Location List")
    (key "<leader>sM" "Snacks.picker.man()" "n" "Man Pages")
    (key "<leader>sm" "Snacks.picker.marks()" "n" "Marks")
    (key "<leader>sR" "Snacks.picker.resume()" "n" "Resume")
    (key "<leader>sq" "Snacks.picker.qflist()" "n" "Quickfix List")
    (key "<leader>su" "Snacks.picker.undo()" "n" "Undotree")
    (key "<leader>uC" "Snacks.picker.colorschemes()" "n" "Colorschemes")
    # terminal
    (key "<c-/>"
      ''
        Snacks.terminal()
      ''
      [
        "n"
        "t"
      ]
      "Toggle Terminal"
    )
    (key "<c-_>"
      ''
        Snacks.terminal()
      ''
      [
        "n"
        "t"
      ]
      "which_key_ignore"
    )
    # scratch / zen
    (key "<leader>." ''
      Snacks.scratch()
    '' "n" "Toggle Scratch Buffer")
    (key "<leader>S" ''
      Snacks.scratch.select()
    '' "n" "Select Scratch Buffer")
    (key "<leader>uz" ''
      Snacks.zen()
    '' "n" "Toggle Zen Mode")
    (key "<leader>uZ" ''
      Snacks.zen.zoom()
    '' "n" "Toggle Zoom")
    # profiler
    (key "<leader>dpp" "Snacks.profiler.toggle()" "n" "Toggle Profiler")
    (key "<leader>dps" "Snacks.profiler.start()" "n" "Start Profiler")
    (key "<leader>dpb" "Snacks.profiler.toggle()" "n" "Toggle Profiler")
  ];
in
{
  programs.nixvim.keymaps = map (k: {
    mode = k.mode;
    key = k.__unkeyed-1;
    action = k.__unkeyed-2;
    options.desc = k.desc;
  }) keys;

  programs.nixvim.plugins.snacks = {
    enable = lib.mkDefault true;
    package = mkPlugin "snacks.nvim" {
      # Backend modules import lazily (notify/snacks views, docs, profiler);
      # nixvim's static require-check cannot resolve them.
      nvimSkipModules = [ "snacks.picker.util.db" ];
      # Bundled trouble extension (trouble.sources.profiler) needs trouble.
      dependencies = [ (mkPlugin "trouble.nvim" { nvimSkipModules = [ "trouble.docs" ]; }) ];
    };
    lazyLoad.enable = lib.mkDefault false; # start: host of lightweight QoL modules
    settings = lib.mkDefault {
      bigfile.enabled = true;
      dashboard = {
        preset = {
          header = ''
            ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
            ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z
            ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z
            ██║     ██║  ██║███████╗   ██║   ██║  ╚████╔╝ ██║██║ ╚═╝ ██║ z
            ███████╗██║  ██║╚════██║   ╚═╝   ╚═╝   ╚═══╝  ██║╚══════╝ ╚═╝
            ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝              ╚═══╝  ╚═╝     ╚═╝
          '';
          keys = [
            {
              icon = " ";
              key = "f";
              desc = "Find File";
              action = ":lua Snacks.dashboard.pick('files')";
            }
            {
              icon = " ";
              key = "n";
              desc = "New File";
              action = ":ene | startinsert";
            }
            {
              icon = " ";
              key = "g";
              desc = "Find Text";
              action = ":lua Snacks.dashboard.pick('live_grep')";
            }
            {
              icon = " ";
              key = "r";
              desc = "Recent Files";
              action = ":lua Snacks.dashboard.pick('oldfiles')";
            }
            {
              icon = " ";
              key = "c";
              desc = "Config";
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})";
            }
            {
              icon = " ";
              key = "p";
              desc = "Projects";
              action = ":lua Snacks.picker.projects()";
            }
            {
              icon = " ";
              key = "s";
              desc = "Restore Session";
              section = "session";
            }
            {
              icon = " ";
              key = "q";
              desc = "Quit";
              action = ":qa";
            }
          ];
        };
      };
      dim.enabled = true;
      explorer = { };
      indent = {
        enabled = true;
        indent = {
          enabled = false; # indent-blankline owns guides (#11)
        };
      };
      input.enabled = true;
      lazygit.enabled = true;
      notifier.enabled = true;
      picker = { };
      profiler = { };
      quickfile.enabled = true;
      rename.enabled = true;
      scope.enabled = true;
      scroll.enabled = true;
      scratch.enabled = true;
      statuscolumn.enabled = true;
      terminal.enabled = true;
      toggle.enabled = true;
      words.enabled = true;
      zen.enabled = true;
    };
    # Cross-plugin affordances that need every target loaded; this spec
    # runs when snacks (start) initialises, after all DeferredUIEnter
    # lazy plugins from #10/#11.
    luaConfig.post =
      ""
      # ibl toggle (LazyVim indent-blankline extra)
      + ''
        Snacks.toggle({
                name = "Indention Guides",
                get = function()
                  return require("ibl.config").get_config(0).enabled
                end,
                set = function(state)
                  require("ibl").setup_buffer(0, { enabled = state })
                end,
              }):map("<leader>ug")

              Snacks.toggle({
                name = "Treesitter Context",
                get = function()
                  local ok, tsc = pcall(require, "treesitter-context")
                  return ok and tsc.enabled() or false
                end,
                set = function(state)
                  local tsc = require("treesitter-context")
                  if state then
                    tsc.enable()
                  else
                    tsc.disable()
                  end
                end,
              }):map("<leader>ut")

              Snacks.toggle({
                name = "Mini Pairs",
                get = function()
                  return not vim.g.minipairs_disable
                end,
                set = function(state)
                  vim.g.minipairs_disable = not state
                end,
              }):map("<leader>up")
      '';
  };
}
