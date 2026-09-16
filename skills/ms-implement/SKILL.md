---
name: ms-implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

Read `.vscode/agents/README.md`. Then read the linked files this task needs: `issue-tracker.md` before using the issue tracker. If `.vscode/agents/README.md` is missing, tell the user to run `/ms-setup-skills`.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work.

Commit your work to the current branch.
