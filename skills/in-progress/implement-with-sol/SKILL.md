---
name: implement-with-sol
description: Orchestrate the codex CLI (gpt-sol) as implementation executor with review-fix rounds, then ship the PR. Use when the user asks to delegate implementation or execution to codex, sol, or gpt-sol, or to send review findings back to a codex session.
---

# implement-with-sol

Codex implements in a worktree; you keep planning, review, and synthesis. Ends with a PR ready for human review.

## Steps

1. **Worktree**: create one with `git wt <branch> origin/<default-branch>` and run everything from inside it.

2. **Spec file**: save the task spec verbatim to a temp file (e.g. `gh issue view <n> --json title,body -q '"# " + .title + "\n\n" + .body' > /tmp/<slug>.md`) so the prompt references a path instead of inlining it.

3. **Launch** from the worktree, in the background:

   ```
   codex exec --sandbox workspace-write "<prompt>"
   ```

   Global flags precede the subcommand: follow-ups are `codex exec --sandbox workspace-write resume --last "<prompt>"` — flags placed after `resume` fail. The model comes from `~/.codex/config.toml`; override with `-m`.

   The prompt names: the spec path with "follow every decision in it"; the existing code and test patterns to study; the definition of done (build, lint, and tests pass; required cases covered); a review-fix instruction ("re-review your own diff against the spec, fix findings, repeat until a pass finds nothing"); "Do NOT commit — leave changes in the working tree"; and "print files changed and each verification command with its result".

4. **Verify**: rerun the claimed checks yourself, review the diff against the spec decision by decision, and smoke-test edge cases the spec calls out. Codex's report is a claim, not evidence.

5. **Fix rounds**: send each finding via `resume --last` as in step 3 and re-verify, until a review pass finds nothing. Trivial one-file tweaks may be fixed directly instead.

6. **Ship**: commit per the logical-commits skill (`git-hunk skills get core logical-commits`), then invoke `make-pr`.

Done when a review pass finds nothing, the checks pass locally, and the PR URL is returned.
