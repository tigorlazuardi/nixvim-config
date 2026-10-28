# Base editor options, ported from the dotfiles base config.
# mkDefault per key (lib.mapAttrs below): wrapping the whole attrset would be
# dropped as soon as another module sets any `opts.*` key at normal priority
# (treesitter.nix does), silently disabling every option here.
{
  lib,
  ...
}:
{
  programs.nixvim.opts = lib.mapAttrs (_: lib.mkDefault) {
    # https://www.lazyvim.org/configuration/general
    autowrite = true;
    clipboard = "unnamedplus";
    # conceallevel = 2;
    completeopt = "menu,menuone,noselect";
    confirm = true;
    cursorline = true;
    expandtab = true;
    fillchars = {
      foldopen = builtins.fromJSON ''"\uf078"'';
      foldclose = builtins.fromJSON ''"\uf054"'';
      fold = " ";
      foldsep = " ";
      diff = "╱";
      eob = " ";
    };
    formatoptions = "jcroqlnt";
    grepformat = "%f:%l:%c:%m";
    grepprg = "rg --vimgrep";
    foldlevel = 99;
    foldtext = "";
    ignorecase = true;
    inccommand = "nosplit";
    jumpoptions = "view";
    laststatus = 3;
    linebreak = true;
    list = true;
    mouse = "a";
    number = true;
    pumblend = 10;
    pumheight = 10;
    relativenumber = true;
    ruler = false;
    scrolloff = 5;
    sessionoptions = [
      "buffers"
      "curdir"
      "tabpages"
      "winsize"
      "help"
      "globals"
      "skiprtp"
      "folds"
    ];
    shiftround = true;
    shiftwidth = 2;
    shortmess = "ltToOCF" + "WIc";
    showmode = false;
    sidescrolloff = 8;
    signcolumn = "yes";
    smartcase = true;
    smartindent = true;
    spelllang = [ "en" ];
    splitbelow = true;
    splitkeep = "screen";
    splitright = true;
    tabstop = 4;
    softtabstop = 4;
    termguicolors = true;
    timeoutlen.__raw = # lua
      ''
        vim.g.vscode and 1000 or 300
      '';
    undofile = true;
    undolevels = 10000;
    updatetime = 200;
    virtualedit = "block";
    wildmode = "longest:full,full";
    winminwidth = 5;
    wrap = true;
    title = true;

    smoothscroll = true;
  };
}
