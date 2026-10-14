# LazyVim Inventory — menu keputusan keep/drop

Riset untuk tiket [#3](https://github.com/tigorlazuardi/nixvim-config/issues/3). Inventarisasi lengkap **semua yang diberikan LazyVim bawaan (sebelum override)** + config lama user, jadi menu keep/drop untuk migrasi ke nixvim-config. **Tanpa rekomendasi** — keputusan ada di user.

Sumber:
- Repo lama: `/home/homeserver/nix-neovim-config/nvim` (LazyVim starter, `lazyvim.json` 21 extras aktif, `lua/plugins/*.lua` 16 spec, `lua/config/*.lua`)
- LazyVim upstream: https://www.lazyvim.org/ (plugins, keymaps, extras)
- Nixpkgs: dicek via `builtins.attrNames (import <nixpkgs> {}).vimPlugins` (2026-10-14)

Kolom: **Lazy** = lazy-loaded / eager = load saat startup (LazyVim default: plugin LazyVim lazy, plugin custom eager). **nixpkgs** = tersedia di `vimPlugins` (yes/no/unsure).

---

## 0. Plugin manager & bootstrap

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| lazy.nvim | Plugin manager; setup `concurrency=2`, git throttle 1/s, checker update (enabled, notify=false), rtp disabled gzip/tar/tohtml/tutor/zip, `defaults.lazy=false`, install colorscheme tokyonight/habamax | user config (`config/lazy.lua`) | eager (bootstrap) | yes |
| LazyVim/LazyVim | Import `lazyvim.plugins` — seluruh default di bawah | user config + LazyVim default | — | yes |

---

## 1. Colorscheme & UI

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| tokyonight.nvim | Colorscheme utama. Override user: `transparent=true`, sidebars & floats transparent | LazyVim default + user override (`plugins/tokyonight.lua`) | eager (install colorscheme) | yes |
| catppuccin | Colorscheme alternatif LazyVim (bawaan kedua, `<leader>ub` toggle dark memakainya) | LazyVim default | lazy | yes |
| bufferline.nvim | Tabline/buffer bar atas, pin/delete buffers, `[b`/`]b`/`<S-h>`/`<S-l` | LazyVim default | eager (UI) | yes |
| lualine.nvim | Statusline global: mode, branch, root dir, diagnostics, filetype+pretty_path, noice mode status, dap status, lazy update, git diff (dari gitsigns), progress/location, jam | LazyVim default | eager (UI) | yes |
| which-key.nvim | Popup keymap hints, `<leader>` = `<space>`, `<localleader>` = `\` | LazyVim default | eager | yes |
| noice.nvim | UI messages/cmdline/popupmenu/lsp progress. Override user: route notify min_height≥15 → view split; suppress "No information available" (tailwind) | LazyVim default + user override (`plugins/noice.lua`, `plugins/tailwind.lua`) | eager | yes |
| nui.nvim | Lib komponen UI (dep noice) | LazyVim default (dep) | — | yes |
| mini.icons | Ikon filetype/file | LazyVim default | lazy | yes |
| snacks.nvim (UI parts) | Dashboard (starter screen), notifier, statuscolumn, smooth scroll, zen mode, indent guides, dim, words (LSP highlight jump), bigfile, input, rename, quickfile, gitbrowse | LazyVim default | campur | yes |
| indent-blankline.nvim | Indent guides | active extra `ui.indent-blankline` | lazy | yes |
| nvim-treesitter-context | Sticky context header atas (fungsi/kelas saat scroll) | active extra `ui.treesitter-context` | lazy | yes |
| tiny-inline-diagnostic.nvim | Inline diagnostic di bawah kursor (pengganti virtual_text). User opts: show_source, throttle 0, multilines always, multiple_diag_under_cursor, enable_on_insert; virtual_text nvim-lspconfig dimatikan | user config (`plugins/tiny-inline-diagnostics.lua`) | lazy | yes |

### Snippets & autopairs (coding defaults, dipakai UI/completion)

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| mini.pairs | Autopairs otomatis | LazyVim default | eager (event VeryLazy) | yes |
| ts-comments.nvim | Comment string per treesitter | LazyVim default | lazy (ft) | yes |
| mini.ai | Textobjects custom (f/c/o/t/d/e/g/u/U, treesitter-based) | LazyVim default | lazy | yes |
| nvim-treesitter-textobjects | Motion textobjects (af/if, ac/ic, dst Q) | LazyVim default | lazy | yes |
| flash.nvim | Motion/jump `s`/`S`, treesitter search, incremental selection `<c-space>` | LazyVim default | lazy | yes |

---

## 2. Editor core

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| snacks.nvim (picker) | File picker (`<leader><space>`, `<leader>ff`, git-files), grep (`<leader>/`, `<leader>sg`), buffers (`<leader>,`), recent, projects, registers, jumps, marks, help, keymaps, autocmds, commands, man, highlights, icons, diagnostics, undotree, todo, resume | LazyVim default | lazy | yes |
| snacks.nvim (explorer) | File explorer, `replace_netrw`. Override user: hidden+ignored=true, filter exclude `node_modules`/`.direnv` | LazyVim default + user override (`plugins/snacks-explorer.lua`) | lazy | yes |
| snacks.nvim (terminal) | Floating terminal `<c-/>`, `<leader>ft`/`fT`. User keymaps: `q`=hide, `gf` open file under cursor, double-`<esc>` → normal mode | LazyVim default + user override (`plugins/snacks.lua`) | lazy | yes |
| snacks.nvim (scratch) | Scratch buffer `<leader>.`, `<leader>S` | LazyVim default | lazy | yes |
| snacks.nvim (profiler) | Profiler `<leader>dpp`, `dph`, status di lualine | LazyVim default | lazy | yes |
| trouble.nvim | Panel diagnostics/symbols/quickfix/locations (`<leader>xx`, `<leader>cs`, `<leader>xX`, ...) | LazyVim default | lazy | yes |
| todo-comments.nvim | Highlight + picker TODO/FIXME (`<leader>st`, `]t`/`[t`) | LazyVim default | lazy | yes |
| persistence.nvim | Sesi restore (`<leader>qs`/`ql`/`qS`) | LazyVim default | lazy | yes |
| grug-far.nvim | Search & replace multi-file (`<leader>sr`) | LazyVim default | lazy | yes |
| nvim-sops (prismatic-koi) | Encrypt/decrypt .sops.yaml files saat BufEnter. **Versi kecil & niche — unsure update nixpkgs** | user config (`plugins/sops.lua`) | event BufEnter | yes |
| lazydev.nvim | Completion/config utk Neovim Lua development; user `nvim.lua` set `vim.g.lazydev_enabled=true` | LazyVim default + user flag | lazy (ft lua) | yes |
| SchemaStore.nvim | JSON/YAML schema store utk jsonls/yamlls | LazyVim default | lazy | yes |

### Extras editor yang aktif

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| dial.nvim | Increment/decrement pintar `<C-a>`/`<C-x>` (bool, tanggal, dst.) | active extra `editor.dial` | lazy | yes |
| inc-rename.nvim | Preview rename LSP live saat mengetik `<leader>cr` | active extra `editor.inc-rename` | lazy | yes |
| yanky.nvim | Yank history (`<leader>p`), put behavior indent-aware (`>p`, `=p`, `[y`/`]y` cycle) | active extra `coding.yanky` | lazy | yes |
| cmp-git | Completion git di commit message (issue/PR refs). NOTE: butuh nvim-cmp source; dgn blink.cmp kemungkinan tidak aktif. | active extra `lang.git` | lazy | yes |

---

## 3. LSP / Completion

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| nvim-lspconfig | Setup semua LSP server via `servers` table | LazyVim default + banyak user override | lazy (ft) | yes |
| blink.cmp | Completion engine (pengganti nvim-cmp). Override user: `keymap.preset="default"` (default LazyVim juga "default" — override ini no-op, mungkin sisa) | LazyVim default + user override (`plugins/blink.lua`) | eager (InsertEnter) | yes |
| friendly-snippets | Snippet collection | LazyVim default | lazy | yes |
| mason.nvim | **Dimatikan user** — Nix owns binaries, LSP resolve dari PATH | user config (`plugins/mason.lua`) | disabled | yes |
| mason-lspconfig.nvim | **Dimatikan user** | user config (`plugins/mason.lua`) | disabled | yes |

### Default LSP yang diset LazyVim (invis di config user):

- `vim.diagnostic.config`: underline, update_in_insert=false, virtual_text (spacing 4, prefix ●, source if_many), severity_sort, signs berikon.
- **Inlay hints: enabled** (kecuali vue) — `<leader>uh` toggle.
- Codelens: **disabled** — `<leader>cc`/`<leader>cC`.
- Folds: enabled (treesitter foldexpr).
- File operations: `didRename`/`willRename` capabilities → `<leader>cR` rename file.
- Keymaps semua server: `gd`, `gr`, `gI`, `gy`, `gD`, `K`, `gK`/`<c-k>` (signature), `<leader>ca` (code action), `<leader>cr` (rename), `<leader>cA` (source action), `<leader>cl` (Lsp info), `<leader>co` (organize imports), `<leader>cc` (codelens).
- `]]`/`[[`/`<a-n>`/`<a-p>` = next/prev reference via **Snacks.words** (bukan diagnostics!). ⚠️ User override `]]`/`[[` jadi diagnostic nav — bentrok yang ini.
- lua_ls defaults: hints on, callSnippet Replace, codeLens, doc privateName.

### Override LSP user per file:

| Nama | Yang diberikan | Sumber |
|---|---|---|
| `plugins/go.lua` | gopls: usePlaceholders=false, semua hints off, semua analisis ST1xxx + shadow off. nvim-lint: `linters_by_ft.go = {}` (matikan golangci-lint bawaan LazyVim) | user config |
| `plugins/lsp-keymaps.lua` | `]]`/`[[` = diagnostic nav prioritas error→warn→info→hint (semua server) | user config |
| `plugins/markdown.lua` | `marksman.enabled=false` (markdown via render-markdown + tanpa LSP) | user config |
| `plugins/tsc.lua` | `vtsls` & `tsgo` off, `tsc` (nvim tsc LSP) on — TypeScript pakai tsc type-checking | user config |
| `plugins/web-languages.lua` | `astro` + `svelte` servers on; svelte `<leader>co` organize imports; conform: astro/svelte → prettier | user config |
| `config/autocmds.lua` | Diagnostics off utk .env*/markdown/dockerfile | user config |

---

## 4. Language support (active extras `lang.*`)

| Extra / feature | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| lang.go | gopls, golangci-lint (nvim-lint), neotest-golang, treesitter go/gomod/gosum/gowork/gotmpl, DAP delve. User matikan golangci-lint | active extra + user override | lazy | yes (neotest-golang, gopls bin) |
| lang.typescript.tsc | tsc LSP (nvim-tsc), treesitter tsx/typescript. User: tsc on, vtsls/tsgo off | active extra + user override | lazy | yes |
| lang.typescript.biome | biome LSP + formatter/linter biomejs (biome-nls) | active extra | lazy | bin unsure (biome bin ada di nixpkgs; biome-language-server unsure) |
| lang.docker | dockerls + docker_compose_language_service, hadolint lint, treesitter dockerfile | active extra | lazy | yes |
| lang.json | jsonls + SchemaStore, treesitter json/json5, lint jsonlint? (conform) | active extra | lazy | yes |
| lang.yaml | yamlls + SchemaStore, treesitter yaml, yaml-comprehension? | active extra | lazy | yes |
| lang.toml | taplo LSP, treesitter toml | active extra | lazy | yes |
| lang.sql | vim-dadbod + vim-dadbod-completion + vim-dadbod-ui, sqls LSP, `<leader>D` DBUI | active extra | lazy | yes (ketiganya) |
| lang.tailwind | tailwindcss LSP + tailwind class completion; user suppress noice "No information available" | active extra + user override | lazy | yes (tailwindcss-language-server) |
| lang.markdown | marksman (user off), markdownlint-cli2 (nvim-lint), render-markdown.nvim, markdown-preview.nvim (`<leader>cp`, browser-based), treesitter markdown/markdown_inline | active extra + user override | lazy | yes (render-markdown-nvim, markdown-preview-nvim) |
| lang.nix | nil_ls LSP, conform nixfmt, nvim-lint statix, treesitter nix. ⚠️ Nixvim punya modul nix sendiri (nixd/nil options) | active extra | lazy | bin yes (nil, nixfmt, statix di nixpkgs top-level) |
| lang.git | treesitter git_config/gitcommit/git_rebase/gitignore/gitattributes, cmp-git, commit ft setup | active extra | lazy | yes |
| util.dot | bashls, shellcheck (mason — ⚠️ tidak jalan krn mason off), filetype rasi/waybar/mako/kitty/hypr/env, treesitter git_config/hyprlang/fish/rasi | active extra | lazy | yes |
| util.mini-hipatterns | mini.hipatterns: highlight hex color + **Tailwind CSS class color** (astro/css/html/js/rust/svelte/ts) | active extra | lazy (LazyFile) | yes |
| test.core | neotest + nvim-nio, `<leader>t` suite (run nearest/file/all, output, summary, watch) | active extra | lazy | yes |

---

## 5. Git & tools

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| gitsigns.nvim | Gutter signs (▎), hunk nav `]h`/`[h`, stage/reset hunk/buffer, blame line/buffer, diff this, select hunk (textobj `ih`) | LazyVim default | eager (BufRead) | yes |
| snacks.nvim (gitbrowse) | `<leader>gB`/`gY` open/copy repo URL | LazyVim default | lazy | yes |
| lazygit.nvim (kdheepak) | Wrapper `LazyGit` float, keymap `<leader>z`. ⚠️ **Duplikat** — LazyVim bawaan sudah `:LazyGit` via snacks (toggleterm/snacks terminal? LazyVim default `<leader>gg` = snacks lazygit) | user config (`plugins/lazygit.lua`) | lazy (cmd/keys) | yes |
| vim-dadbod + completion + ui | DB browser SQL (`<leader>D`) | active extra `lang.sql` | lazy | yes |

---

## 6. Formatter / Lint

| Nama | Yang diberikan | Sumber | Lazy | nixpkgs |
|---|---|---|---|---|
| conform.nvim | Formatting `<leader>cf`/`<leader>cF`, format on save (autocmd LazyVim). Per-ft dari extras: nix→nixfmt, astro/svelte→prettier (user) | LazyVim default + extras + user | lazy | yes |
| nvim-lint | Linting per-ft; user: go linters kosong | LazyVim default + user | lazy | yes |
| prettier (extra `formatting.prettier`) | prettierd + prettier, plus `vim.g.lazyvim_prettier_needs_config=true` (user set) — prettier hanya jalan kalau ada config | active extra | lazy | bin yes (prettierd, prettier) |
| golangci-lint | Dari lang.go; **user matikan** | active extra (disabled) | — | bin yes |
| hadolint | Dockerfile lint (lang.docker) | active extra | lazy | bin yes |
| markdownlint-cli2 | Markdown lint (lang.markdown) | active extra | lazy | bin yes |
| statix | Nix lint (lang.nix) | active extra | lazy | bin yes |
| shellcheck | Bash lint (util.dot; via mason — mati di Nix, harus dari PATH) | active extra | — | bin yes |

---

## 7. Default keymaps LazyVim (invis di config user — ringkas)

`<leader>`=`<space>`, `<localleader>`=`\`.

- **Window**: `<C-h/j/k/l>` move, `<C-Arrow>` resize, `<leader>-`/`<leader>|` split, `<leader>wd` close, `<leader>wm`/`uz` zoom/zen.
- **Buffer/tab**: `[b`/`]b`, `<S-h>`/`<S-l>`, `<leader>bd/bo/bi/bD/bb`, `<leader><tab>` suite.
- **Search/motion**: `n`/`N` centered, `<esc>` clear hlsearch, flash `s`/`S`/`r`/`R`, mini.ai textobjects.
- **Diagnostics** (LazyVim default): `]d`/`[d`, `]e`/`[e`, `]w`/`[w`, `<leader>cd` (line diagnostics), `<leader>xx` (Trouble). `]]`/`[[` default = next/prev **reference** (user ganti jadi diagnostic nav).
- **Toggle (`<leader>u`)**: `uf`/`uF` autoformat, `us` spell, `uw` wrap, `uL` rel number, `ud` diagnostics, `ul` line numbers, `uc` conceal, `uA` tabline, `uT` treesitter highlight, `ub` dark bg, `uD` dim, `ua` anim, `ug` indent, `uS` smooth scroll, `uh` inlay hints, `uC` colorschemes, `uZ` zoom.
- **Git**: `<leader>gl/gL/gf/gb/gB/gY`, gitsigns `<leader>ghs/ghr/ghS/ghu/ghR/ghp/ghb/ghB/ghd/ghD`, `ih` textobj.
- **LSP**: `gd gr gI gy gD K gK <c-k>`, `<leader>ca/cc/cC/cr/cR/cA/cl/co`, `<leader>ss/sS` symbols, `gai/gao` calls.
- **Files/picker (snacks)**: `<leader><space>` find, `<leader>/` grep, `<leader>,` buffers, `<leader>e/E` explorer, `<leader>ff/fF/fb/fc/fg/fp/fr/fR`, `<leader>s*` search suite (`sh` help, `sk` keymaps, `sd` diagnostics, `su` undotree, `st` todo, ...).
- **Format**: `<leader>cf`, `<leader>cF` (injected lang).
- **Misc**: `<C-s>` save, `<leader>K` keywordprg, `gco`/`gcO` comment, `<leader>qq` quit all, `<leader>l`/`<L>` Lazy/changelog, `<c-/>` terminal, `<leader>sr` grug-far, `<leader>dpp/dph/dps` profiler, `<leader>n` notification history.

### Override keymap user (config/keymaps.lua + autocmds.lua):

- `<C-S-v>` paste (semua mode), mouse: LeftRelease yank, MiddleMouse paste, `<C-LeftMouse>` goto-def, double/triple click yank, RightMouse popup, Alt+scroll horizontal, `vim.opt.mousefocus=true`.
- `]]`/`[[` diagnostic nav prioritas (juga via lsp-keymaps).
- Neovide: `<C-=>`/`<C-->` font size; options: opacity 0.7, blur, layer grouping.

### Default options LazyVim (invis — ringkas):

`vim.opt` set LazyVim: relativenumber, smart indent, `signcolumn=yes`, `updatetime`, `completeopt=menu,menuone,noselect`, `termguicolors`, foldmethod expr (treesitter), `foldlevelstart=99`, spell/wrap per-ft autocmd (markdown wrap+spell), `root_spec` (user override → `{cwd}`), `clipboard` (user override → `unnamedplus`), `tabstop` (user override → 4). User: `vim.g.lazyvim_prettier_needs_config=true`, OSC 52 clipboard saat SSH/HERDR.

### Override autocmd user:

- Diagnostics off: `.env*`, markdown, dockerfile.
- TS/JS tabstop 4 (autocmds).
- (keymaps mouse — di atas).

---

## 8. Catatan nixpkgs

Semua plugin di atas **ada di nixpkgs vimPlugins** kecuali:
- `goimpl.nvim` (edolphin-ydf) — tidak ada → perlu fetchPinned/buildLua.
- Versi kecil `nvim-sops` (prismatic-koi) — **ada** di nixpkgs, tapi versi bisa beda.
- Binari LSP/lint/formatter (nixd/nil/nixfmt/statix/hadolint/prettierd/shellcheck/delve/golangci-lint/tailwindcss-language-server dll.) ada di nixpkgs top-level — di nixvim-config cara pasangnya lewat modul nixvim (`plugins.lsp.servers.*`), bukan mason.
- treesitter grammars: nixvim `plugins.treesitter` pakai `nvim-treesitter.builtGrammars` — semua grammar dari nix, config lama sudah set `ensure_installed = {}` + `build = false` (pola `dir = stdpath data /nix/...` — di nixvim-config tidak perlu dir hack).

## 9. ⚠️ Konflik / catatan migrasi (fakta, bukan rekomendasi)

1. `]]`/`[[`: LazyVim default = next/prev reference (Snacks.words); user = diagnostic nav. Kalau keymap user di-drop, behavior berubah jadi reference jump.
2. `<leader>z` (user lazygit.nvim) vs LazyVim default `<leader>gg` lazygit via snacks — dua jalur lazygit.
3. Mason off + util.dot minta shellcheck via mason → shellcheck tidak pernah terpasang dari LazyVim; hanya jalan kalau ada di PATH.
4. cmp-git extra butuh nvim-cmp; stack aktif adalah blink.cmp → kemungkinan cmp-git tidak berfungsi.
5. gopls hints/analisis dimatikan massal (go.lua) — konfigurasi nyata yang tidak terlihat kalau hanya lihat nama server.
6. `vim.g.lazyvim_prettier_needs_config=true` — prettier tidak auto-format tanpa config; format on save masih jalan utk formatter lain (nixfmt).
