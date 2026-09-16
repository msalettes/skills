---
name: ms-setup-skills
description: "Configure this repo for the engineering skills: set up its issue tracker, and domain doc layout. Run once before first use of the other engineering skills."
disable-model-invocation: true
---

# Setup My ms Skills

Scaffold the per-repo configuration that the engineering skills assume:

- **Issue tracker**: where issues live (GitHub by default; local markdown is also supported out of the box)
- **Domain docs**: where `CONTEXT.md` and ADRs live, and the consumer rules for reading them

Write only under `.vscode/agents/`. That folder is personal skill config, not team agent instructions: leave `AGENTS.md` and `CLAUDE.md` unchanged.

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write.

## Process

### 1. Explore

Look at the current repo to understand its starting state. Read whatever exists; don't assume:

- `git remote -v` and `.git/config`: is this a GitHub repo? Which one?
- `CONTEXT.md` and `CONTEXT-MAP.md` at the repo root
- `adr/` and any `packages/*/adrs/` or `apps/*/adrs/` directories
- `.vscode/agents/`: does this skill's prior output already exist? (`README.md`, `issue-tracker.md`, `domain.md`)
- `.vscode/scratch/`: a sign that a local-markdown issue tracker convention is already in use
- Monorepo signals: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*` with its own `src/`. These are present only in a genuinely large multi-package repo; their absence means single-context, which is almost every repo.

### 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order. One section, one answer, then the next.

Lead each section with the recommended answer so the user can accept it in a word. Give a one-line explainer only when the choice genuinely branches; skip the section entirely when exploration already settled it (ex: Section B when there's no monorepo).

**Section A: Issue tracker.**

> Explainer: The "issue tracker" is where issues live for this repo. Skills like `to-tickets` and `to-spec` read from and write to it. They need to know whether to call `gh issue create`, write a markdown file under `.vscode/scratch/`, or follow some other workflow you describe. Pick the place you actually track work for this repo.

Default posture: these skills were designed for GitHub. If a `git remote` points at GitHub, propose that. If a `git remote` points at GitLab (`gitlab.com` or a self-hosted host), propose GitLab. Otherwise (or if the user prefers), offer:

- **GitHub**: issues live in the repo's GitHub Issues (uses the `gh` CLI)
- **GitLab**: issues live in the repo's GitLab Issues (uses the [`glab`](https://gitlab.com/gitlab-org/cli) CLI)
- **Local markdown**: issues live as files under `.scratch/<feature>/` in this repo (good for solo projects or repos without a remote)
- **Other** (Jira, Linear, etc.): ask the user to describe the workflow in one paragraph; the skill will record it as freeform prose

Record the choice in `.vscode/agents/issue-tracker.md`. The GitHub and GitLab templates carry a "PRs as a request surface" flag, defaulted **off**. Leave it off and don't raise it: a user who wants external PRs in the triage queue can flip the flag in the file later.

**Section B: Domain docs.** Default to **single-context** (one `CONTEXT.md` + `adrs/` at the repo root). This fits almost every repo; write it without asking.

Offer **multi-context** (a root `CONTEXT-MAP.md` pointing to per-context `CONTEXT.md` files) only when exploration found monorepo signals. Then confirm which layout they want.

### 3. Confirm and edit

Show the user a draft of:

- `.vscode/agents/README.md` (the `## Agent skills` index)
- `.vscode/agents/issue-tracker.md` and `.vscode/agents/domain.md`

Let them edit before writing.

### 4. Write

Write only these files under `.vscode/agents/`. If `README.md` already exists, update its contents in-place rather than appending a duplicate.

`.vscode/agents/README.md`:

```markdown
## Agent skills

### Issue tracker

[one-line summary of where issues are tracked]. See `issue-tracker.md`.

### Domain docs

[one-line summary of layout: "single-context" or "multi-context"]. See `domain.md`.
```

Then write the docs files using the seed templates in this skill folder as a starting point:

- [issue-tracker-github.md](./issue-tracker-github.md): GitHub issue tracker
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md): GitLab issue tracker
- [issue-tracker-local.md](./issue-tracker-local.md): local-markdown issue tracker
- [domain.md](./domain.md): domain doc consumer rules + layout

For "other" issue trackers, write `.vscode/agents/issue-tracker.md` from scratch using the user's description.

### 5. Done

Tell the user the setup is complete and which engineering skills will now read `.vscode/agents/README.md`, then the linked files. Mention they can edit `.vscode/agents/*.md` directly later; re-running this skill is only necessary if they want to switch issue trackers or restart from scratch.

In a team repo these files are personal: leave them untracked (a global gitexclude, not a team `.gitignore` change).
