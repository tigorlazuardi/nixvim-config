---
name: deploy
description: Deploy nixvim-config to the homelab host. Use when the user says "deploy" — notifies the homelab agent over the relay tools to update the nixvim-config flake input and switch.
---

# Deploy

"Deploy" = ask the **homelab agent** (relay peer) to bump its `nixvim-config`
flake input to the latest `main` and switch. This repo never touches the
homelab repo or runs the switch itself.

## Steps

1. **Pre-flight (this repo).** Deploy only what is on GitHub:
   - `git status --short` must be clean (uncommitted work is not deployed;
     tell the user and stop if dirty).
   - `git fetch -q && git rev-parse HEAD origin/main` must match. If local is
     ahead, ask before pushing; never force-push.
   - Note the short rev (`git rev-parse --short origin/main`) and the last
     commit subjects since the previous deploy, for the message.
2. **Find the peer.** `relay_list_peers`; pick the address starting with
   `/home/homeserver/homelab@homeserver#`. The `#<uuid>` suffix changes per
   session, so never reuse an old address. Follow `next_cursor` if absent. No
   such peer → tell the user the homelab agent is offline; stop.
3. **Send** with `relay_agent_send` (plain string body):

   > Deploy nixvim-config `<rev>` (<one-line summary>). In the homelab repo:
   > 1. `nix flake update nixvim-config` (only that input).
   > 2. Review the lock diff; it should touch `nixvim-config` and whatever it
   >    pulls in (e.g. `flake-file`, plugin inputs) only.
   > 3. Switch the host (your usual elevated switch flow) and confirm it
   >    succeeds. `bareksa-box` etc. apply fully on next redeploy.
   > 4. Smoke test: `nvim --headless +qa` exits 0, leader keys set, no startup
   >    errors.
   > 5. Commit and push the lock bump if that is your normal flow, then report
   >    back: result, new rev, any failure output. On failure, roll back
   >    (`git checkout flake.lock`, switch) and report; do not leave the host
   >    half-switched.

4. **Report to the user:** peer message sent, rev deployed. Do not claim the
   deploy succeeded until the homelab agent replies; if the user wants, wait
   for its reply, otherwise say it is pending.

## Notes

- Updating one plugin first: `nix flake update <plugin-input>` here, commit,
  push, then deploy.
- Run `nix flake check` here beforehand for risky changes; deploy itself does
  not.
