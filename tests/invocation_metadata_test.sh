#!/usr/bin/env bash

set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SKILLS_DIR="$REPO_DIR/skills"
failures=0

report_failure() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

read_skill_field() {
  local field=$1
  local skill_path=$2

  awk -v field="$field" '
    /^---$/ { fence += 1; next }
    fence == 1 {
      key = $0
      sub(/:.*/, "", key)
      if (key == field) {
        sub(/^[^:]+:[[:space:]]*/, "")
        print
        exit
      }
    }
  ' "$skill_path"
}

while IFS= read -r -d '' skill_path; do
  if [[ "$(read_skill_field disable-model-invocation "$skill_path")" != "true" ]]; then
    continue
  fi

  skill_name=$(read_skill_field name "$skill_path")
  if [[ -z "$skill_name" ]]; then
    report_failure "$skill_path has no skill name"
    continue
  fi

  openai_path="$(dirname "$skill_path")/agents/openai.yaml"
  if [[ ! -f "$openai_path" ]]; then
    report_failure "$skill_path has no agents/openai.yaml"
    continue
  fi

  if ! grep -q '^  allow_implicit_invocation: false$' "$openai_path"; then
    report_failure "$openai_path must disable implicit invocation"
  fi

  default_prompt=$(awk '/^  default_prompt:/ { print; exit }' "$openai_path")
  if [[ "$default_prompt" != *"\$$skill_name"* ]]; then
    report_failure "$openai_path default prompt must name \$$skill_name"
  fi
done < <(find "$SKILLS_DIR" -name SKILL.md -print0)

while IFS= read -r -d '' openai_path; do
  if ! grep -q '^  allow_implicit_invocation: false$' "$openai_path"; then
    continue
  fi

  skill_path="$(dirname "$(dirname "$openai_path")")/SKILL.md"
  if [[ ! -f "$skill_path" ]]; then
    report_failure "$openai_path has no SKILL.md"
    continue
  fi

  if [[ "$(read_skill_field disable-model-invocation "$skill_path")" != "true" ]]; then
    report_failure "$skill_path must disable model invocation"
  fi
done < <(find "$SKILLS_DIR" -path '*/agents/openai.yaml' -print0)

if ((failures > 0)); then
  exit 1
fi

printf 'invocation metadata pairs passed\n'
