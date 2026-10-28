# Headless boot: init.lua must generate, evaluate, and exit clean
# with zero startup output, and the lz.n lazy trigger must load
# the pilot colorscheme.
{ pkgs, nvim }:
pkgs.runCommand "nvim-headless-boot"
  {
    inherit nvim;
  }
  ''
    export HOME=$(mktemp -d)
    output=$("$nvim/bin/nvim" --headless "+qa" 2>&1)
    if [ -n "$output" ]; then
      echo "nvim startup produced output:"
      echo "$output"
      exit 1
    fi
    # lz.n colorscheme trigger must actually load tokyonight.
    output=$("$nvim/bin/nvim" --headless \
      -c "colorscheme tokyonight" \
      -c "lua assert(vim.g.colors_name and vim.g.colors_name:find('^tokyonight'), 'not applied: '..tostring(vim.g.colors_name)); print('LAZY_TRIGGER_OK')" \
      +qa 2>&1)
    printf '%s\n' "$output" | grep -q '^LAZY_TRIGGER_OK$' || {
      echo "lz.n lazy trigger did not load tokyonight:"
      printf '%s\n' "$output"
      exit 1
    }
    if printf '%s\n' "$output" | grep -v '^LAZY_TRIGGER_OK$' | grep -q .; then
      echo "lazy-trigger run produced unexpected output:"
      printf '%s\n' "$output"
      exit 1
    fi
    touch $out
  ''
