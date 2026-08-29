---
name: writing-code
description: Write or audit code against the house coding conventions. Use while writing code to settle a style call, or when auditing a change against the conventions.
---

# Writing code

The house coding conventions. These are personal preferences, not universal law. They win
over generic best practice. Where a repository has clearly established a different style,
match the repository.

## Say so, do not invent

Where a case is not covered below, say that plainly instead of supplying a preference the
house has not stated. This holds for a style call, for an audit, and in every language,
and it outranks the urge to give a complete-sounding answer.

## Modes

**A style call while writing code** ("how do I name this?", "does this comment earn its
place?", "should this be a helper?"). Answer from the matching rule and quote it.

**An audit of a change.** Check every rule below against the change and report only the
rules it actually breaks, as a numbered list: the location, the rule cited by its section
and its bold lead-in quoted verbatim, and the concrete edit. Give `file:line` where the
change names its file, and the line alone where it does not. Report exactly `No findings.`
when nothing is broken. Findings look like this:

```
1. `labelme/_app.py:1312` (Imports, Imports at the top): move `from pathlib import Path`
   out of the function body.
2. Line 7 (Type annotations, Annotate every signature): add the return type, `-> None`.
```

## Coding Standards

- **Tests must verify observable behavior and be capable of detecting a plausible production defect.** Reject assertions derived only from test setup, mock configuration, guarantees already enforced by the language or type checker, or the production implementation.
- **Implementation comments explain information the code cannot express, such as intent, constraints, or rationale.** Reject comments that narrate code.

## Outside Python

The rules are written in Python because that is the language the house has documented.
Most are structural and carry over unchanged: scoping, extraction (minus the `_` prefix
below), thin entry points, reading top to bottom, guard clauses, imports, naming, comments, type
annotations, and real dependencies over mocks. Apply those in any language, using whatever
mechanism it provides.

Some rules are Python spellings of one idea, so carry the idea and drop the spelling.
`Final` and `UPPER_CASE` (Scoping and constants): keep the immutability marker, whether
`readonly` or `const`, but follow the language's own casing, since Go constants use
MixedCaps and ALL_CAPS is not idiomatic there. `xs[:]` (Call sites), the container dunders (Class design),
and the pytest structure rules (Tests) translate the same way.

The `_` prefix marking a private helper function has no equivalent worth carrying: it is
wrong in Go, where capitalization controls export, and dated in TypeScript. Leave it in
Python. Keyword arguments are the opposite case, absent as syntax but alive as a goal, so
translate the goal into an options object in TypeScript or named struct fields in Go.

## Scoping and constants

- **Scope a value to its usage site.** A value used in one function lives inside it; promote to module scope only when a second function or module needs it.
- **Parameterize on demand.** Keep a single-use value a local constant, and promote it to a parameter when a caller actually varies it.
- **Constants are `Final` and `UPPER_CASE`.**

## Functions and entry points

- **Thin entry points.** `main()` parses arguments and delegates. Lookup tables and config data live inside `main`, not at module scope.
- **Extract for scope, not reuse.** Extract a single-caller helper to limit a variable's lifetime, narrow its scope, flatten nesting, or when the name adds meaning the expression lacks. Otherwise inline it where it is only one or two lines, since that much indirection buys nothing. Prefix an extracted helper `_` unless it is deliberate public API.
- **Read top to bottom.** A function that reads straight through beats logic shredded into single-caller helpers, each one a jump the reader must reassemble. A module made mostly of one-caller helpers is fragmented, not modular. A `# section` comment inside a long function is the signal to extract; "this could be a function" is not. After any simplification, re-audit the helpers you touched.

## Control flow

- **Guard clauses over nesting.** Put the happy path at the outer indent and invert the negative cases into early exits, so the real work never hides behind extra indentation. `if cond: do_a_lot` becomes `if not cond: continue` in a loop, or `if not cond: return` in a function.

## Class design

- **Named edit methods over container dunders.** `shape.points[i]` and `shape.move_vertex(i, pos)` show both the data shape and the mutation surface; `shape[i] = pos` hides what is being indexed and conflates the object with its inner collection. Reserve `__getitem__`, `__setitem__`, `__len__`, and `__iter__` for types whose whole purpose is to be a container, not for domain entities that happen to hold a list.

## Imports

- **Imports at the top.** A deferred import is for breaking a circular dependency, which should be rare.
- **One `import` per line.**

## Linting

- **Rule selection belongs to the repository.** The house pins no ruff or ty rule set here. Read the repository's own linter configuration rather than guessing at it.

## Naming and comments

- **Names replace comments.** If deleting a docstring makes a function unclear, rename the function.
- **Keep identifiers out of comment prose.** A comment that names another function goes stale the moment that function is renamed, and nothing catches it.
- **Verb-prefixed function names.** Start a function name with a verb naming what it does (`make_local_mask`, `compute_mask_iou`, `round_bbox_to_int`). Use a non-verb form only where it reads strictly better: predicates (`is_*`, `has_*`, `can_*`, `should_*`), classmethod constructors (`from_*`), and conversion idioms (`to_dict`). Prefer singular `is_*` over `are_*`, naming the subject: `is_redundant_pair(new, peer)`, not `are_redundant(new, peer)`. A noun-only name (`mask_iou`) or an adjective-noun name (`filled_mask_for_bbox`) reads as a value, not an action.

## Call sites

- **Spell out keyword arguments,** unless the call is trivially obvious (`len(x)`, `max(items)`, `shape(aoi)`).
- **Copy a list with `xs[:]`,** which reads as "copy this list", where the source is statically a `list`. Reserve `list(...)` for converting a genuine non-list iterable, or where `list(xs or [])` beats `(xs or [])[:]`.

## Type annotations

- **Annotate every signature,** parameters and return type, including `-> None` on tests.
- **Leave inferable locals bare.** Annotate only the ones the type checker cannot infer: `results: list[Hunk] = []`, `exclude: bool | None = None`. A `Final` marker on a fixed value is not a local annotation in this sense.
- **Migration exception.** Annotate locals while upstream functions lack annotations, and remove those once upstream is fixed.

## Tests

- **Plain `test_` functions with fixtures,** never test classes.
- **Mirror the source layout.** Test directories mirror source modules, and tests live in them rather than beside the code they cover. A module with several test files gets a subdirectory named after it (`tests/unit/hunk/` for `hunk.py`), and each file is named for the aspect it covers (`id_test.py`, not `hunk_id_test.py`).
- **Split test files** instead of separating groups with comments.
- **Deduplicate shared setup into a `@pytest.fixture`.**
- **Real dependencies over mocks.** Drive a test through the real thing wherever it is cheap: an existing conftest fixture, an ephemeral subprocess, a dockerized service, an in-memory engine. Mocking a downstream system verifies only your reading of its API, and keeps passing after the real API changes shape. Reserve mocks for paid third-party APIs, irreversible side effects such as payments or mail to humans, and services with no offline mode. When unsure, measure: a sub-second real-dependency test beats the equivalent `MagicMock`.
