---
name: dictation
description: Handles voice-dictated requests with a readback and targeted transcription checks, either once or for the current conversation.
disable-model-invocation: true
argument-hint: "<dictated request>|on|off"
---

# Dictation

Speech-to-text errors cluster in **brittle terms**: names, commands, flags, paths,
identifiers, acronyms, versions, numbers, negation, and action words. Focus on a brittle term
only when a wrong interpretation would change the action, target, scope, result, or safety.
Accept ordinary wording as given.

## Invocation

Read the argument text that follows the explicit skill invocation. Match the control words
after trimming whitespace and without case sensitivity. Treat a control word as a control
only when it is the entire argument.

- `on`: Enable dictation mode for the current conversation. Confirm the new state. Apply the
  protocol to each later user message until the mode is disabled.
- `off`: Disable dictation mode. Confirm the new state. Treat later messages as normal text.
- Any other non-empty argument: Apply the protocol to that request once. Preserve the current
  mode state. A later clarification is normal text when the mode is off.
- No argument: Report whether dictation mode is on or off, then state that this skill accepts
  `on`, `off`, or a dictated request.

Initialize dictation mode as off in each new conversation. Store its state only in the
current conversation. Control invocations do not receive a `Heard:` readback.

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
3. Proceed in the same turn when all dependent terms are resolved. The readback is an error
   check, not a confirmation gate.
4. When two or more credible interpretations remain, ask one focused question before the
   dependent work. Complete every independent part of the request while that part is
   blocked. Mutate state only when the action and its target are both resolved.

The protocol is complete when every consequential ambiguity is resolved and stated, or is
isolated behind a specific question, and all independent work is complete.
