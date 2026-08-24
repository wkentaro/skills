---
name: review-fix
description: >-
  Run configurable review-and-fix rounds on a working change until clean.
  Use for review-fix requests on uncommitted work, a branch, PR, or MR; use the
  Default Review Policy when no brief is supplied, accept an optional target or
  custom review brief, and leave supported fixes uncommitted.
---

# Review fix

Run Review Rounds until clean from a resolved Review Policy:

```text
/review-fix [target] [free-form review brief]
```

Examples:

```text
/review-fix
/review-fix #123
/review-fix over-engineering
/review-fix #123 specification compliance and authorization boundaries
/review-fix ponytail-review and writing-code
```

An explicit brief chooses the Review Policy; no brief uses the Default Review
Policy. This skill owns reviewer orchestration, evidence verification, repairs,
and checks.

## Resolve the request

Treat the leading argument as the target only when it unambiguously resolves as
an existing Git ref, a PR or MR number in the current repository, or a PR or MR
URL. Otherwise use the current branch and working tree as the target and treat
the whole argument as the Review Brief.

Resolve an explicit target into an editable local checkout without disturbing
uncommitted work. A target that cannot be checked out safely makes the outcome
`incomplete`. Determine the target's base from forge metadata, its upstream, or
the repository's default branch, in that order.

When the request contains no brief, use the Default Review Policy below. This
includes a target-only request such as `/review-fix #123`.

## Resolve the review policy

A Review Request runs in a fresh, report-only Reviewer Tree. A Leaf Review Skill
reports through one Reviewer; a Composite Review Skill may delegate the review
work it requires. Every agent in the tree inherits the same report-only boundary.

- Each explicitly named review skill creates one Review Request.
- Explicitly named skills replace the Default Review Policy rather than adding
  to it.
- Read each named skill during preflight. Accept leaf and composite Review Skills
  that can complete the request without writes or external mutations. Reject
  cycles and skills whose required descendants cannot be resolved or kept
  report-only.
- When no skill is named, match the brief against installed Review Skills.
  One unambiguous match uses that skill; no match creates one ad-hoc Reviewer
  from the brief; several plausible matches require native structured input.
- Several concerns in one skill-free brief remain one ad-hoc Review Request.
  Never split prose into an implicit panel.
- Text around explicit skill names refines those requests. If it clearly adds a
  separate, unassigned concern, ask whether it belongs to a named Reviewer or a
  separate ad-hoc Reviewer.

Preflight the complete Reviewer Tree before starting any Reviewer. Resolve named
skills and their required review skills to absolute directories so every agent
can read its skill directly even when model invocation is disabled. Reserve
enough agent slots for Composite Review Skills; serialize top-level requests
when concurrent dispatch would starve their descendants. The runtime chooses
models and reasoning effort; this skill carries no model matrix. Record each
resolved Reviewer Tree and its slot reservation for the final report.

### Default Review Policy

Use one Review Request per row when the caller supplies no Review Brief. The
mode narrows write-capable skills to report-only evaluation.

| Review skill | Mode |
| --- | --- |
| `code-review` | Standards and Spec review |
| `brooks-review` | Maintainability review |
| `ask-exemplar` | Embedded Evaluation |
| `zero-tech-debt` | Analysis only |
| `writing-code` | Audit mode |

## Run until clean

Keep the resolved Review Policy unchanged across rounds. Each round uses fresh
Reviewers against the target produced by the preceding round.

1. Record the target's HEAD, status, and complete diff. Do not edit while
   Reviewers run.
2. Dispatch one fresh top-level Reviewer per Review Request, concurrently where
   the preflighted nesting budget allows. Give each tree the same target, base,
   diff scope, and repository instructions. A named-skill Reviewer reads and
   follows that skill and its required references; an ad-hoc Reviewer uses the
   Review Brief as its review criteria.
3. Require every Reviewer Tree to inspect and report only. A Composite Review
   Skill delegates only where required and passes the target context and
   report-only boundary to every descendant. A Reviewer executing a Leaf Review
   Skill or ad-hoc focus does not delegate. No Reviewer may modify files, commit,
   comment on a forge, or push. Each finding includes its location, claim,
   evidence, and proposed remedy; a clean Reviewer says so.
4. Wait for every Reviewer Tree. If any agent fails or times out, or the target
   changed during review, apply no orchestrator edits and return `incomplete`
   with the failed request or changed state.
5. Merge duplicate claims while retaining every Reviewer's provenance. Treat
   each claim as a hypothesis: verify it independently against the exact source,
   specification, repository rules, or observable behavior. Name claims that
   could not be verified; they are not findings and never receive fixes.
6. Let evidence resolve disagreements. Leave a Verified Finding unfixed when
   competing remedies remain unresolved, and make the outcome `incomplete`.
7. Apply every supported, non-conflicting repair as a tight edit. Do not expand
   the target's scope or edit adjacent code without a Verified Finding.
8. Run the smallest relevant tests, lint, and type checks. Exercise a changed
   output surface directly when existing tests do not observe it. A red check
   or an unsafe repair makes the outcome `incomplete`.
9. Record the round's Review Outcome. `clean` ends the run. `fixed` starts a new
   Review Round at step 1. `incomplete` ends the run without further edits.

Continue only while each `fixed` round changes the target and passes its checks.
A repeated Verified Finding without new evidence, or any round that cannot make
a supported repair, makes the outcome `incomplete` instead of cycling.

## Return the outcome

Report whether the Review Policy was default or caller-supplied, the resolved
Review Requests, each round's full Reviewer Tree provenance, Verified Findings,
unverified claims, repairs, checks, and Review Outcome. Finish with exactly one
terminal outcome. For each Composite Review Skill, provenance names the
top-level Reviewer and every descendant role, and records that preflight
accepted the tree with enough agent capacity. State the exact Review Request
count, identify the fresh top-level Reviewer dispatched for each request, and
for every later round confirm that it reused the same Review Policy.

- `clean`: no Verified Findings.
- `incomplete`: the requested policy could not finish safely.

Leave all repairs uncommitted. Do not commit, rebase, comment, or push. The
caller owns the repository's history and publication workflows.
