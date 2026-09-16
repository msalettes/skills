---
name: ms-pr-brief
description: Generate a comprehension brief for a GitHub pull request — summary, main changes, rationale, and where complexity/risk/test-gaps live — without rendering a review verdict. Use only when the user explicitly runs /pr-brief with a PR number or URL.
---

# PR Brief

## Purpose

Help the user _understand_ a pull request before they review it themselves: what changed, why, and
where to focus their attention. This skill never approves, blocks, or judges the change — it prepares
the reader, it does not replace them. If the user wants an actual review (bugs, correctness verdicts,
approve/request-changes), point them at `/ms-code-review` or a review-focused skill instead.

## Trigger

Only on explicit invocation: `/ms-pr-brief <PR number|URL>`. Do not auto-trigger on PR mentions in
conversation.

## Process

1. **Resolve the target.**
   - If given a full URL, extract `owner/repo` and PR number from it.
   - If given a bare number, resolve the repo from the current directory (`gh repo view --json owner,name`).
   - Run `gh auth status` once; if not authenticated, tell the user and stop.

2. **Delegate to a subagent.** Spawn a `general-purpose` agent (via the Agent tool) with a self-contained
   prompt (it starts with no context) that instructs it to:
   - Fetch PR metadata: `gh pr view <n> --repo <owner>/<repo> --json title,body,author,baseRefName,headRefName,commits,files,additions,deletions,url,comments`
   - Fetch the diff: `gh pr diff <n> --repo <owner>/<repo>`
   - Fetch existing review threads: `gh api repos/<owner>/<repo>/pulls/<n>/comments` (inline review comments) and
     `gh api repos/<owner>/<repo>/pulls/<n>/reviews` (top-level reviews) — note which threads look unresolved
     or still under discussion.
   - Detect a linked ticket by matching `[A-Z]{2,}-\d+` against the PR title, the head branch name, and each
     commit message.
   - If a ticket ID is found AND `acli` is available and authenticated, fetch its summary/description via
     the `atlassian-cli` skill's commands. If no ticket is found, or `acli` isn't usable, skip the ticket
     lookup silently — do not block or complain about it.
   - Group the changed files into logical themes (e.g. "API client", "UI component X", "tests",
     "config/build"), not a flat file list.
   - For each theme, apply the **critical-point taxonomy** below to note where attention is warranted,
     in "point, don't judge" phrasing (see Boundary rule).
   - Work out a suggested reading order based on dependency, not importance ("start with the shared type
     change — the other files build on it").
   - Return the finished markdown document (using the Output template below) as its final answer.

3. **Deliver the result.**
   - Print the returned markdown in the conversation.
   - Save it to `./vscode/pr-brief/<pr-number>.md` in the user's current working directory
     (create the `./vscode/pr-brief` directory if it doesn't exist).

## Critical-point taxonomy

When flagging where the reader should pay attention, categorize using these (from Google's
[eng-practices](https://google.github.io/eng-practices/review/reviewer/looking-for.html) reviewer
checklist), and only these — do not invent ad hoc severity labels:

- **Design/architecture fit** — does this change sit where you'd expect, does it integrate with existing
  patterns in the codebase, or does it introduce a new one?
- **Functionality & edge cases** — non-obvious branches, error paths, concurrency/async ordering.
- **Complexity** — including _over_-engineering (more generic/flexible than the problem needs), not just
  hard-to-follow logic.
- **Test coverage** — what's tested, what isn't, whether tests would actually fail if the logic broke.
- **Readability & naming** — code that requires the PR description to be understood.
- **Comments** — whether comments explain _why_ (non-obvious rationale) vs. restate _what_ the code does.
- **Documentation** — README/migration-guide/changeset updates needed given the change.

## Boundary rule — point, don't judge

Every critical point is a _location + category_, never a verdict. Use phrasing like:

- "This touches `<file>` — no test added for the new branch." (test coverage)
- "`<function>` takes on a second responsibility here." (design fit)
- "This diverges from the pattern used in `<other file>` for the same kind of thing." (design fit,
  descriptive only — not "this is wrong")

Never write "bug", "wrong", "should", "good", "bad", "correct", or propose a fix. Never assign a
blocking/nice-to-have severity — that's a reviewer's call, not this skill's.

## Output template

```markdown
# PR Brief: <title> (#<number>)

## TLDR

<2-3 sentences: what this PR does, at a glance>

## Why

<Ticket summary + rationale if found, otherwise drawn from the PR description. State plainly if no
rationale is available in either place.>

## Changes by theme

### <Theme 1>

- **What**: <files/behavior>
- **Why**: <rationale for this theme specifically, if inferable>
- **Points to note**: <taxonomy-tagged, location-based observations, or "none flagged" if none>

### <Theme 2>

...

## Suggested reading order

1. <file/theme> — <dependency-based reason>
2. ...

## Open discussion

<Summary of unresolved review threads/comments, or "No existing review comments yet.">
```

## Edge cases

- **Fork PR / limited access**: if `gh api` calls for review comments 403, note it in Open discussion
  rather than failing the whole brief.
- **No ticket ID found**: omit the ticket context, don't guess one.
- **Very large PR**: still group by theme; if a theme has a large file count, say so as a location note
  under that theme rather than warning about PR size globally.
- **PR already merged/closed**: still generate the brief — the metadata is still valid — but note its
  state at the top of the TLDR.
