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
In a `.github/copilot-instructions.md` or `AGENTS.md`:
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

## Summary

| Principle | One-liner |
|-|-|
| Deterministic verification | Automate checks; don't trust agent output |
| Semantic linting | Error messages should teach the fix |
| Three-tier boundaries | Always / Ask / Never |
| Fail-fast feedback | Fast checks first, slow checks last |
| Architecture as map | Where things are, not why they exist |

These principles compound. Deterministic verification catches mistakes. Semantic linting helps agents fix them in one shot. Three-tier boundaries prevent mistakes in the first place. Fail-fast feedback makes the whole loop faster. And a clear architecture map means agents know where to work without wandering the codebase.
