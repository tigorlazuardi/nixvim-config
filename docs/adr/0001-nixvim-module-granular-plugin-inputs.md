# Nixvim module dengan granular penuh via flake input per plugin

Context: prioritas user adalah dependencies stabil dengan update per-plugin — nixpkgs `vimPlugins.*` hanya bisa di-update banderol (ikut bump input nixpkgs), dan binary (LSP server, formatter) kadang butuh versi lebih baru dari yang nixpkgs kasih. Vanilla flake (tanpa nixvim) sempat dipertimbangkan karena alasan ini, tapi dibatalkan: kita tetap pakai nixvim module (`programs.nixvim`) karena validasi eval-time, helper opsi, dan base config dotfiles yang sudah format nixvim (zero porting). Kelemahan update banderol dijawab dengan granular penuh: setiap plugin yang di-keep jadi flake input sendiri (`flake = false`), dibangun via `buildVimPlugin` dengan versi dari rev input, diarahkan ke `plugins.<name>.package` — update per plugin: `nix flake lock --update-input <plugin>`. Binary non-plugin default nixpkgs via `extraPackages`, semua `mkDefault` sehingga consumer bebas override.

Status: accepted (2026-10-14)

## Considered Options

- **Vanilla flake.nix + lz.n native** — kontrol penuh, satu file lockfile, tapi kehilangan validasi eval-time dan helper; butuh translate manual base config dotfiles. Rejected: biaya migrasi tidak sebanding, mekanisme lazy load identik (lz.n → packadd), snappiness sama.
- **Bundle nixpkgs murni** — paling stabil (versi ter-tes bersama), tapi update banderol. Rejected: melanggar kebutuhan update per-plugin.
- **Hybrid selektif** (default nixpkgs, input sendiri selektif) — ditolak user; user mau granular penuh dan siap kelola risiko kompatibilitas antar plugin sendiri.

## Consequences

- User menjadi tester kompatibilitas antar plugin: update `nvim-treesitter` tanpa grammars (atau sebaliknya) rawan patah — treesitter perlu dikoordinasi saat update.
- `flake.lock` dan `flake.nix` besar (satu input per plugin); per-plugin selective update adalah alur normal.
- Versi plugin baru tersedia langsung dari upstream, tidak menunggu nixpkgs.
