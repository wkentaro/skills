---
name: make-pr
description: Push the current branch and create or update its GitHub pull request. Use after the branch is ready for review.
---

# Publish a pull request

1. Resolve the current and default branches. If the current branch is the default branch or a placeholder, invoke `make-branch` first. Stop if the intended changes are not committed.

2. Inspect the commits and diff against the default branch. Write a Conventional Commit title under 70 characters and invoke `writing-pull-requests` for the body.

3. Check for an open PR from the current branch. Push with tracking; use `--force-with-lease` only after an intentional history rewrite.

4. Create the PR with `--assignee @me`, or update its title and body, passing the body through a temporary `--body-file` deleted afterward. Direct user invocations create a ready PR; autonomous invocations create a draft unless explicitly requested otherwise.

5. Return the PR URL.
