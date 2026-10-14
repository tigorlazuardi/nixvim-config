# nixvim-config

Module flake Nixvim yang membawa config Neovim kesukaan owner ke semua consumer (host home-manager), dengan default yang bisa di-override per mesin. Lazy loading via lz.n tanpa lazy.nvim runtime; plugin di-pin granular via flake input per plugin.

## Language

**Consumer**:
Host/mesin home-manager yang meng-import `homeManagerModules.default` dari flake repo ini dan menerima seluruh config default. Bisa meng-override nilai apa pun yang dibungkus `mkDefault` pada namespace yang sama (`programs.nixvim.*`).
_Avoid_: user, client, host (pakai `consumer` untuk konteks module ini)

**Plugin module**:
Satu file di `modules/plugins/<name>.nix` yang mendeklarasikan satu plugin: flake input sumbernya, `plugins.<name>.package` (buildVimPlugin dari input), trigger lazy load, dan settings. Organisasi file saja — tidak membuat option tree baru.

**Granular pinning**:
Skema dependency di mana setiap plugin adalah flake input sendiri (`flake = false`) yang dibangun via `buildVimPlugin`, sehingga bisa di-update per plugin (`nix flake lock --update-input <plugin>`) tanpa menyentuh plugin lain.

**Banderol update**:
Update yang membawa semua plugin sekaligus karena bersumber dari satu input (nixpkgs). Dihindarkan sebagai alur utama; masih dipakai untuk binary non-plugin (LSP server, formatter) secara default.

**Base config**:
Config non-plugin yang dibawa module — opts, globals, keymaps, autocmds, clipboard, colorscheme — pindahan dari `dotfiles/nixos/shared/home-manager/nixvim/`.

**Repo owner**:
Pemilik repo ini; menentukan config default yang dibawa ke semua consumer. Berbeda dari consumer meskipun orangnya sama.
