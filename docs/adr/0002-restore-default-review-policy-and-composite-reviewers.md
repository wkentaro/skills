# Restore a Default Review Policy and Composite Review Skills

Status: Accepted

Supersedes ADR-0001.

Review-fix uses a documented Default Review Policy when the caller supplies no Review Brief. An explicit Review Brief still replaces that default, so callers can select one skill, several skills, or an ad-hoc concern without the default silently broadening their request.

The Default Review Policy contains five report-only Review Requests: `code-review`, `brooks-review`, `ask-exemplar`, `zero-tech-debt` analysis, and `writing-code` audit. This restores the useful no-argument workflow from before ADR-0001 while omitting the retired `simplify` and `review` dependencies.

Review Requests may use Leaf or Composite Review Skills. A Composite Review Skill may delegate bounded work, but its complete Reviewer Tree is preflighted and inherits the report-only boundary. Top-level requests are serialized when necessary to leave enough agent capacity for descendants.

ADR-0001 made every Review Policy caller-owned and every Reviewer non-delegating to expose fan-out and decouple review-fix from particular review types. In practice, that made the common no-argument invocation stop for a question and rejected `code-review`, the primary correctness review, because its Standards and Spec axes use separate agents. The visible Default Review Policy and full-tree provenance retain the transparency goal without imposing those usability costs.

Review-fix still leaves repairs uncommitted and never owns rebases, forge comments, or pushes. Restoring convenient review selection does not broaden publication authority.
