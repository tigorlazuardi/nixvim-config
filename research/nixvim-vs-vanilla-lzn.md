# Riset #2: Apakah nixvim dibutuhkan? — nixvim vs vanilla flake.nix + lz.n native

Tanggal: 2026-10-14 · Issue: [#2](https://github.com/tigorlazuardi/nixvim-config/issues/2) · Lanjutan riset di `HANDOVER.md`

## Jawaban singkat

**lz.n bisa dipakai native tanpa nixvim** — bahkan itu adalah use case yang
dirancang oleh upstream lz.n sendiri. README lz.n menyatakan library ini
ditujukan untuk *"users of plugin managers that don't provide a convenient API
for lazy-loading (`vim.pack`, `nix`, `paq-nvim`, ...)"*, dan menyediakan contoh
resmi untuk home-manager `programs.neovim`.

Jadi pertanyaannya bukan "bisa atau tidak", melainkan trade-off ergonomi.
Rekomendasi akhir: **tetap nixvim** (status quo di `HANDOVER.md`), dengan alasan
utama biaya migrasi ≈ nol untuk base config yang sudah ada dan validasi
eval-time. Vanilla hanya menang di kecepatan eval Nix dan granularitas update
per plugin — dua-duanya bisa diatasi di jalur nixvim (lihat hybrid di bawah).

## 1. Wiring lz.n native dengan home-manager `programs.neovim`

Fakta yang diverifikasi:

- nixpkgs sudah packagelz.n: `pkgs.vimPlugins.lz-n` (3.1.1 saat riset).
  lz.n sekarang di-host di `lumen-oss/lz.n` (pindah dari `nvim-neorocks`).
- Prasyarat: Neovim ≥ 0.10 (cek runtime `nvim-0.10.0`); README menarget 0.12.
- lz.n **bukan plugin manager** — ia hanya lazy-load plugin yang *sudah* ada di
  `packpath`. Default load function: `vim.cmd.packadd`.
- home-manager `programs.neovim` (diverifikasi dari source modul
  `modules/programs/neovim/default.nix`):
  - Semua plugin masuk satu packdir `pack/hm`, di-link ke
    `~/.local/share/nvim/site/pack/hm`.
  - `optional = true` → plugin ditaruh di `pack/hm/opt/<nama>` (tidak diload
    saat startup; dimuat via `packadd`).
  - Field `config` + `type = "lua"` dari **setiap** entry plugin digabungkan
    (`generatedConfigs.lua`) dan ditulis ke `init.lua` — **dijalankan saat
    startup**, bukan saat packadd. Ini kunci wiring: saat startup kita hanya
    *mendaftarkan spec* ke lz.n; plugin belum di-packadd.

Pola wiring (contoh resmi dari README lz.n, jalur home-manager):

```nix
{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins [
      lz-n
      {
        plugin = pkgs.vimPlugins.telescope-nvim;
        config = ''
          require("lz.n").load {
            "telescope.nvim",
            cmd = "Telescope",
            after = function() require("telescope").setup {} end,
          }
        '';
        type = "lua";
        optional = true;
      }
      {
        plugin = pkgs.vimPlugins.sweetie-nvim;
        config = ''
          require("lz.n").load {
            "sweetie.nvim",
            colorscheme = "sweetie",
          }
        '';
        type = "lua";
        optional = true;
      }
    ];
  };
}
```

Alternatif lebih rapi: plugin semua `optional = true` tanpa config, semua spec
lz.n dikumpulkan di satu tempat (`extraLuaConfig` / file `lua/plugins/*.lua`
via `plugins.<x>.runtime`), lalu satu panggilan
`require("lz.n").load("plugins")` — lz.n mendukung spec multi-file
(`lua/plugins/*.lua` di-merge otomatis).

Gotchas jalur native (sama dengan yang tercatat di `HANDOVER.md`, karena
sumbernya lz.n itu sendiri):

- Nama di spec **harus** match nama folder di `pack/hm/opt/<nama>` (umumnya
  repo name), karena default load adalah `packadd <nama>`.
- Tidak ada `dependencies` otomatis — pakai `trigger_load` di hook `before`.
- nvim-cmp + source (yang pakai `after/plugin`) bermasalah dengan `packadd`
  pasca-startup; rekomendasi upstream: bundling atau `rtp.nvim`, atau pindah
  ke blink.cmp.

## 2. Tabel perbandingan

| Aspek | Nixvim (`programs.nixvim` + lz.n provider) | Vanilla (flake.nix + HM `programs.neovim` + lz.n native) |
|---|---|---|
| lz.n lazy loading | ✅ `plugins.<x>.lazyLoad` dirutekan ke lz.n; setup code auto-dibungkus jadi hook `after` | ✅ Native, pola resmi README; spec ditulis manual (Lua) |
| Trigger yang tersedia | Sama persis (cmd/ft/event/keys/colorscheme) — provider-nya lz.n | Sama persis |
| Opsi typed + validasi | ✅ Eval-time: salah nama opsi = error build | ❌ Nix string → typo Lua & opsi salah ketik = error runtime (atau diam-diam) |
| Helpers colorschemes | ✅ ~100+ modul `colorschemes.*`, trigger `colorscheme` otomatis | Pakai `vimPlugins.<colorscheme>` biasa + spec `colorscheme = ...` — tetap bisa, tapi tanpa typed opsi |
| Helpers LSP | ✅ `lsp.servers.<name>.enable`, wiring server otomatis | Manual: nvim-lspconfig diLua + server di `extraPackages` (atau mason — tapi mason = runtime download, anti-lockfile) |
| Treesitter grammars | ✅ `plugins.treesitter.settings` + grammar dari nixpkgs | Tetap bagus tanpa nixvim: `pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [...])` — helper ini milik nixpkgs, bukan nixvim |
| Packaging kualitas | vimPlugins nixpkgs + passthrough | Sama — sumbernya nixpkgs juga, kecuali pakai flake input per plugin |
| Plugin di luar nixpkgs | flake input → `extraPlugins` (sama saja) | flake input → entry `plugins` (sama saja) |
| Ketersediaan plugin baru | Tunggu nixpkgs, atau flake input | flake input langsung dari upstream — lebih cepat |
| Lockfile | ✅ flake.lock (nixvim + nixpkgs) | ✅ flake.lock (nixpkgs + per-plugin inputs) |
| Update flow | Bump nixpkgs = semua plugin ikut sekali jalan (granularitas per-plugin via flake input saja); + churn opsi nixvim antar rilis | `nix flake update <input>` per plugin — granular; tapi banyak input = lock besar & compat dep (mis. telescope↔plenary) jadi tanggungan manual |
| Kecepatan eval Nix | Berat — modul nixvim besar, eval bisa puluhan detik | Ringan — hanya HM + wrapper neovim |
| Ukuran / kompleksitas input | nixvim + nixpkgs (+ HM) | nixpkgs (+ HM) + N input plugin |
| Keterbacaan | Tersebar di banyak opsi module, ada "magic" indirection (auto-config → `after` hook) | Satu flake.nix (+ file lua), semuanya eksplisit |
| Snappiness (lazy load) | Setara — mekanisme identik (lz.n/packadd) | Setara |
| Migrasi dari repo kosong + base config dotfiles | **≈ nol** — `autocmds.nix`, `keymaps.nix`, `opts.nix`, `git.nix`, `clipboard.nix`, `neovide.nix` di `~/dotfiles/nixos/shared/home-manager/nixvim/` sudah format `programs.nixvim.*`, tinggal di-import | Terjemahan manual ke Lua: `opts.nix` → tabel `vim.opt`, `keymaps.nix` → `vim.keymap.set`, `autocmds.nix` → `nvim_create_autocmd` + augroup; ~setengah hari untuk base, risiko typo runtime |
| Migrasi plugin berat | Per-deklarasi `lazyLoad.settings` (lihat `HANDOVER.md`) | Per-spec Lua manual; LSP & completion jadi bagian paling berat |

### Catatan "lockfile tunggal"

Klaim "satu flake.nix sebagai lockfile tunggal" di jalur vanilla sedikit
menyesatkan: lockfile-nya tetap `flake.lock`. Yang benar-benar berubah:

- **nixvim path**: 1 input besar (nixvim) + nixpkgs. Plugin dari nixpkgs ikut
  bump nixpkgs — tidak bisa update telescope saja kalau pluginnya dari
  `vimPlugins.*`.
- **vanilla path**: N input kecil per plugin. Bisa `nix flake update
  telescope-nvim` selective. Tapi setiap input juga punya
  lock entry-nya sendiri, dan update semuanya = resolve N+1 repos.

Keduanya **setara di jaminan reproduksibilitas** — tidak ada lazy-lock.json di
kedua jalur. Perbedaannya murni granularitas update dan jumlah churn input.

## 3. Dampak ke prioritas user

- **Snappiness**: tidak ada pemenang. Mekanisme lazy load identik (lz.n →
  `packadd`). Nixvim hanya menambah overhead eval-time Nix (build lebih lambat
  terasa), bukan runtime nvim.
- **Stabilitas dependency**: setara. flake.lock mengikat semua di kedua jalur.
  Risiko konflik lebih besar di jalur nixvim **antar-rilis nixvim** (opsi
  berubah, ada breaking change) — tapi ini terkendali dengan tidak bump
  nixvim sering. Jalur vanilla risikonya kompatibilitas antar-plugin saat
  update selective (mis. bump telescope tanpa plenary).

## 4. Biaya migrasi (dari repo kosong)

1. **nixvim path**: bootstrap flake (input nixvim + HM) + import 6 file dotfiles
   yang sudah format nixvim → porsi besar kerja hanya di wiring plugin
   `lazyLoad` per plugin dan LSP. Estimasi paling kecil.
2. **vanilla path**: bootstrap flake + terjemahan manual base config ke Lua +
   spec lz.n per plugin + LSP manual. Estimasi 1–2 hari untuk paritas, dengan
   utang jangka panjang: tidak ada validasi eval-time, jadi setiap edit
   diverifikasi manual (`nvim --headless +qa`).

## 5. Rekomendasi: **nixvim** (dengan hybrid untuk plugin di luar nixpkgs)

Alasan:

1. **Base config sudah nixvim format** — migrasi ≈ nol vs terjemahan manual
   yang rentan typo dan tidak tervalidasi.
2. **Validasi eval-time** adalah nilai nyata untuk config yang mau dijaga
   stabil jangka panjang (tujuan utama migrasi dari LazyVim di `HANDOVER.md`).
3. **Kekurangan vanilla yang paling sering diklaim** (update granular, plugin
   cepat dari upstream) tidak benar-benar hilang di nixvim: plugin di luar
   nixpkgs tetap bisa sebagai flake input → `extraPlugins` /
   `plugins.<name>.package`, ter-pin di flake.lock yang sama.
4. lz.n native tanpa nixvim tetap **layak dan didukung upstream** — jadi kalau
   suatu saat eval-time nixvim terasa menyakitkan atau opsi-nya terlalu
   menyulitkan, jalur vanilla terbuka; base config di dotfiles adalah aset
   yang harus diterjemahkan ulang saat itu.

Kapan vanilla jadi pilihan yang lebih baik: kalau target adalah config yang
99% hand-written Lua (bukan opsi module), jumlah plugin sedikit, dan
kecepatan eval Nix / kesederhanaan input lebih dihargai daripada typed
options. Saat ini belum kasusnya.

## 6. Contoh config minimal jalur rekomendasi (nixvim + lz.n)

```nix
# flake.nix (inti)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim.url = "github:nix-community/nixvim";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Plugin di luar nixpkgs → input sendiri, tetap di-lock:
    grug-far-nvim.url = "github:MagicDuck/grug-far.nvim";
  };
}
```

```nix
# modul nixvim
{
  programs.nixvim = {
    enable = true;

    # Base config dari dotfiles — sudah format programs.nixvim:
    # imports = [ ../nixvim/opts.nix ../nixvim/keymaps.nix ../nixvim/autocmds.nix ... ];

    plugins.lz-n.enable = true;

    # Plugin dari nixpkgs:
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

    # Plugin di luar nixpkgs — flake input, tetap ter-pin di flake.lock:
    extraPlugins = [ inputs.grug-far-nvim.packages.${pkgs.system}.default ];
    plugins.grug-far = {
      enable = true;
      package = inputs.grug-far-nvim.packages.${pkgs.system}.default;
      lazyLoad.settings.cmd = "GrugFar";
    };
  };
}
```

## Sumber

- lz.n README (lumen-oss/lz.n, eks nvim-neorocks) — bagian "Nix (Home Manager)
  example", "Comparison with lazy.nvim", "Plugin dependencies":
  https://github.com/lumen-oss/lz.n
- home-manager `modules/programs/neovim/default.nix` — packdir `pack/hm`,
  `optional`, agregasi `config` per `type` ke `init.lua`:
  https://github.com/nix-community/home-manager/blob/master/modules/programs/neovim/default.nix
- nixpkgs `vimPlugins.lz-n` (diverifikasi `nix eval`, 3.1.1)
- `HANDOVER.md` repo ini — riset lazyLoad + lz.n provider nixvim (2026-10-14)
- Base config existing: `~/dotfiles/nixos/shared/home-manager/nixvim/`
  (default.nix, opts.nix, keymaps.nix, autocmds.nix, git.nix, clipboard.nix,
  neovide.nix — semua format `programs.nixvim.*`)
