{ pkgs, nvim }:
pkgs.runCommand "nvim-rust-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p/src && cd $HOME/p
    git init -q
    printf '[package]\nname = "x"\nversion = "0.1.0"\nedition = "2021"\n' > Cargo.toml
    printf 'fn main() {\n    let x:i32=1;\n    let _y: u8 = "s";\n    let _ = x;\n}\n' > src/main.rs
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function main()
      vim.cmd("edit src/main.rs")
      -- the crash from the bug report: FileType must find a rust parser
      ok(vim.treesitter.language.add("rust"), "rust parser")
      ok(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil, "treesitter highlight active")
      ok(vim.wait(60000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" }) > 0 end, 100), "rust_analyzer attach")
      ok(vim.wait(90000, function() return #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR }) > 0 end, 200), "type error diagnostic")
      local s = vim.lsp.get_clients({ bufnr = 0, name = "rust_analyzer" })[1].config.settings["rust-analyzer"]
      ok(s.check.command == "clippy" and s.cargo.allFeatures == true, "LazyVim settings")
      for _, b in ipairs({ "cargo", "rustc", "rustfmt", "cargo-clippy" }) do ok(vim.fn.executable(b) == 1, "binary " .. b) end
      require("lz.n").trigger_load("conform.nvim")
      ok(vim.tbl_contains(require("conform").list_formatters_for_buffer(0), "rustfmt"), "conform rustfmt")
      -- Cargo.toml still goes to taplo
      vim.cmd("edit Cargo.toml")
      ok(vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0, name = "taplo" }) > 0 end, 100), "taplo on Cargo.toml")
      io.stdout:write("RUST_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 200 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q RUST_OK
    touch $out
  ''
