# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.vscode/scratch/`.

## Conventions

- One feature per directory: `.vscode/scratch/<feature-slug>/`
- The spec is `.vscode/scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.vscode/scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.vscode/scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.
