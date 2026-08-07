# Ask Exemplar reference

Read only the sections that match the Target.

## Routing table

Route on observable signals in the Target. Select the one or two Exemplars with the
strongest fit. Treat each entry as a research lead, then verify it with current primary
sources.

| Target signal | Research leads | Observable basis |
| --- | --- | --- |
| `SKILL.md`, agent instructions, prompt, or tool definition | Anthropic skill and prompt-engineering guidance | skill structure, progressive disclosure, tool use, evaluation design |
| TypeScript generics or type-level code | Total TypeScript and TypeScript documentation | inference, safe types, ergonomic types |
| Ruby, Rails, `Gemfile`, or `config/routes.rb` | Rails Doctrine and shipped Rails conventions | convention over configuration, cohesive applications, low ceremony |
| HTTP client, SDK, public API, or packaging | Requests, Flask, and Click | humane APIs, sensible defaults, hard-to-misuse interfaces |
| Python standard-library idiom or readability | PEP 20, PEP 8, and Python documentation | one clear way, readable and idiomatic Python |
| UI component, CSS, or interaction state | Apple HIG, WCAG, and shipped design systems | states, alignment, affordances, input access, contrast |
| Documentation, README, DX, blog, or changelog | Stripe documentation, Vercel documentation, and Divio | runnable examples, information types, progressive disclosure |
| Feature scope or work to cut | Shape Up and shipped focused products | one primary need, bounded scope, deliberate omissions |
| CLI flag, output, or UX | `gh`, Click, and Typer | discoverable help, human defaults, machine output, actionable errors |
| Distributed system, data, or reliability | Google SRE and documented production systems | failure modes, idempotency, backpressure, recovery |
| Tests | xUnit Test Patterns, pytest, and maintained test tools | fixtures, real dependencies, stable test boundaries |
| Tweet, aphorism, or short voice-driven line | the named writer's published corpus | first-read parse, compression, clean antithesis, original universal insight |

For a multi-domain Target, select the dominant axis plus one secondary axis and state the
choice. When a research lead has no current citable basis for the Target, do not select it.

## Evaluation rubrics

Check the Target against each criterion in the `criterion`, `bar`, `current`, `fix`
table. When no rubric below matches the Target, derive the criteria from the routing
table's observable basis and the researched evidence.

**Agent Skill:** The description states what the skill does and, for a model-invocable
skill, when to use it; the
SKILL.md body stays focused and under 500 lines; reference files sit one level deep;
a concrete example shows the output shape; `evals/evals.json` holds three or more
evals with objectively checkable expectations.

**UI:** Empty, loading, and error states exist; spacing and optical alignment are clear;
motion has a purpose and can be interrupted; copy names the action; every state has a
next action; focus, keyboard, and touch input work; contrast meets the applicable standard.

**Documentation and DX:** The quick start runs as written; tutorial, how-to, reference,
and explanation content remain distinct; every sample runs; complexity appears only when
needed; errors and edge cases are documented; each section has one clear purpose.

**API and library:** The common case has one clear call; defaults are useful; configuration
is optional; errors are typed and actionable; required boilerplate is small; names reveal
intent; the interface is hard to misuse.

**CLI:** Help is discoverable; the human default is readable; machine-readable output is
available; exit codes are reliable; errors go to stderr; scripts have a non-interactive
path.

**Scope:** The Target solves a stated need; each surface has one primary action; removing
each optional part causes a clear loss; speculative capability stays outside the boundary.

**Short writing:** The first read parses without repair; every word earns its place; any
antithesis is clean; the idea is universal but not a paraphrase of the named writer; sound
and rhythm serve the intended voice.

## Worked example

Target: A CLI test suite implements about 50 lines of custom `http.server` classes to test
an HTTP client. The compact Evaluation brief:

```markdown
## Decision Brief

### Standard Finding
Dominant convention: maintained HTTP-client test suites use a real local test server or
a maintained server fixture, not custom server infrastructure. Confidence: high, based
on the current test suites of maintained HTTP clients.

### Exemplars
Requests and the pytest ecosystem, selected because the Target is a Python HTTP client
test suite and both have current, citable test infrastructure. Confidence: high, based
on their current test suites and documentation.

### Observable criteria
| criterion | bar | current | fix |
| --- | --- | --- | --- |
| Server fixture | maintained fixture | ~50 custom `http.server` lines | adopt `pytest-httpserver` |
| Test support code | none beyond fixtures | custom support module | delete the support module |

### Recommendation
Replace the custom server classes with the `pytest-httpserver` fixture and delete the
support module. Confidence: high, based on the tool's confirmed API and maintenance
status.

### Evidence limits
Coverage Limit: the source check covered the Python test ecosystem only.

### Top Fixes

1. Custom `http.server` classes duplicate a maintained fixture. Fix: adopt
   `pytest-httpserver` and delete the support module. Confidence: high. Tradeoff: one
   new development dependency; the shipped runtime stays unchanged.
```

In a real run, each material claim carries a source link; this example omits them.
