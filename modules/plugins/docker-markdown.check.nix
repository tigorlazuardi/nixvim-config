{ pkgs, nvim }:
pkgs.runCommand "nvim-docker-markdown-behaviour"
  {
    inherit nvim;
    nativeBuildInputs = [ pkgs.git ];
  }
  ''
    export HOME=$(mktemp -d)
    mkdir -p $HOME/p && cd $HOME/p
    git init -q
    printf 'FROM alpine\nRUN apk add curl\n' > Dockerfile
    printf 'services:\n  a:\n    image: x\n' > compose.yaml
    printf '# Title\n\n```lua\nx=1\n```\n' > r.md
    cat > $HOME/probe.lua <<'LUA'
    local function ok(c, m) if not c then error("FAIL: " .. m) end end
    local function has(name)
      return vim.wait(20000, function() return #vim.lsp.get_clients({ bufnr = 0, name = name }) > 0 end, 100)
    end
    local function main()
      ok(package.loaded["render-markdown"] == nil, "render-markdown lazy at start")
      vim.cmd("edit Dockerfile")
      ok(has("dockerls"), "dockerls attaches to Dockerfile")
      vim.cmd("edit compose.yaml")
      ok(vim.bo.filetype == "yaml.docker-compose", "compose filetype")
      ok(has("docker_compose_language_service"), "compose LS attaches to compose.yaml")
      vim.cmd("edit r.md")
      ok(vim.bo.filetype == "markdown", "markdown ft")
      ok(package.loaded["render-markdown"] ~= nil, "render-markdown loads on markdown buffer")
      ok(vim.fn.maparg("<leader>cp", "n") ~= "", "<leader>cp mapped")
      ok(vim.fn.maparg("<leader>um", "n") ~= "", "<leader>um render toggle mapped")
      ok(vim.fn.exists(":MarkdownPreviewToggle") == 2, "MarkdownPreviewToggle exists")
      vim.wait(1500)
      ok(#vim.lsp.get_clients({ bufnr = 0, name = "marksman" }) == 0, "marksman not attached")
      ok(vim.lsp.config.marksman == nil or not vim.lsp.is_enabled("marksman"), "marksman not enabled")
      io.stdout:write("DM_OK\n")
    end
    local good, err = xpcall(main, debug.traceback)
    if not good then io.stdout:write(tostring(err) .. "\n") end
    vim.cmd(good and "qa!" or "cquit")
    LUA
    res=$(timeout 150 "$nvim/bin/nvim" --headless -S $HOME/probe.lua 2>&1) || true
    printf '%s\n' "$res"
    printf '%s\n' "$res" | grep -q DM_OK
    touch $out
  ''
