---
name: hear-me
description: Handles voice-dictated requests with a readback and targeted transcription checks, either once or for the current conversation.
disable-model-invocation: true
argument-hint: "[dictated request|on|off]"
---

# Hear Me

Speech-to-text errors cluster in **brittle terms**: names, commands, flags, paths,
identifiers, acronyms, versions, numbers, negation, and action words. Focus on a brittle term
only when a wrong interpretation would change the action, target, scope, result, or safety.
Accept ordinary wording as given.

## Invocation

Treat `on` or `off` as a control only when it is the entire argument. Reply to a control
with only a confirmation of the new state.

- No argument or `on`: Enable dictation mode for the current conversation. Apply the
  protocol to each later user message until the mode is disabled.
- `off`: Disable dictation mode. Treat later messages as normal text.
- Any other non-empty argument: Apply the protocol to that request once. Preserve the
  current mode state, so a later clarification is normal text when the mode is off.

## Protocol

1. Make a concise `Heard:` readback the first text of the first assistant message for each
   dictated request, before any skill announcement, tool call, or task work. Restate the
   action, target, scope, and all consequential constraints. Use one line when it preserves
   them; otherwise use a short block.
   - Format each correction or assumption as code. Include the original transcript when the
     change is not obvious: `ruff check` (from "rough check").
   - Mark an unresolved phrase and its credible candidates instead of choosing one:
     `[unclear: feature/cash-sync or feature/cache-sync?]`.
   - Replace a secret or sensitive value with a role label such as `[API token]`.
2. Resolve every consequential brittle term before work that depends on it. Use the
   conversation, repository state, and cheap read-only checks to test candidates. Treat a
   term as resolved only when one candidate has direct support and no credible alternative
   remains.
3. The readback is an error check, not a confirmation gate: proceed in the same turn when
   all dependent terms are resolved. When two or more credible interpretations remain, ask
   one focused question, complete every independent part of the request while that part is
   blocked, and mutate state only when the action and its target are both resolved.
