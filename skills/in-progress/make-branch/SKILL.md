---
name: make-branch
description: Move work from the default or an auto-generated branch onto a conventional PR branch without changing the work.
---

# Make a PR branch

1. Fetch `origin`, resolve the current and default branches, and inspect commits and working-tree changes against `origin/<default>`. Stop if there is no work to move.

2. If the current branch is already conventional, stop and use `make-pr`. Rename another non-default branch only when it is clearly auto-generated or the user asked; otherwise stop.

3. Choose `<type>/<short-kebab-description>` from the work, using its Conventional Commit type.

4. From the default branch, preserve everything without stashing:

   ```bash
   git switch --no-track -c <new-branch>
   git branch -f <default> origin/<default>
   ```

   Creating the new branch first keeps every commit reachable and the working tree unchanged; `--no-track` leaves upstream setup to `make-pr`.

5. From a placeholder branch, rename it with `git branch -m <new-branch>`.

6. Verify the branch, commits, and working tree. Leave uncommitted changes uncommitted and return the new branch name.
