# Keep Review Policy outside review-fix

Status: Superseded by ADR-0002

The review-and-fix skill accepts a caller's free-form Review Brief and resolves it into a caller-owned Review Policy, asking when routing is ambiguous instead of selecting or broadening reviews silently. It repeats bounded rounds of non-delegating review, evidence verification, repair, and checks with that policy until clean; callers own reviewer models, Git history, and publication because the former fixed roster hid fan-out and coupled orchestration to particular review types.
