# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read an issue**: `gh issue view <number> --comments`, filtering comments by `jq` and also fetching labels.
- **List issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` with appropriate `--label` and `--state` filters.
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` / `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v` — `gh` does this automatically when run inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.** _(Set to `yes` if this repo treats external PRs as feature requests; `/triage` reads this flag.)_

When set to `yes`, PRs run through the same labels and states as issues, using the `gh pr` equivalents:

- **Read a PR**: `gh pr view <number> --comments` and `gh pr diff <number>` for the diff.
- **List external PRs for triage**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` then keep only `authorAssociation` of `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR`, or `NONE` (drop `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comment / label / close**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

GitHub shares one number space across issues and PRs, so a bare `#42` may be either — resolve with `gh pr view 42` and fall back to `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a single issue with **child** issues as tickets.

- **Map**: a single issue labelled `wayfinder:map`, holding the Notes / Decisions-so-far / Fog body. `gh issue create --label wayfinder:map`.
- **Child ticket**: an issue linked to the map as a GitHub sub-issue (`gh api` on the sub-issues endpoint). Where sub-issues aren't enabled, add the child to a task list in the map body and put `Part of #<map>` at the top of the child body. Labels: `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Once claimed, the ticket is assigned to the driving dev.
- **Blocking**: GitHub's **native issue dependencies** — the canonical, UI-visible representation. Add an edge with `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`, where `<blocker-db-id>` is the blocker's numeric **database id** (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _not_ the `#number` or `node_id`). GitHub reports `issue_dependencies_summary.blocked_by` (open blockers only — the live gate). Where dependencies aren't available, fall back to a `Blocked by: #<n>, #<n>` line at the top of the child body. A ticket is unblocked when every blocker is closed.
- **Frontier query**: list the map's open children (`gh issue list --state open`, scoped to the map's sub-issues / task list), drop any with an open blocker (`issue_dependencies_summary.blocked_by > 0`, or an open issue in the `Blocked by` line) or an assignee; first in map order wins.
- **Claim**: `gh issue edit <n> --add-assignee @me` — the session's first write.
- **Resolve**: `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`, then append a context pointer (gist + link) to the map's Decisions-so-far.

## Drain queue

Harness tools run this repo's queue by executing the commands in the fenced blocks below.
A command prints exactly one non-negative integer — the count for its queue — and exits 0
whenever its query succeeded, including a count of 0. Every fetch carries an explicit
`--limit 500`; a result that hits the ceiling may be truncated, so the command exits 1
instead of reporting a count it cannot vouch for (covered by the refusal rule below).

- `drain-queue`: count of pickable issues — open, labeled `ready-for-agent`, no assignee, and no
  open native blockers (`blocked_by` from `.issue_dependencies_summary`; `needs-info`,
  `ready-for-human`, and `wontfix` never qualify). The command enforces the exclusions itself:
  any fetched issue that also carries one of those labels, or that has an assignee, is dropped
  before counting.
- `drain-inflight`: count of open `ready-for-agent` issues assigned to @me (claimed or in progress).

Refusal rule: a missing block, non-zero exit, or non-numeric output means refuse to start or
pause the run — it is never interpreted as "done" or as an empty queue.

```drain-queue
set -euo pipefail
# A fetch capped at the limit may be truncated; refusing beats printing a plausible wrong count.
# ponytail: fixed to a 500-item fetch ceiling; switch to `gh --paginate` (count server-side) when a queue can legitimately reach 500.
if [ "$(gh issue list --state open --label ready-for-agent --limit 500 --json number --jq 'length')" -eq 500 ]; then
  exit 1
fi
open_ready="$(gh issue list --state open --label ready-for-agent --limit 500 --json number,labels,assignees --jq '[.[] | select((.assignees | length) == 0 and (([.labels[].name] | index("needs-info") // index("ready-for-human") // index("wontfix")) == null)) | .number] | .[]')"
count=0
for number in $open_ready; do
  blocked="$(gh api "repos/{owner}/{repo}/issues/$number" --jq '.issue_dependencies_summary.blocked_by')"
  # A non-numeric answer means the query broke; aborting beats silently counting the issue as unblocked.
  case "$blocked" in ''|*[!0-9]*) exit 1 ;; esac
  if [ "$blocked" -eq 0 ]; then count=$((count + 1)); fi
done
echo "$count"
```

```drain-inflight
set -euo pipefail
count="$(gh issue list --state open --label ready-for-agent --assignee @me --limit 500 --json number --jq 'length')"
# Same fetch ceiling as drain-queue: a count that hits the limit may be truncated, so refuse.
# ponytail: fixed to 500; switch to `gh --paginate` when the queue can legitimately reach 500.
if [ "$count" -eq 500 ]; then exit 1; fi
echo "$count"
```
