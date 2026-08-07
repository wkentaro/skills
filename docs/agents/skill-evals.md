# Skill evals

These rules define how agents run skill evals in this repository.

## When to run

When you create or change a skill that has `evals/evals.json`, run every eval before you mark the change complete.

## Eval file format

`evals/evals.json` follows the skill-creator schema: a `skill_name`, and an `evals` array with one entry per eval, each with `id`, `prompt`, `expected_output`, and `expectations`. `expected_output` is a one-sentence description of a good result. `expectations` are the statements you check one by one.

## How to run

- Run each eval prompt in a fresh context that has the changed skill loaded.
- Compare the output with the previous skill version, or with a no-skill baseline when the skill is new.
- Check every expectation in the eval against the output. The agent that produced the output does not grade it; a separate context checks the expectations.

## How to report

Report the per-expectation results in the PR description before you mark the change complete. Report a failed expectation as a failure; do not soften it.
