# HANDOVER — nixvim-config

## Context

Migrasi config Neovim dari **LazyVim** (dikelola via repo `nix-neovim-config`) ke
**nixvim** (https://github.com/nix-community/nixvim). Motivasi utama:

1. **LazyVim tidak bisa proper lockfile** — lazy.nvim menulis `lazy-lock.json` saat
   runtime, drift & sulit direproduksi lewat Nix.
2. Config sering error — management overhead tinggi (spec Lua string di Nix,
   update semi-manual, interop Nix ↔ lazy.nvim rapuh).

Keputusan: config baru berbasis nixvim, plugin di-pin lewat **flake.lock** (Nix),
lazy loading via **`plugins.<name>.lazyLoad` + lz.n** — tanpa lazy.nvim runtime.

## Hasil riset lazy plugin loading (2026-10-14)

### Mekanisme built-in nixvim

Nixvim punya lazy loading per-plugin via opsi `plugins.<nama>.lazyLoad`.
Konfigurasinya dirutekan ke **provider** lazy-loading; satu-satunya provider yang
didukung saat ini: **[lz.n](https://github.com/nvim-neorocks/lz.n)**
(`plugins.lz-n.enable = true`). lz.n sendiri di-load paling awal
(`extraConfigLuaPre`) supaya trigger dihormati.

Ketika lazy loading aktif, generated setup code dari
`plugins.<nama>.luaConfig.content` otomatis dibungkus jadi fungsi `after` milik
lz.n — jalan pas trigger terpenuhi. Jadi **tidak perlu pindah setup config** ke
tempat lain.

### Trigger yang tersedia (`lazyLoad.settings`)

| Opsi | Isi | Contoh |
|---|---|---|
| `cmd` | command | `"GrugFar"`, `["Telescope"]` |
| `ft` | filetype | `"markdown"`, `["tex"]` |
| `event` | autocmd event | `"BufEnter *.lua"`, `["DeferredUIEnter"]` |
| `keys` | keymap (mode `n` default) | `"<leader>tg"`, atau spec `{ __unkeyed-1 = "<leader>ff"; __unkeyed-2 = "<cmd>..."; desc = "..."; }` |
| `colorscheme` | khusus colorscheme | dipasang otomatis dari `colorscheme = "<nama>"` top-level |
| `before` / `after` | Lua fn | sebelum/sesudah load; **`after` override default** (bukan extend) |
| `enabled` | bool / Lua fn | kondisional |
| `priority` | int | khusus startup (non-lazy) plugin |

### Colorscheme

```nix
{
  colorscheme = "catppuccin";
  colorschemes.catppuccin = {
    enable = true;
    lazyLoad.enable = true; # trigger `colorscheme` dipasang otomatis
    luaConfig.post = ''require("lz.n").trigger_load("bufferline.nvim")'';
  };
}
```

Integrasi pasca-setup pakai `luaConfig.post`, **bukan** override
`lazyLoad.settings.after`.

### Dependencies

lz.n TIDAK auto-load dependency. Kalau plugin butuh dep diload dulu:

```nix
lazyLoad.settings = {
  keys = [ "<leader>du" ];
  before.__raw = ''
    function() require("lz.n").trigger_load("nvim-dap") end
  '';
};
```

Atau deklarasi dep sebagai plugin normal dengan trigger sendiri, lalu
`trigger_load` manual. Di lazy.nvim ada `dependencies = [...]`; di jalur lz.n
tidak ada — tangani eksplisit.

### Pinning / lockfile

- Plugin datang dari **nixpkgs** (`vimPlugins.*`) — ter-pin via `flake.lock`.
- Plugin di luar nixpkgs: jadi flake input sendiri (satu input per plugin) dan
  dilempar via `extraPlugins` / `plugins.<name>.package` — semua masuk
  `flake.lock`.
- Tidak ada lockfile runtime. Reproducibility = `flake.lock`.

### Gotchas

- **`lazyLoad.settings.after` adalah override**: sekali di-set, default
  auto-generated Nixvim diganti total (bukan dibungkus). Untuk kode tambahan
  pasca-setup pakai `luaConfig.post`.
- **Pilih satu jalur**: jangan campur `lazyLoad` (lz.n) dengan spec
  `plugins.lazy` (lazy.nvim) di config yang sama.
- `plugins.lazy` (wrapper lazy.nvim) tetap ada di nixvim (`plugins.lazy.enable`,
  `plugins.lazy.plugins = [...]` dengan field `lazy`/`event`/`cmd`/`ft`/`keys`/
  `cond`/`dependencies`/`init`/`opts`) — tapi ini justru masukin kembali masalah
  lazy.nvim. Tidak dipakai di repo ini.
- Lazy-load hanya plugin berat yang jelas (telescope, treesitter, formatter,
  dap UI). Core/LSP client yang dibutuhkan global biarkan eager.
- lz.n load via `vim.cmd.packadd` — nama plugin di spec harus match folder
  `pack/opt/<name>` (umumnya repo name).

### Contoh minimal

```nix
{
  plugins.lz-n.enable = true;

  plugins.telescope = {
    enable = true;
    lazyLoad.settings = {
      cmd = "Telescope";
      keys = [{
        __unkeyed-1 = "<leader>ff";
        __unkeyed-2 = "<cmd>Telescope find_files<cr>";
        desc = "Find files";
      }];
    };
  };

  plugins.treesitter = {
    enable = true;
    lazyLoad.settings.event = [ "BufReadPost" "BufNewFile" ];
  };

  plugins.conform-nvim = {
    enable = true;
    lazyLoad.settings.event = [ "BufWritePre" ];
  };
}
```

## Sumber

- Nixvim lazy loading guide:
  https://nix-community.github.io/nixvim/user-guide/lazy-loading
- lz.n wrapper source:
  https://github.com/nix-community/nixvim/blob/main/plugins/pluginmanagers/lz-n.nix
- lazy.nvim wrapper source (tidak dipakai):
  https://github.com/nix-community/nixvim/blob/main/plugins/pluginmanagers/lazy.nix
- lz.n upstream spec:
  https://github.com/nvim-neorocks/lz.n#plugin-spec
- lazy.nvim lazy-loading spec (referensi semantik trigger):
  https://lazy.folke.io/spec/lazy_loading

## Roadmap implementasi

1. Bootstrap flake: input `nixvim` (nix-community/nixvim) + `home-manager`,
   target module nixvim yang dipasang ke `programs.nixvim`.
2. Port config LazyVim → nixvim bertahap: options/globals/keymaps dulu
   (mapping 1:1), lalu LSP, lalu plugins berat (lazyLoad per plugin).
3. Disable/hapus nix-neovim-config dari home-manager setelah paritas.
4. Validasi: `nix eval` + boot nvim headless
   (`nvim --headless "+Lazy! check" +qa` padanannya di sini: `nvim --headless +qa`)
   untuk memastikan tidak ada error startup.

## Cara pakai (consumer / cutover)

Repo ini mengekspor satu Home Manager module: `homeManagerModules.default`.

```nix
# flake.nix consumer
inputs.nixvim-config = {
  url = "github:tigorlazuardi/nixvim-config";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};

# home-manager module
imports = [ inputs.nixvim-config.homeManagerModules.default ];
```

- Modul sudah meng-import `nixvim.homeModules.nixvim` sendiri, dan menyalakan `programs.nixvim` + `defaultEditor`.
  Tidak perlu `programs.neovim.enable`. `viAlias`/`vimAlias` tidak dinyalakan (set `programs.nixvim.viAlias = true;` bila perlu).
- Semua nilai konsumen-tunable `mkDefault`: override dengan menyetel path `programs.nixvim.*` yang sama.
- Binary neovim = `config.programs.nixvim.build.package` (init sudah ter-bake via `wrapRc`).
- Update satu plugin: `nix flake update <nama-input>` di repo ini lalu push, lalu `nix flake update nixvim-config` di consumer.
- Jangan pakai bersama `programs.neovim` atau `inputs.nix-neovim-config.homeModules.default` pada user yang sama (bentrok `EDITOR`/`nvim`).
- Neovide + font JetBrains Mono ikut terpasang lewat `home.packages` dan `fonts.fontconfig.enable` di modul ini.
- Verifikasi di repo ini: `nix flake check` dan `nix build .#default` lalu `result/bin/nvim`. Check hidup di samping modulnya: `modules/**/<nama>.check.nix` (bentuk `{ pkgs, nvim }: pkgs.runCommand ...`) otomatis jadi `checks.<system>.nvim-<nama>`. Plugin baru: `<nama>.nix` + `<nama>.check.nix` bersebelahan.
