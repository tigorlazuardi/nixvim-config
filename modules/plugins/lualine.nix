# Statusline, ported from LazyVim's sections. Deferred pieces:
# - Snacks profiler status, dap status, lazy.status updates (not ported / #12)
# - trouble symbols via vim.g.trouble_lualine (#13)
# LazyVim's root detection (LazyVim.root.get) is not ported: root_dir shows
# the cwd basename instead.
{ lib, mkPlugin, ... }:
{
  programs.nixvim.plugins.lualine = {
    enable = lib.mkDefault true;
    package = mkPlugin "lualine.nvim" { };
    lazyLoad.enable = lib.mkDefault true;
    lazyLoad.settings.event = [ "DeferredUIEnter" ];
    settings = lib.mkDefault {
      options = {
        theme = "auto";
        globalstatus = true;
        disabled_filetypes.statusline = [
          "dashboard"
          "alpha"
          "ministarter"
          "snacks_dashboard"
        ];
      };
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [ "branch" ];
        lualine_c = [
          {
            __raw = ''
              function()
                local icon = "󱉭 "
                local name = vim.fs.basename(vim.fn.getcwd())
                return icon .. " " .. (name or "")
              end
            '';
            color.__raw = ''function() return { fg = __nvim_hl_fg("Special") } end'';
          }
          {
            __unkeyed-1 = "diagnostics";
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = "󰌵 ";
            };
          }
          {
            __unkeyed-1 = "filetype";
            icon_only = true;
            separator = "";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            # pretty_path (LazyVim), simplified: cwd-relative, length 3,
            # modified/bold/readonly highlight. No root detection.
            __raw = ''
              function(self)
                local path = vim.fn.expand("%:p")
                if path == "" then
                  return ""
                end
                path = vim.fs.normalize(path)
                local cwd = vim.fs.normalize(vim.fn.getcwd())
                if path:find(cwd, 1, true) == 1 then
                  path = path:sub(#cwd + 2)
                end
                local sep = package.config:sub(1, 1)
                local parts = vim.split(path, "[\\/]")
                if #parts > 3 then
                  parts = { parts[1], "…", unpack(parts, #parts - 2, #parts) }
                end
                local function fmt(text, hl_group)
                  text = text:gsub("%%", "%%%%")
                  if not hl_group or hl_group == "" then
                    return text
                  end
                  self.hl_cache = self.hl_cache or {}
                  local cached = self.hl_cache[hl_group]
                  if not cached then
                    local utils = require("lualine.utils.utils")
                    local gui = vim.tbl_filter(function(x)
                      return x
                    end, {
                      utils.extract_highlight_colors(hl_group, "bold") and "bold",
                      utils.extract_highlight_colors(hl_group, "italic") and "italic",
                    })
                    cached = self:create_hl({
                      fg = utils.extract_highlight_colors(hl_group, "fg"),
                      gui = #gui > 0 and table.concat(gui, ",") or nil,
                    }, "LV_" .. hl_group)
                    self.hl_cache[hl_group] = cached
                  end
                  return self:format_hl(cached) .. text .. self:get_default_hl()
                end
                if vim.bo.modified then
                  parts[#parts] = parts[#parts] .. ""
                  parts[#parts] = fmt(self, parts[#parts], "MatchParen")
                else
                  parts[#parts] = fmt(self, parts[#parts], "Bold")
                end
                local dir = ""
                if #parts > 1 then
                  dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
                  dir = fmt(self, dir .. sep, "")
                end
                local readonly = ""
                if vim.bo.readonly then
                  readonly = fmt(self, " 󰌾 ", "MatchParen")
                end
                return dir .. parts[#parts] .. readonly
              end
            '';
          }
        ];
        lualine_x = [
          {
            __raw = ''function() return require("noice").api.status.command.get() end'';
            cond.__raw = ''
              function()
                return package.loaded["noice"] and require("noice").api.status.command.has()
              end
            '';
            color.__raw = ''function() return { fg = __nvim_hl_fg("Statement") } end'';
          }
          {
            __raw = ''function() return require("noice").api.status.mode.get() end'';
            cond.__raw = ''
              function()
                return package.loaded["noice"] and require("noice").api.status.mode.has()
              end
            '';
            color.__raw = ''function() return { fg = __nvim_hl_fg("Constant") } end'';
          }
          {
            __unkeyed-1 = "diff";
            symbols = {
              added = " ";
              modified = " ";
              removed = " ";
            };
            source.__raw = ''
              function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end
            '';
          }
        ];
        lualine_y = [
          {
            __unkeyed-1 = "progress";
            separator = " ";
            padding = {
              left = 1;
              right = 0;
            };
          }
          {
            __unkeyed-1 = "location";
            padding = {
              left = 0;
              right = 1;
            };
          }
        ];
        lualine_z = [
          {
            __raw = ''function() return "" .. os.date("%R") end'';
          }
        ];
      };
    };
  };
}
