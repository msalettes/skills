---
name: ms-fix-pr-feedback
description: Auto-fix GitHub PR review comments that the PR author has explicitly approved by leaving a 👍 reaction on them, committing one dedicated commit per fixed thread, then posting a ✅ reply after user confirmation. Use only when the user explicitly runs /fix-pr-feedback with a PR URL — never trigger automatically on PR mentions.
allowed-tools: Bash(gh:*), Bash(git:*), Bash(jq:*), Read, Edit, Write, AskUserQuestion
---

# Fix PR Feedback

## Purpose

Given a GitHub PR you authored, find the reviewer comments you've signaled ready to auto-fix
(by reacting 👍 on them), apply the suggested fix to the code, and commit each fix separately —
so review feedback becomes code without you hand-applying every suggestion. This is the *fix*
counterpart to `/check-pr-feedback` (which only checks/resolves, never edits code) — do not
confuse the two, and never modify that other command.

## Trigger

Only on explicit invocation: `/ms-fix-pr-feedback <PR URL>`. Do not auto-trigger on PR mentions.

## Process

### Phase 1 — Resolve inputs & preconditions

1. Parse `owner`, `repo`, and PR number from the URL (`https://github.com/{owner}/{repo}/pull/{number}`).
   If the argument isn't a full PR URL, stop and ask for one.
2. Verify local repo state:
   ```bash
   gh pr view <number> --repo <owner>/<repo> --json headRefName -q .headRefName
   git branch --show-current
   ```
   If these don't match, **stop** and tell the user to check out the PR's branch first — never
   check it out for them.
3. Confirm `gh` is authenticated (`gh auth status`); stop with a clear message if not.

### Phase 2 — Fetch candidates

Run the bundled script, which does the deterministic fetch + filter in one shot:

```bash
scripts/fetch-candidates.sh <owner> <repo> <number>
```

It returns a JSON array of qualifying threads — threads that are simultaneously: unresolved,
have no ✅/`:white_check_mark:` reply yet, were opened by someone other than the PR author, and
whose root comment carries a 👍 reaction from you (the authenticated `gh` user). Each item has
the shape:

```json
{ "thread_id": "...", "comment_id": 123, "path": "...", "diff_hunk": "...", "body": "...", "url": "...", "replies": [...] }
```

If the array is empty, report "No 👍-approved unresolved reviewer comments to fix on this PR."
and stop.

### Phase 3 — Apply each fix

For each candidate, in order:

1. **If `body` contains a `` ```suggestion `` fenced block**: extract the code inside it and
   apply it verbatim at the location indicated by `diff_hunk`/`path` (the `diff_hunk` shows the
   surrounding lines as they looked when the comment was made — use it to locate the exact spot
   in the current file, the same way `pr-feedback-checker` locates code by diffing `diff_hunk`
   against current content).
2. **Otherwise (free-text suggestion)**: read `body` plus the current content of `path` around
   the `diff_hunk` location, and decide whether you can confidently determine the exact change
   being requested.
   - If confident, apply it.
   - If not confident, **skip** this candidate — record status `skipped - needs manual fix` and
     move on. Never guess at a destructive or ambiguous change.
3. For every candidate you *did* apply a fix for: create one dedicated commit for that thread
   only (`git add <changed file(s)>` then `git commit`), before moving to the next candidate.
   Write a commit message that names what was fixed, e.g.:
   ```
   fix: address review feedback on <path>

   <one-line summary of the comment>

   Ref: <comment url>
   ```
   Do **not** push. Do not batch multiple threads into one commit, even if they touch the same
   file.
4. Track each candidate's outcome: `{ excerpt, status: "fixed" | "skipped - needs manual fix", comment_id, url }`.

### Phase 4 — Report & confirm

1. Render a markdown table:
   ```
   | Comment | Status |
   |---------|--------|
   | <excerpt, <=80 chars> | fixed |
   | <excerpt, <=80 chars> | skipped - needs manual fix |
   ```
2. If at least one row is `fixed`, use `AskUserQuestion` to ask: "Post ✅ replies on the N fixed
   thread(s) now?" with options "Yes" / "No, I'll do it myself".
3. If confirmed, for each `fixed` row run:
   ```bash
   scripts/post-checkmark-reply.sh <owner> <repo> <number> <comment_id>
   ```
4. Report how many replies were posted (and any failures, with the error).

### Notes / guardrails

- Never resolve the review thread — only the reviewer who opened it should do that, not this
  skill and not the PR author.
- Never push the commits this skill creates — leave them local for the user to review and push.
- Already-resolved threads, threads with an existing ✅ reply, threads opened by the PR author,
  and threads without your 👍 are never surfaced or touched.
- If `scripts/fetch-candidates.sh` or `gh` calls fail (rate limit, permissions, PR not found),
  report the error verbatim and stop — don't retry silently or fall back to guessing PR data.
