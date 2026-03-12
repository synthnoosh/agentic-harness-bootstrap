# Harness Engineering Principles

Five principles for building repos that AI agents can work in reliably. These apply whether you're bootstrapping a new harness or improving an existing one.

---

## 1. Deterministic Verification Over Trust

**Principle:** Every agent action must be verifiable by automated checks. Never trust that the agent did the right thing — verify it.

**Why it matters for agents:**
Agents are confidently wrong at a rate that makes junior developers look cautious. They will write code that looks plausible, passes a cursory review, and breaks at runtime. The only reliable defense is automated verification that runs on every change.

Humans can eyeball a diff and catch subtle issues. Agents cannot self-review with the same reliability. Verification must be external and deterministic.

**Concrete example:**
A CI pipeline that runs on every PR:
```yaml
- go vet ./...
- golangci-lint run
- go test -race ./...
- go build ./...
```
This catches more agent mistakes than any amount of prompt engineering. The agent sees the failure, reads the error, and fixes it — usually correctly on the second attempt.

**Anti-pattern:**
Writing detailed instructions like "always check for nil pointers" or "make sure your error handling is correct." Agents read these, say "understood," and then write nil pointer dereferences anyway. Instructions without enforcement are wishes, not guardrails.

---

## 2. Semantic Linting With Remediation

**Principle:** Linter error messages should teach the agent how to fix the violation, not just flag it.

**Why it matters for agents:**
Humans read "import cycle detected" and think through the dependency graph. Agents read "import cycle detected" and start randomly moving imports around. The quality of the error message directly determines whether the agent fixes the problem in one shot or five.

Agents are literal interpreters. They do exactly what the error message suggests. If the message says nothing actionable, the agent guesses. If it says "move shared types to package C," the agent does that.

**Concrete example:**
Instead of:
```
Error: import cycle detected
```
Emit:
```
Error: import cycle detected: package handlers imports services which imports handlers.
Move shared types to a new package 'types/' that both can import.
Shared types to move: UserRequest, UserResponse.
```
The first message leads to 3-4 fix attempts. The second leads to one.

**Anti-pattern:**
Using off-the-shelf linter messages without customization. Default messages are written for humans who have context. Agents don't have context unless you provide it in the message.

---

## 3. Three-Tier Boundaries

**Principle:** Every harness defines three categories of agent actions: Always, Ask, and Never.

**Why it matters for agents:**
Without explicit boundaries, agents default to doing whatever seems helpful. Sometimes that's great. Sometimes that means they refactor your authentication module because they thought it "could be cleaner." Clear boundaries prevent both paralysis (agent asks about everything) and recklessness (agent changes everything).

The three tiers create a decision framework the agent can apply without judgment calls:

- **Always** — Do without asking: run tests, format code, update docs, fix lint errors.
- **Ask** — Confirm before doing: add dependencies, change public APIs, modify CI config, alter database schemas.
- **Never** — Do not do under any circumstances: delete production data, push directly to main, disable tests, remove security checks.

**Concrete example:**
In an `AGENTS.md`:
```markdown
## Boundaries

### Always
- Run `npm test` before committing
- Run `prettier --write` on changed files
- Update JSDoc when changing function signatures

### Ask
- Adding new npm dependencies
- Changing exported interfaces
- Modifying GitHub Actions workflows

### Never
- Disabling TypeScript strict mode
- Removing test files
- Changing authentication/authorization logic without review
```

**Anti-pattern:**
A single long list of "rules" with no priority or categorization. When everything is equally important, nothing is. Agents need to know the difference between "always do this" and "check with a human first."

---

## 4. Fail-Fast Feedback Loops

**Principle:** Agents work best with fast, unambiguous feedback. Structure your toolchain to give the fastest possible signal on the most common failure modes.

**Why it matters for agents:**
Every minute an agent waits for CI is a minute it could be fixing the problem. A 15-minute CI pipeline that fails on a lint error in the first 30 seconds wastes 14.5 minutes of wall-clock time. Agents iterate faster when feedback is fast.

More importantly, agents handle unambiguous errors far better than ambiguous ones. "Syntax error on line 42" gets fixed immediately. "Tests failed" with 200 lines of stack trace leads to flailing.

**Concrete example:**
Structure CI in stages, fast to slow:
```yaml
stages:
  - name: lint        # ~10 seconds
    run: eslint . && prettier --check .
  - name: typecheck   # ~30 seconds
    run: tsc --noEmit
  - name: unit-test   # ~1 minute
    run: jest --ci
  - name: integration # ~5 minutes
    run: jest --ci --config jest.integration.config.js
```
Put pre-commit hooks on the fastest checks:
```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: lint
      entry: eslint --fix
      types: [javascript, typescript]
    - id: format
      entry: prettier --write
      types_or: [javascript, typescript, json, yaml, markdown]
```
The agent gets lint feedback in seconds, not minutes.

**Anti-pattern:**
A single monolithic CI job that runs everything sequentially. The agent submits a PR, waits 20 minutes, finds out it had a typo in an import, fixes it, waits 20 more minutes. Fast feedback loops turn this into a 30-second iteration cycle.

---

## 5. Architecture as a Map, Not a Manual

**Principle:** ARCHITECTURE.md should be a navigational aid, not a design document. It tells agents where things are and what the rules are.

**Why it matters for agents:**
Agents working in unfamiliar codebases need to answer three questions fast:
1. Where does this type of code live?
2. What depends on what?
3. What am I not allowed to do?

A 50-page design document answers none of these quickly. A concise map with directory structure, dependency rules, and boundaries answers all three in under a minute of reading.

Agents have limited context windows. A 200-line ARCHITECTURE.md fits easily. A 2000-line one forces the agent to search, summarize, and potentially miss critical rules.

**Concrete example:**
```markdown
# Architecture

## Directory Map
- `cmd/` — Entry points. One subdirectory per binary.
- `internal/` — Private packages. Never import from outside this repo.
- `pkg/` — Public packages. Stable API, semver'd.
- `services/` — Business logic. Depends on `internal/`, never on `cmd/`.

## Dependency Rules
- `cmd/` -> `services/` -> `internal/`
- Nothing imports `cmd/`
- `pkg/` never imports `internal/`

## Boundaries
[Always/Ask/Never tiers here]
```

**Anti-pattern:**
An ARCHITECTURE.md that explains the history of architectural decisions, includes meeting notes, or describes the "vision" for the system. Agents don't need to know why you chose PostgreSQL over MongoDB in 2019. They need to know that database access goes through `internal/db/` and nowhere else.

---

## 6. Repository as System of Record

**Principle:** Everything agents need to know must live in the repository. Knowledge that exists only in Slack, Google Docs, or people's heads is invisible to agents.

**Why it matters for agents:**
From an agent's perspective, anything it can't access in-context while running effectively doesn't exist. A Slack discussion that aligned the team on an architectural pattern, a design decision made over a call, product context shared in a meeting — none of this is accessible to the system unless it's encoded into the repo.

This isn't just about documentation. It's about treating the repository as the single source of truth for everything an agent needs to operate: product specs, design decisions, engineering conventions, team agreements, and domain knowledge.

**Concrete example:**
A structured knowledge base co-located with the code:

```
docs/
├── design-docs/
│   ├── index.md
│   └── core-beliefs.md
├── exec-plans/
│   ├── active/
│   └── completed/
├── references/
│   └── design-system-reference-llms.txt
├── QUALITY_SCORE.md
└── tech-debt-tracker.md
```

Product specs, design docs, and execution plans are versioned alongside the code. LLM-optimized reference documents for key dependencies are co-located. Quality grades and tech debt are tracked in structured, machine-readable formats.

**Anti-pattern:**
A team wiki with important architectural context that agents never see. Design decisions made in meetings that are never written down. Product requirements in a Google Doc that the agent can't read. The fix is always the same: push the context into the repo.

---

## 7. Progressive Disclosure

**Principle:** Give agents a map, not a 1,000-page instruction manual. Start with a small, stable entry point and teach them where to look next.

**Why it matters for agents:**
Context is a scarce resource. A giant instruction file crowds out the task, the code, and the relevant docs — so the agent either misses key constraints or starts optimizing for the wrong ones. Too much guidance becomes non-guidance. When everything is "important," nothing is.

The solution is progressive disclosure: AGENTS.md is the table of contents (~100 lines), and it points to deeper sources of truth. The agent reads the map, identifies what's relevant to its current task, and navigates to the right doc.

**Concrete example:**
Instead of a monolithic AGENTS.md that duplicates every convention and rule:

```markdown
# Agent Instructions

## Commands
build: npm run build | test: npm test | lint: npm run lint | check: npm run check

## Quick Reference
- Architecture and module boundaries → [ARCHITECTURE.md](./ARCHITECTURE.md)
- Design decisions and rationale → [docs/design-docs/](./docs/design-docs/)
- Product specs and requirements → [docs/product-specs/](./docs/product-specs/)
- Quality grades by domain → [docs/QUALITY_SCORE.md](./docs/QUALITY_SCORE.md)
- Active execution plans → [docs/exec-plans/active/](./docs/exec-plans/active/)

## Boundaries
[concise Always/Ask/Never]
```

The agent gets orientation in seconds. When it needs depth, it follows the pointer.

**Anti-pattern:**
A monolithic AGENTS.md that tries to cover everything — product context, coding conventions, dependency rules, error handling patterns, deployment procedures. It rots instantly, agents can't tell what's still true, and the file quietly becomes an attractive nuisance.

---

## 8. Mechanical Enforcement Over Documentation

**Principle:** When documentation falls short, promote the rule into code. Prefer linters, tests, and structural checks over prose instructions.

**Why it matters for agents:**
Agents read documentation, say "understood," and then violate it anyway. This isn't defiance — it's the fundamental gap between comprehension and execution. A prose rule like "always validate inputs at the boundary" will be followed 70% of the time. A linter that rejects code without boundary validation will be followed 100% of the time.

The progression is: document first, observe violations, encode the rule mechanically. Every time an agent makes a mistake that documentation should have prevented, that's a signal to promote the rule from docs into tooling.

**Concrete example:**
Custom linters that enforce architectural boundaries:

```javascript
// eslint custom rule: no-direct-db-in-controllers
// Instead of documenting "don't call the database from controllers"
module.exports = {
  create(context) {
    return {
      CallExpression(node) {
        if (isDbCall(node) && isInControllerLayer(context)) {
          context.report({
            node,
            message: `[layer-violation] db.query() called in ${context.getFilename()}.
              Move this query to services/, export it as a named function,
              and import/call it from this controller.`
          });
        }
      }
    };
  }
};
```

Error messages include remediation instructions (Principle 2), and the check runs on every commit (Principle 1). The documentation becomes a description of why the rule exists, not the enforcement mechanism.

**Anti-pattern:**
Adding more and more rules to AGENTS.md and wondering why agents keep violating them. Spending Friday afternoons cleaning up "AI slop" manually instead of encoding the pattern into a linter. Human taste that lives only in review comments instead of being captured in tooling.

---

## 9. Entropy Management

**Principle:** Agent-generated codebases accumulate entropy. Counteract this with quality grades, recurring cleanup, and golden principles that are enforced mechanically.

**Why it matters for agents:**
Agents replicate patterns that already exist in the repository — even uneven or suboptimal ones. Over time, this leads to drift: inconsistent naming, duplicated helpers, degraded module boundaries, and accumulating tech debt. Without active management, the codebase gradually becomes less legible to future agent runs.

The solution is treating entropy like garbage collection: measure it, surface it, and clean it up continuously in small increments rather than painful quarterly refactors.

**Concrete example:**
A quality scoring system that grades each domain and layer:

```markdown
# Quality Score

| Domain | Code Quality | Test Coverage | Doc Freshness | Arch Compliance | Grade |
|-|-|-|-|-|-|
| Auth | A | B+ | A | A | A |
| Payments | B | B | C | B+ | B |
| Notifications | C | D | F | C | D+ |
```

A recurring background process scans for deviations from golden principles, updates quality grades, and opens targeted cleanup PRs. Most can be reviewed in under a minute and auto-merged. Known tech debt is tracked with explicit remediation plans and target dates.

**Anti-pattern:**
Spending 20% of engineer time manually cleaning up agent output. Letting tech debt compound for weeks before tackling it in painful bursts. Having no visibility into which areas of the codebase are degrading until something breaks.

---

## 10. Boring Tech Preference

**Principle:** Favor technologies that are composable, API-stable, and well-represented in the training set. Agents work best with "boring" tech.

**Why it matters for agents:**
Technologies often described as "boring" — stable APIs, predictable behavior, extensive documentation, wide adoption — tend to be easier for agents to model and work with. Novel frameworks, bleeding-edge libraries, and opaque abstractions create friction.

In some cases, it's cheaper to have the agent reimplement focused subsets of functionality than to work around opaque upstream behavior. An in-house utility with 100% test coverage and tight integration is often more agent-friendly than a third-party library with complex configuration and implicit behavior.

**Concrete example:**
Rather than pulling in a generic concurrency-limiting package with complex configuration:

```typescript
// In-house map-with-concurrency helper:
// - Tightly integrated with our OpenTelemetry instrumentation
// - 100% test coverage
// - Behaves exactly the way our runtime expects
export async function mapWithConcurrency<T, R>(
  items: T[],
  fn: (item: T) => Promise<R>,
  concurrency: number
): Promise<R[]> { /* ... */ }
```

The agent can read, understand, modify, and test this helper directly. No documentation to fetch, no version compatibility to worry about, no implicit behavior to discover.

**Anti-pattern:**
Adopting the newest framework because it's trendy, then spending weeks teaching agents how to use it. Pulling in a library for a single function and getting opaque behavior the agent can't debug. Using technologies whose documentation is sparse or whose APIs change frequently.

---

## Summary

| # | Principle | One-liner |
|-|-|-|
| 1 | Deterministic verification | Automate checks; don't trust agent output |
| 2 | Semantic linting | Error messages should teach the fix |
| 3 | Three-tier boundaries | Always / Ask / Never |
| 4 | Fail-fast feedback | Fast checks first, slow checks last |
| 5 | Architecture as map | Where things are, not why they exist |
| 6 | Repository as system of record | If agents can't see it, it doesn't exist |
| 7 | Progressive disclosure | Map first, details on demand |
| 8 | Mechanical enforcement | When docs fail, promote the rule to code |
| 9 | Entropy management | Measure, grade, clean up continuously |
| 10 | Boring tech preference | Stable, composable, well-documented tech wins |

These principles compound. Verification catches mistakes (1). Semantic linting helps agents fix them in one shot (2). Boundaries prevent mistakes in the first place (3). Fast feedback makes the loop faster (4). Architecture as map tells agents where to work (5). Repository as system of record gives agents the context they need (6). Progressive disclosure keeps context manageable (7). Mechanical enforcement replaces repeated instructions with automated checks (8). Entropy management keeps the codebase legible over time (9). And boring tech reduces friction at every step (10).
