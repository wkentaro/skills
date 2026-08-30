# PR/MR body reference

The job of a PR/MR description is to compress what the reviewer needs to know that **is not visible in the diff**. Apply this test to every sentence.

To embed screenshots or video, read [MEDIA.md](MEDIA.md).

## One block, one line

GitHub renders a single newline inside a paragraph as `<br>` in issue, pull-request, and discussion fields (documented; release notes behave the same in practice), so a hard-wrapped paragraph displays broken mid-sentence. Write each paragraph or list item as one line, however long, with a blank line between blocks — this renders correctly on every forge, including GitLab, whose fields follow standard Markdown paragraph rules. Markdown files in the repo (README, docs, `CHANGELOG.md`) render paragraphs normally; the rule applies the moment their content is pasted into a comment-style field — a changelog entry pasted into release notes is the common trap. Commit messages stay wrapped at 72 columns.

## The necessity test

Before writing a sentence, ask: *can the reviewer get this from a 30-second scan of the diff?* If yes, cut it.

Cut, because the diff already says this:

- "Adds a `Record` dataclass with six fields: a, b, c, ..." (read the class definition).
- "Updated all callers from dict access to attribute access." (read any hunk).
- "Function signatures changed from `dict` to `Record`." (read the signature).
- "No behavior change intended." (the `refactor:` type label and absent test changes already say this).

Keep, because the reviewer can't get this from a diff scan:

- "Stacked on #200. Merge that first."
- "`timestamp = None` is the sentinel; the existing fallback path was already designed for it, so semantics unchanged."
- "Safe because the indexer only reads `Base` fields."

## Match length to change weight

A mechanical or conventional change (rename sweep, formatting, dependency bump, dead-code removal) needs only a few sentences: the rationale, the "no logic change" claim, and any exceptions summarized as a category, not enumerated per file. Name the sweep and its pattern once — "Mechanical rename sweep across 40 files: key access becomes attribute access; no logic change." — and let the diff carry every instance. If the reviewer can verify the whole diff by pattern-matching one hunk, the description should be readable in one breath. Reserve multi-paragraph descriptions and itemized non-obvious-bits lists for changes whose hunks genuinely differ from each other.

## Lead with the punchline

The first sentence answers *why does this exist?*, not *what does this do?*. The "what" is the diff.

| Weak | Strong |
|---|---|
| "This MR migrates `record` from dict to dataclass." | "Finishes what #200 started." |
| "Refactors the auth module." | "Replaces the layered try/except in auth with a dispatch table; the old structure swallowed CSRF errors on token refresh." |
| "Adds a new endpoint." | "Third try at `/api/v2/widgets`; v1 returned the wrong cache key, the spike PR ran into rate limits." |

If you can't write a strong lead, you may not understand the change well enough to describe it. Re-read the diff.

## Surface non-obvious bits explicitly, each with safety resolution

When the diff has subtle decisions (sentinels, ordering swaps, intentional breaks), enumerate them. Each one ends with a safety claim so the reviewer doesn't have to come back with "but what about...".

```
Two non-obvious bits:

1. `timestamp = None` is the sentinel for "not yet parsed". The existing none-fallback was already doing this on dicts; nothing changes semantically.

2. The pipeline reorders normalization to run before indexing. The indexer only reads `Base` fields; safe.
```

The "; safe" / "; nothing changes" tail matters. Without it the reviewer has to verify the safety claim themselves.

## What to cut

**Recap of context the reviewer already has:**

- "This MR builds on #1234 which did X. That work left Y. This MR finishes Y." → "Finishes #1234."
- "The original code did X. This changes it to Y." — before/after framing; the diff shows X and Y.
- Restating code comments — the description is ephemeral; the comment persists with the code.

**Apologies and framings:**

- "This is a large change but..."
- "Please review carefully because..."
- "Sorry for the noise in file Z..."

**Templates without signal:**

- A `## Summary` header with one bullet that is already the lead sentence.
- A `## Why` header on a docs typo fix.
- `- [x] make lint` in a docs-only test plan.

**Marketing words:** "headline", "elegant", "robust", "sells", "deliberately", "carefully crafted".

## Worked example

A `dict` → dataclass migration MR. Bloated draft (~190 words):

> Eliminates the dict / dataclass boundary inside the pipeline. `Container.items` was already typed `list[Record]` after #200 only because the items happened to be dicts at runtime; now they actually are Record instances with attribute access throughout.
>
> Record is a frozen kw_only dataclass with six required fields: a, b, c, d, e, f. The conversion from the parser's dict output happens once at its boundary inside `_normalize_items`; `timestamp = None` is the "unknown" sentinel that the existing fall-back-to-`now()` path was already designed for. The parser still takes dicts, so a small bridge round-trips items via `dataclasses.replace`.
>
> The pipeline is reordered so the second normalization call runs on `ContainerBase` before promoting to `Container`. ...
>
> [...3 more bullets recapping what the diff shows...]

After the necessity test (~60 words):

> Finishes what #200 started.
>
> Two non-obvious bits:
>
> 1. `timestamp = None` is the sentinel for "not yet parsed". The existing none-fallback was already doing this on dicts; nothing changes semantically.
>
> 2. The pipeline reorders the second normalization call to run on `ContainerBase` before promoting to `Container`. The function only reads `ContainerBase` fields; safe.
>
> Stacked on #200.
