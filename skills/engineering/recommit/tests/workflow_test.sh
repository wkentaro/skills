#!/usr/bin/env bash
#
# Executable fixtures for the non-obvious claims in the skill documents. Each
# test pins one section; when that section changes, update its test here:
#   test_docs             -> SKILL.md frontmatter contract
#   test_autosquash_fixup -> REBUILD.md "Fold existing fixups"
#   test_full_rebuild     -> REBUILD.md "Perform a full rebuild"
#   test_commit_checks    -> REBUILD.md "Validate each commit in isolation"

set -euo pipefail

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL_DIR=$(cd "$TEST_DIR/.." && pwd)
TEST_ROOT=$(mktemp -d)
trap 'rm -rf -- "$TEST_ROOT"' EXIT

fail_test() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_equal() {
  local expected=$1
  local actual=$2
  local message=$3

  if [[ "$expected" != "$actual" ]]; then
    fail_test "$message"
  fi
}

make_repo() {
  local repo_dir=$1
  local branch=$2

  git init -q -b "$branch" "$repo_dir"
  git -C "$repo_dir" config user.name RecommitTest
  git -C "$repo_dir" config user.email recommit-test@example.com
}

test_docs() {
  local frontmatter
  frontmatter=$(awk '/^---$/ { fence += 1; next } fence == 1' "$SKILL_DIR/SKILL.md")

  grep -q '^description:' <<<"$frontmatter" ||
    fail_test "frontmatter must carry a description"
  grep -q 'Use when ' <<<"$frontmatter" ||
    fail_test "description must carry Use-when triggers"
  if grep -q '^disable-model-invocation' <<<"$frontmatter"; then
    fail_test "skill must stay model-invoked so other skills can reach it"
  fi
  grep -q '^  allow_implicit_invocation: true$' "$SKILL_DIR/agents/openai.yaml" ||
    fail_test "Codex metadata must match model invocation"
}

test_autosquash_fixup() {
  local repo="$TEST_ROOT/autosquash"
  local original_tree
  local commit_count

  make_repo "$repo" main
  printf 'base\n' > "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -q -m "base"
  git -C "$repo" switch -q -c feature
  printf 'feature\n' >> "$repo/file.txt"
  git -C "$repo" commit -q -am "feat: change file"
  printf 'fixup\n' >> "$repo/file.txt"
  git -C "$repo" add file.txt
  git -C "$repo" commit -q --fixup=HEAD
  original_tree=$(git -C "$repo" rev-parse 'HEAD^{tree}')

  GIT_SEQUENCE_EDITOR=true git -C "$repo" rebase -i --autosquash main >/dev/null
  commit_count=$(git -C "$repo" rev-list --count main..HEAD)
  assert_equal "1" "$commit_count" "autosquash did not fold the fixup commit"
  assert_equal "$original_tree" "$(git -C "$repo" rev-parse 'HEAD^{tree}')" \
    "autosquash changed the final committed tree"
}

test_full_rebuild() {
  local repo="$TEST_ROOT/full-rebuild"
  local scratch="$TEST_ROOT/patches"
  local original_tree
  local merge_base
  local first_commit
  local second_commit
  local first_content
  local second_content
  local mode
  local link_mode

  make_repo "$repo" main
  mkdir -p "$repo/src" "$repo/tests" "$scratch"
  printf 'base\n' > "$repo/src/config.txt"
  printf 'base\n' > "$repo/tests/config.txt"
  printf 'delete\n' > "$repo/delete.txt"
  printf 'rename\n' > "$repo/rename-old.txt"
  printf '#!/bin/sh\nexit 0\n' > "$repo/mode.sh"
  ln -s src/config.txt "$repo/link"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "base"

  git -C "$repo" switch -q -c feature
  printf 'base\nfirst\nsecond\n' > "$repo/src/config.txt"
  printf 'base\ntest change\n' > "$repo/tests/config.txt"
  rm "$repo/delete.txt"
  git -C "$repo" mv rename-old.txt rename-new.txt
  chmod +x "$repo/mode.sh"
  ln -sfn tests/config.txt "$repo/link"
  printf 'new\n' > "$repo/new.txt"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "grab bag"

  original_tree=$(git -C "$repo" rev-parse 'HEAD^{tree}')
  git -C "$repo" switch -q main
  printf 'target advance\n' > "$repo/target-only.txt"
  git -C "$repo" add target-only.txt
  git -C "$repo" commit -q -m "target advance"
  git -C "$repo" switch -q feature
  merge_base=$(git -C "$repo" merge-base main HEAD)
  git -C "$repo" reset --mixed "$merge_base" >/dev/null

  printf '%s\n' \
    'diff --git a/src/config.txt b/src/config.txt' \
    '--- a/src/config.txt' \
    '+++ b/src/config.txt' \
    '@@ -1 +1,2 @@' \
    ' base' \
    '+first' > "$scratch/commit.patch"
  git -C "$repo" apply --cached --check "$scratch/commit.patch"
  git -C "$repo" apply --cached "$scratch/commit.patch"
  git -C "$repo" diff --cached --check
  git -C "$repo" commit -q -m "refactor: add first config layer"
  first_commit=$(git -C "$repo" rev-parse HEAD)

  git -C "$repo" add src/config.txt
  git -C "$repo" commit -q -m "feat: add second config layer"
  second_commit=$(git -C "$repo" rev-parse HEAD)

  git -C "$repo" add tests/config.txt
  git -C "$repo" commit -q -m "test: update config fixture"
  git -C "$repo" add -A
  git -C "$repo" commit -q -m "chore: apply filesystem changes"

  assert_equal "$original_tree" "$(git -C "$repo" rev-parse 'HEAD^{tree}')" \
    "full rebuild changed the final committed tree"
  assert_equal "" "$(git -C "$repo" status --porcelain=v1 --untracked-files=all)" \
    "full rebuild left a dirty working tree"

  first_content=$(git -C "$repo" show "$first_commit:src/config.txt")
  second_content=$(git -C "$repo" show "$second_commit:src/config.txt")
  assert_equal $'base\nfirst' "$first_content" "first split commit has the wrong state"
  assert_equal $'base\nfirst\nsecond' "$second_content" \
    "second split commit is not cumulative"
  assert_equal $'base\nfirst\nsecond' "$(git -C "$repo" show HEAD:src/config.txt)" \
    "source config with a duplicate basename was lost"
  assert_equal $'base\ntest change' "$(git -C "$repo" show HEAD:tests/config.txt)" \
    "test config with a duplicate basename was lost"

  if git -C "$repo" cat-file -e HEAD:delete.txt 2>/dev/null; then
    fail_test "deleted file returned after rebuild"
  fi
  git -C "$repo" cat-file -e HEAD:rename-new.txt
  git -C "$repo" cat-file -e HEAD:new.txt
  mode=$(git -C "$repo" ls-tree HEAD mode.sh | cut -d' ' -f1)
  link_mode=$(git -C "$repo" ls-tree HEAD link | cut -d' ' -f1)
  assert_equal "100755" "$mode" "executable mode was lost"
  assert_equal "120000" "$link_mode" "symlink mode was lost"
  assert_equal "tests/config.txt" "$(git -C "$repo" show HEAD:link)" \
    "symlink target was lost"

  test_commit_checks "$repo" "$merge_base"
}

test_commit_checks() {
  local repo=$1
  local merge_base=$2
  local verify_root="$TEST_ROOT/verify"
  local verify_tree="$verify_root/tree"
  local sha
  local check_status
  local first_sha
  local visited

  mkdir -p "$verify_root"
  git -C "$repo" worktree add -q --detach "$verify_tree" "$merge_base"
  first_sha=$(git -C "$repo" rev-list --reverse "$merge_base"..HEAD | head -n 1)

  check_status=0
  visited=""
  for sha in $(git -C "$repo" rev-list --reverse "$merge_base"..HEAD); do
    git -C "$verify_tree" switch -q --detach "$sha" || { check_status=$?; break; }
    visited="$visited$sha"$'\n'
    false || { check_status=$?; break; }
  done
  if [[ "$check_status" -eq 0 ]]; then
    fail_test "a failed per-commit check did not fail verification"
  fi
  assert_equal "$first_sha"$'\n' "$visited" \
    "verification continued past the first failing commit"

  check_status=0
  for sha in $(git -C "$repo" rev-list --reverse "$merge_base"..HEAD); do
    git -C "$verify_tree" switch -q --detach "$sha" || { check_status=$?; break; }
    git -C "$verify_tree" diff-tree --check "$sha^" "$sha" || { check_status=$?; break; }
  done
  if [[ "$check_status" -ne 0 ]]; then
    fail_test "a clean history failed the per-commit checks"
  fi

  git -C "$repo" worktree remove "$verify_tree"
  rmdir "$verify_root"
}

test_docs
test_autosquash_fixup
test_full_rebuild
printf 'recommit workflow fixtures passed\n'
