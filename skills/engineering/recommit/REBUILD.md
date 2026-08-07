# Rebuild methods

Use the lightest method that can produce the planned sequence. Both methods start from the
clean state and recorded values in `SKILL.md`.

## Fold existing fixups

Use this method only when the planned sequence differs by folding existing `fixup!` or
`squash!` commits into their named ancestors:

```bash
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <MERGE_BASE>
```

This command does not reorder, reword, or drop ordinary commits. Use the full rebuild for
those changes. If the rebase stops, run `git rebase --abort`, confirm that `HEAD` is
`ORIG`, and use the full rebuild instead.

This method is complete when the log matches the planned sequence and the working tree is
clean.

## Perform a full rebuild

Use this method for reordered, reworded, dropped, combined, or split commits.

Move the planned range into the working tree while keeping the final content from `ORIG`:

```bash
git reset --mixed <MERGE_BASE>
```

The worktree now contains the final content. Each new commit advances `HEAD`, so the
remaining diff is always relative to all earlier new commits. Keep the worktree at its final
content. Never restore a split file to `MERGE_BASE` between commits.

For each planned commit, stage only its files or hunks. Stage with `git-hunk` when it is
installed; read its usage before the first staging call:

```bash
git-hunk skills get core
git-hunk list
git-hunk stage <hunk-or-path>...
```

Use `git-hunk stage <hunk> -l <lines>` when one hunk contains work for several commits. For
a whole file that belongs to one commit, `git add -- <path>` is also sufficient.

When `git-hunk` is not installed, use plain git with a patch outside the repository for
non-interactive hunk selection:

```bash
SCRATCH=$(mktemp -d)
git add -N -- <new-path>  # only for a new file that must appear in the patch
git diff --binary > "$SCRATCH/remaining.patch"
cp "$SCRATCH/remaining.patch" "$SCRATCH/commit.patch"
# Edit commit.patch so it contains only the next commit's complete file headers and hunks.
git apply --cached --check "$SCRATCH/commit.patch"
git apply --cached "$SCRATCH/commit.patch"
```

Select whole files and whole hunks only. A patch edit that splits inside one hunk must
recompute the `@@` line counts and fails easily; that split needs
`git-hunk stage <hunk> -l <lines>`, so without `git-hunk` revise the planned commits to
split only at whole-hunk boundaries.

Record the absolute `SCRATCH` path with the other recorded values. Binary patches preserve
paths, modes, and symlinks, so files with the same basename remain distinct.

Before every commit, read the complete staged diff and verify its whitespace:

```bash
git diff --cached --check
git diff --cached
git commit -m "<planned title>"
```

After each commit, confirm that it matches one planned story. Continue until `git status
--porcelain=v1 --untracked-files=all` is empty. If the patch fallback was used, remove the
scratch directory:

```bash
rm -rf "$SCRATCH"
```

The full rebuild is complete when the log matches the planned sequence and the working
tree is clean.

## Validate each commit in isolation

Run checks in a temporary detached worktree so later uncommitted content cannot make an
earlier commit pass:

```bash
VERIFY_ROOT=$(mktemp -d)
VERIFY_TREE="$VERIFY_ROOT/tree"
git worktree add --detach "$VERIFY_TREE" <MERGE_BASE>
CHECK_STATUS=0
for sha in $(git rev-list --reverse <MERGE_BASE>..HEAD); do
  git -C "$VERIFY_TREE" switch --detach "$sha" || { CHECK_STATUS=$?; break; }
  (cd "$VERIFY_TREE" && <checks planned for this commit>) || { CHECK_STATUS=$?; break; }
done
git worktree remove --force "$VERIFY_TREE"
rmdir "$VERIFY_ROOT"
test "$CHECK_STATUS" -eq 0
```

Run the exact checks from the plan for each commit. A failed check fails the
verification. The procedure is complete when every commit passes and the temporary
worktree is removed.
