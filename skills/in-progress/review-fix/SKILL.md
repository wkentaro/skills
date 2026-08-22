---
name: review-fix
description: >-
  Run caller-configured review-and-fix rounds on a working change until clean.
  Use for review-fix requests on uncommitted work, a branch, PR, or MR; accept
  an optional target and free-form review brief, ask when the brief is unclear,
  and leave supported fixes uncommitted.
---

# Review fix

Run Review Rounds until clean from a caller-owned Review Brief:

```text
/review-fix [target] [free-form review brief]
```

Examples:

```text
/review-fix over-engineering
/review-fix #123 specification compliance and authorization boundaries
/review-fix ponytail-review and writing-code
```

The brief chooses the review policy. This skill owns reviewer orchestration,
evidence verification, repairs, and checks. It never supplies a default roster.

## Resolve the request

Treat the leading argument as the target only when it unambiguously resolves as
an existing Git ref, a PR or MR number in the current repository, or a PR or MR
URL. Otherwise use the current branch and working tree as the target and treat
the whole argument as the Review Brief.

Resolve an explicit target into an editable local checkout without disturbing
uncommitted work. A target that cannot be checked out safely makes the outcome
`incomplete`. Determine the target's base from forge metadata, its upstream, or
the repository's default branch, in that order.

When the brief is absent, ask through native structured input what the review
should focus on. Do not start reviewers or modify the target until the caller
has supplied a brief.

## Resolve the review policy

A Reviewer is a fresh, report-only subagent assigned one Review Request.

- Each explicitly named review skill creates one Review Request.
- A named skill must be a Leaf Review Skill: it can perform the requested review
  directly, without subagents or writes. Read its instructions during preflight
  and return `incomplete` before dispatch when it is not a leaf.
- When no skill is named, match the brief against installed Leaf Review Skills.
  One unambiguous match uses that skill; no match creates one ad-hoc Reviewer
  from the brief; several plausible matches require structured clarification.
- Several concerns in one skill-free brief remain one ad-hoc Review Request.
  Never split prose into an implicit panel.
- Text around explicit skill names refines those requests. If it clearly adds a
  separate, unassigned concern, ask whether it belongs to a named Reviewer or a
  separate ad-hoc Reviewer.

Preflight every Review Request before starting any Reviewer. Resolve named
skills to absolute directories so a Reviewer can read the skill directly even
when model invocation is disabled. The runtime chooses models and reasoning
effort; this skill carries no model matrix.

## Run until clean

Keep the resolved Review Policy unchanged across rounds. Each round uses fresh
Reviewers against the target produced by the preceding round.

1. Record the target's HEAD, status, and complete diff. Do not edit while
   Reviewers run.
2. Dispatch one fresh subagent per Review Request, concurrently where possible.
   Give each the same target, base, diff scope, and repository instructions.
   A named-skill Reviewer reads that skill and its required references. An
   ad-hoc Reviewer uses the Review Brief as its review criteria.
3. Require every Reviewer to inspect and report only. It must not modify files,
   delegate, commit, comment on a forge, or push. Each finding includes its
   location, claim, evidence, and proposed remedy; a clean Reviewer says so.
4. Wait for every Reviewer. If one fails or times out, or the target changed
   during review, apply no orchestrator edits and return `incomplete` with the
   failed request or changed state.
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

Report the Review Brief, resolved Review Requests, and each round's reviewer
provenance, Verified Findings, unverified claims, repairs, checks, and Review
Outcome. Finish with exactly one terminal outcome:

- `clean`: no Verified Findings.
- `incomplete`: the requested policy could not finish safely.

Leave all repairs uncommitted. Do not commit, rebase, comment, or push. The
caller owns the repository's history and publication workflows.
