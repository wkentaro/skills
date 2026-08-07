# Domain docs

These rules define how engineering skills use this repository's domain documentation.

## Read before exploration

Read the applicable files before you explore the code:

- Read `CONTEXT.md` at the repository root.
- If `CONTEXT-MAP.md` exists at the repository root, read it and each applicable context file.
- Read applicable ADRs in `docs/adr/`.
- In a multi-context repository, also read applicable ADRs in `src/<context>/docs/adr/`.

If a file or directory does not exist, continue without a warning. Do not suggest that the user create it before it is necessary. The `/domain-modeling` skill creates these files when terms or decisions are resolved.

## File structure

This repository uses the single-context layout:

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-event-sourced-orders.md
│   └── 0002-postgres-for-write-model.md
└── src/
```

A multi-context repository uses this layout:

```
/
├── CONTEXT-MAP.md
├── docs/adr/
└── src/
    ├── ordering/
    │   ├── CONTEXT.md
    │   └── docs/adr/
    └── billing/
        ├── CONTEXT.md
        └── docs/adr/
```

## Use the glossary vocabulary

When output names a domain concept, use the term from `CONTEXT.md`. This rule applies to issue titles, refactor proposals, hypotheses, and test names. Do not use a synonym that the glossary excludes.

If the required concept is not in the glossary, first check that the concept exists in the project. If it does, record the gap for `/domain-modeling`.

## Report ADR conflicts

If output conflicts with an ADR, report the conflict. Do not silently override the ADR.
