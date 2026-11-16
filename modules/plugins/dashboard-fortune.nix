# Snacks dashboard header = `fortune | cowsay`, picked ONCE per nvim start
# (not per render): ~50% wisdom/science/dev quotes, ~50% rude ones (fortune
# off/*). Falls back to the static TIGOR banner if fortune/cowsay fail.
# Not a module: snacks.nix imports it for the header section (snacks `settings`
# is one mkDefault block, so a second module setting a key would drop the rest).
# Tall cows (dragon, stegosaurus, elephant) are left out: they push the menu off screen.
# ponytail: fixed pools; make configurable when a second consumer wants other sets.
# Skipped on purpose: off/{racism,misogyny,misandry,hphobia,ethnic,sex,religion,
# atheism,limerick} (hateful/sexual) and off/fortunes (suicide jokes).
{ lib, pkgs }:
let
  fortune = pkgs.fortune.override { withOffensive = true; };
  dir = "${fortune}/share/games/fortunes";
  luaList = xs: "{ " + lib.concatMapStringsSep ", " (x: ''"${x}"'') xs + " }";
  nice = [
    "wisdom"
    "tao"
    "science"
    "literature"
    "humorists"
    "computers"
    "linux"
  ];
  rude = [
    "off/vulgarity"
    "off/black-humor"
    "off/knghtbrd"
    "off/miscellaneous"
  ];
  cows = [
    "default"
    "tux"
    "koala"
    "moose"
    "sheep"
    "turtle"
    "vader"
    "bunny"
    "kitty"
    "llama"
    "fox"
    "alpaca"
  ];
in
{
  # Dashboard section: a function evaluated lazily on first render, then cached.
  __raw = ''
    (function()
      local cached -- nil = not computed yet, false = failed (use static banner)
      return function()
        if cached == nil then
          cached = false
          math.randomseed(vim.uv.hrtime())
          local function pick(t) return t[math.random(#t)] end
          local pool = math.random() < 0.5 and ${luaList nice} or ${luaList rude}
          local cmd = string.format(
            "%s -s %s/%s | %s -W 48 -f %s",
            "${fortune}/bin/fortune", "${dir}", pick(pool),
            "${pkgs.cowsay}/bin/cowsay", pick(${luaList cows})
          )
          -- Any failure (timeout, missing binary, nil result) keeps the static
          -- banner: the dashboard must never error.
          local ok, res = pcall(function()
            return vim.system({ "sh", "-c", cmd }, { text = true, timeout = 3000 }):wait()
          end)
          if ok and type(res) == "table" and res.code == 0 and res.stdout and res.stdout:match("%S") then
            local out = res.stdout:gsub("\t", "    ")
            local lines = vim.split(vim.trim(out), "\n")
            local w = 0
            for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l)) end
            for i, l in ipairs(lines) do
              lines[i] = l .. string.rep(" ", w - vim.fn.strdisplaywidth(l))
            end
            cached = table.concat(lines, "\n")
          end
        end
        return { header = cached or Snacks.config.dashboard.preset.header, padding = 2 }
      end
    end)()
  '';
}
