# skills

My AI skills

Here are AI skills, i usually use:

## From [Matt Pocock](https://github.com/mattpocock/skills)

- [grilling](https://github.com/mattpocock/skills)
- [grill-me](https://github.com/mattpocock/skills)
- [handoff](https://github.com/mattpocock/skills)
- [research](https://github.com/mattpocock/skills)
- [prototype](https://github.com/mattpocock/skills) ?
- [teach](https://github.com/mattpocock/skills)
- [wait-what](https://github.com/mattpocock/skills)
- [writing-for-agents](https://github.com/mattpocock/skills)
- [write-a-skill](https://github.com/mattpocock/skills)

## Mine

For each skill, "Depends on" lists the other skills it explicitly calls via the `Skill` tool or `/`-invokes.

- **ms-setup-skills** — Depends on: none
- **ms-grill-with-docs** — Depends on: `grilling` (Matt Pocock), `ms-domain-modeling`
- **ms-domain-modeling** — Depends on: none
- **ms-to-spec** — Depends on: none (requires `/ms-setup-skills` to have been run first)
- **ms-to-tickets** — Depends on: none (requires `/ms-setup-skills` to have been run first)
- **ms-implement** — Depends on: `ms-tdd`, `ms-code-review` (requires `/ms-setup-skills` to have been run first)
- **ms-codebase-design** — Depends on: none
- **ms-code-review** — Depends on: none (requires `/ms-setup-skills` to have been run first)
- **ms-tdd** — Depends on: `ms-codebase-design`
- **ms-improve-codebase-architecture** — Depends on: `ms-codebase-design`, `grilling` (Matt Pocock), `ms-domain-modeling`
- **ms-writing-pr** — Depends on: none
- **ms-pr-brief** — Depends on: none
- **ms-fix-pr-feedback** — Depends on: none
