## Agent skills

### Invocation metadata

User-invoked skills use both host controls: `disable-model-invocation: true` in
`SKILL.md` for Claude and `policy.allow_implicit_invocation: false` in
`agents/openai.yaml` for Codex. Keep the two controls paired. A subagent cannot invoke
a `disable-model-invocation` skill by name; an orchestrator that embeds one gives the
subagent the skill's directory path to read directly.

### Issue tracker

Issues are tracked with GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Triage uses the five standard labels. See `docs/agents/triage-labels.md`.

### Domain docs

Domain docs use a single-context layout. See `docs/agents/domain.md`.

### Skill evals

Skill changes are gated by the skill's evals. See `docs/agents/skill-evals.md`.
