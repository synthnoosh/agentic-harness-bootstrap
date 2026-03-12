# Harness Engineering Principles — Audit Checklist

Use this checklist to evaluate changes or repository state against each principle. Each criterion under a principle must be satisfied for a PASS verdict. Any unmet criterion is a GAP.

---

## 1. Deterministic Verification

Every agent action must be verifiable by automated checks.

- [ ] New behavior introduced by the changes is covered by at least one automated test.
- [ ] CI runs lint, typecheck, build, and test on every PR.
- [ ] No new code path relies solely on prose instructions ("always check for X") without a corresponding automated check.
- [ ] Pre-commit hooks are configured for fast checks (lint, format).
- [ ] The `check` command (composite: format + lint + build + test) exists and passes.

**GAP signal**: Untested new behavior. CI that doesn't run on PRs. Prose-only guardrails with no enforcement.

---

## 2. Semantic Linting with Remediation

Linter messages should teach the agent how to fix the violation.

- [ ] Custom lint rules include remediation instructions in their error messages (not just "violation detected").
- [ ] Default linter messages are augmented or wrapped when the default message is ambiguous.
- [ ] Lint errors reference the specific file, location, and suggested fix.
- [ ] No lint rules are disabled without an accompanying comment explaining why.

**GAP signal**: Bare error messages like "import cycle detected" with no guidance. Blanket `// eslint-disable` without justification.

---

## 3. Three-Tier Boundaries

Every harness defines Always, Ask, and Never tiers.

- [ ] CLAUDE.md or AGENTS.md contains explicit Always / Ask / Never boundary sections.
- [ ] Boundaries are categorized by blast radius (low/medium/high risk).
- [ ] New capabilities or patterns introduced by the changes are reflected in the appropriate tier.
- [ ] High-risk areas (auth, payments, data migration) have the strongest validation gates.

**GAP signal**: No boundary definitions. Single flat list of rules with no priority. New high-risk code with no corresponding Never/Ask rule.

---

## 4. Fail-Fast Feedback Loops

Fast, unambiguous feedback on the most common failure modes.

- [ ] CI stages are ordered fast-to-slow (lint → typecheck → unit test → integration test).
- [ ] The fastest checks (lint, format) run as pre-commit hooks or in under 30 seconds in CI.
- [ ] Error messages from CI failures are unambiguous and actionable.
- [ ] No monolithic CI job runs everything sequentially.

**GAP signal**: Single CI job that takes 15+ minutes. Lint errors discovered only after a full test run. Ambiguous test failure output.

---

## 5. Architecture as Map

ARCHITECTURE.md is a navigational aid, not a design document.

- [ ] ARCHITECTURE.md exists and is under 300 lines.
- [ ] It includes a directory/module map, dependency rules, and boundary summary.
- [ ] It answers "where does this type of code live?" and "what depends on what?" quickly.
- [ ] Modules listed in ARCHITECTURE.md correspond to actual directories.
- [ ] No history, meeting notes, or "vision" prose — just structure and rules.
- [ ] New modules introduced by the changes are reflected in the map.

**GAP signal**: No ARCHITECTURE.md. Document over 500 lines. Modules listed that don't exist as directories. History or rationale mixed into the map.

---

## 6. Repository as System of Record

Everything agents need to know lives in the repository.

- [ ] Design decisions, product context, and engineering conventions are documented in `docs/`.
- [ ] No critical context exists only in Slack, Google Docs, wikis, or meeting notes.
- [ ] The `docs/` knowledge base has an index (docs/README.md or docs/design-docs/index.md).
- [ ] ADRs are used for architectural decisions (docs/adr/).
- [ ] Changes that introduce new patterns or conventions update the relevant docs.

**GAP signal**: References to external-only docs ("see the wiki", "as discussed in Slack"). New patterns with no documentation. Missing docs/ directory.

---

## 7. Progressive Disclosure

Give agents a map, not a 1,000-page instruction manual.

- [ ] AGENTS.md (or CLAUDE.md) is concise — under ~150 lines for the primary entry point.
- [ ] Detailed information is in linked documents, not inlined.
- [ ] A "Where to Look" table or equivalent maps needs to documents.
- [ ] No monolithic instruction file that tries to cover everything.
- [ ] Agent files use pointers (`→ see [doc](path)`) rather than duplicating content.

**GAP signal**: AGENTS.md over 300 lines. Full conventions duplicated across multiple files. No pointers to deeper docs.

---

## 8. Mechanical Enforcement over Documentation

When docs fail, promote the rule to code.

- [ ] Recurring review comments have been encoded as lint rules, tests, or structural checks.
- [ ] Architecture boundaries are enforced by tooling (import restrictions, layer checks), not just prose.
- [ ] No rule in CLAUDE.md/AGENTS.md has been violated more than twice without a corresponding automated check being added.
- [ ] CI includes structural validation (e.g., verify-harness.sh, architecture boundary checks).

**GAP signal**: Same review comment given repeatedly. Prose rules that agents keep violating. No verify-harness.sh or equivalent.

---

## 9. Entropy Management

Counteract entropy with quality grades, recurring cleanup, and golden principles.

- [ ] docs/QUALITY_SCORE.md exists and tracks quality grades per module/domain.
- [ ] docs/tech-debt-tracker.md exists and lists known debt with remediation plans.
- [ ] Quality grades are reviewed and updated when modules change.
- [ ] EVOLVE markers are used for planned improvements (not forgotten TODOs).
- [ ] No large blocks of dead code, duplicated helpers, or inconsistent naming introduced by the changes.

**GAP signal**: No quality tracking. Tech debt accumulating without visibility. EVOLVE markers that have been stale for months. Agent-generated code duplication.

---

## 10. Boring Tech Preference

Favor stable, composable, well-documented technologies.

- [ ] New dependencies are well-established (stable API, wide adoption, extensive documentation).
- [ ] No bleeding-edge frameworks or libraries with sparse documentation added.
- [ ] In-house utilities are preferred over opaque third-party libraries for simple, focused operations.
- [ ] New dependencies have been justified (not just "it's popular" or "it's new").

**GAP signal**: New dependency on an alpha/beta library. Framework with < 1 year of stable releases. Dependency added for a single function that could be written in-house.

---

## 11. Behavior Legibility

Make system behavior directly inspectable by agents.

- [ ] The application is bootable locally for agent-driven testing.
- [ ] Logs, metrics, or traces are accessible and queryable.
- [ ] Key user journeys can be reproduced in a test or local environment.
- [ ] Changes that affect observable behavior include updated tests or observability hooks.
- [ ] Error states are logged with correlation IDs or structured context.

**GAP signal**: No local dev environment. Agents can only read source, not observe behavior. New error paths with no logging. No way to reproduce reported bugs locally.

---

## 12. Boundary Control

All external data is untrusted at the boundary. Parse, validate, normalize immediately.

- [ ] External API responses are validated and parsed into canonical internal types at the edge.
- [ ] No raw external payloads flow through internal service logic unchecked.
- [ ] Connectors/adapters translate between external formats and internal types.
- [ ] Validation failures are captured as structured errors, not silently passed through.
- [ ] New external integrations introduced by the changes follow the connector/adapter pattern.

**GAP signal**: Raw API responses used directly in business logic. No validation on external data. Multiple inconsistent representations of the same domain concept. Silent error swallowing at boundaries.
