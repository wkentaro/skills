# Skills

This context defines the language used to design skills in this repository. It
currently covers review orchestration and the Ask Exemplar vocabulary.

## Review Orchestration

**Review Brief**:
The caller's free-form description of the concerns to examine for a target. It may name review skills or describe ad-hoc focuses.
_Avoid_: Review arguments, reviewer prompt

**Review Policy**:
The caller-owned set of Review Requests resolved from a Review Brief. Ambiguity requires caller clarification; the review-and-fix skill never silently broadens or chooses the policy.
_Avoid_: Reviewer roster, review panel, default reviews

**Review Request**:
One review concern in a Review Policy, expressed as a Leaf Review Skill invocation or an ad-hoc focus.
_Avoid_: Review type, review lens

**Reviewer**:
A fresh, report-only subagent assigned exactly one Review Request. It does not delegate or modify the target.
_Avoid_: Review worker, nested reviewer

**Leaf Review Skill**:
A named review skill that one Reviewer can execute directly without delegating or modifying the target. Only leaf review skills can be named in a Review Request.
_Avoid_: Reviewer adapter, nested review skill

**Review Round**:
One bounded execution of a Review Policy: run its Reviewers, verify and aggregate their findings, apply supported fixes, and check the result. A review-fix invocation repeats fixed rounds with the same policy until a round is clean or incomplete.
_Avoid_: Review loop

**Verified Finding**:
A review claim confirmed against the target, its specification, repository rules, or observable behavior. It retains its Reviewer provenance, and only Verified Findings are eligible for repair.
_Avoid_: Reviewer opinion, suggestion

**Review Outcome**:
The status of a Review Round: `clean` when it found no Verified Findings, `fixed` when it applied and verified repairs, or `incomplete` when the requested Review Policy could not finish safely. A review-fix invocation continues after `fixed` and terminates on `clean` or `incomplete`.
_Avoid_: Pass/fail, review verdict

## Ask Exemplar

**Standard**:
An accepted formal rule or dominant convention for the decision domain. When credible sources show no consensus, there is no Standard.
_Avoid_: Best practice, default

**Standard Finding**:
The result of checking the external baseline, classified as a formal requirement, dominant convention, contested practice, or no Standard. It is undetermined only when an Evidence Gap prevents classification.
_Avoid_: Industry standard

**Exemplar**:
A person, organization, product, or method whose proven, citable work defines a high bar for the decision.
_Avoid_: Expert, guru, oracle

**Recommendation**:
The preferred feasible option after comparison with the Standard Finding and Exemplars. The user retains decision ownership.
_Avoid_: Verdict, command

**Feasible Option**:
An option that satisfies mandatory requirements and the user's hard constraints.
_Avoid_: Compliant option

**Decision Brief**:
The compact output that states the Standard Finding, one or two Exemplars, observable criteria, a Recommendation with Confidence, and linked primary sources.
_Avoid_: Research report, review

**Target**:
A decision, plan, design, completed artifact, or diff examined by Ask Exemplar. Its state selects Guidance or Evaluation.
_Avoid_: Input, subject

**Guidance**:
Comparison of an open Target with the Standard Finding and Exemplars to produce criteria and a Recommendation.
_Avoid_: Pre-review

**Evaluation**:
Comparison of a completed Target with the Standard Finding and Exemplars to check observable criteria, identify concrete gap fixes, and rank Top Fixes.
_Avoid_: Exemplar review

**Top Fixes**:
The ranked, deduplicated list of Evaluation findings. Each item contains the finding, the concrete fix, Confidence, and the tradeoff.
_Avoid_: Action items, suggestions

**Embedded Evaluation**:
A report-only Evaluation requested by a parent workflow. It returns compact Top Fixes so the parent controls all changes.
_Avoid_: Embedded edit

**Evidence Gap**:
The absence of primary evidence needed to support a Standard Finding or Exemplar. Secondary sources can give provisional context, but the gap lowers confidence and cannot be hidden.
_Avoid_: Inference, weak evidence

**Verified Source Set**:
The primary sources that support the current Consultation. It stays valid for reuse only while the domain and Standard Finding are unchanged.
_Avoid_: Permanent cache

**Consultation**:
A report-only use of Ask Exemplar that does not change the Target. Standalone use returns a Decision Brief; Embedded Evaluation returns only Top Fixes.
_Avoid_: Remediation, automatic fix

**Confidence**:
A `high`, `medium`, or `low` assessment of a material finding or Recommendation, paired with the reason for its uncertainty.
_Avoid_: Numeric score, certainty

**Coverage Limit**:
A stated boundary of the completed research that prevents an unsupported universal or world-best claim.
_Avoid_: Disclaimer
