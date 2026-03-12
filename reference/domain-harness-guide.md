# Domain-Aware Harness Guide

Some projects face hostile external boundaries: inconsistent third-party schemas, unreliable connections, rate limits, auth quirks, eventual consistency, and ambiguous error states. These projects need harnesses that go beyond standard code quality — they need **boundary control and replayability** as first-class infrastructure.

This guide applies when the Phase 1 analysis detects significant external service integration: API platforms, payment processors, exchange connectors, data pipelines, multi-provider aggregators, or any system where external data flows are a core concern.

---

## When This Guide Applies

Generate domain-aware harness artifacts when the target repo exhibits:

- Multiple external API integrations
- Financial transactions or fund movement
- Real-time data streams (websockets, SSE, polling)
- Multi-provider aggregation (normalizing data from diverse sources)
- Security-sensitive operations (signing, auth, secrets management)
- Reconciliation or ledger-style consistency requirements

---

## Domain Harness Principles

### 1. All External Data Is Untrusted at the Boundary

No raw external payload should leak inward. Parse, validate, and normalize immediately at the connector layer.

```
External API → Connector (parse + validate) → Canonical Domain Types → Service Logic
```

The platform should have **one canonical internal domain model**. Orders, balances, trades, users, events — whatever the domain — should have internal shapes that are provider-agnostic. Connectors translate between provider-specific weirdness and the canonical domain. Nothing more.

### 2. Connectors Are Adapters, Not Mini-Products

Each external integration module should:

- Accept raw external data
- Parse it into a structured intermediate representation
- Validate against the expected schema
- Normalize into canonical domain types
- Surface structured errors for anything unexpected

Connectors should be thin, testable, and isolated. Business logic does not live here.

### 3. Every Important Failure Mode Must Be Reproducible

Build fixtures, simulators, and replay harnesses for critical failure scenarios:

- Rate-limit responses
- Connection disconnect/reconnect
- Sequence gaps in real-time streams
- Stale snapshots
- Partial operations (e.g., partial fills, partial transfers)
- Cancel/replace races
- Authentication failures (signature errors, token expiry, nonce drift)
- Out-of-order events
- Timeout and retry exhaustion

These fixtures should be runnable in CI and usable by agents during development.

### 4. Every Critical Action Must Be Observable

An agent should be able to answer:

- Why did this operation fail?
- What external response caused it?
- What retry logic ran?
- What state transition occurred?
- What trace and audit ID tie it together?

This requires structured logging, distributed tracing, and clear audit trails. Observability is not a nice-to-have — it's what makes agents capable of debugging production issues autonomously.

### 5. Every Production Rule Should Eventually Become a Harness Rule

If a team says "never log secrets," that should be linted.
If a team says "never trust external shapes," that should be tested.
If a team says "execution must be idempotent," that should be enforced by harnesses and invariants.

The progression: **social rule → documentation → automated check → deleted documentation**.

---

## Recommended Artifacts for Domain-Aware Projects

When domain analysis detects hostile external boundaries, generate these additional artifacts:

### docs/SECURITY.md

Security-sensitive operations documentation:

- Signing and secrets management conventions
- Auth flow documentation
- Audit logging requirements
- Sensitive data handling rules (what gets logged, what doesn't)
- Key rotation procedures

### docs/RELIABILITY.md

Reliability and resilience documentation:

- Retry strategies and backoff policies
- Idempotency requirements and implementation patterns
- Circuit breaker conventions
- Timeout policies per external service
- Reconciliation procedures
- Replay and recovery documentation

### Tiered Review Policy

Match merge/review intensity to the code path's blast radius:

| Risk tier | Code paths | Review gate |
|-|-|-|
| Low | Docs, tooling, UI, non-critical config | Agent review may suffice |
| Medium | Business logic, API routes, internal services | Standard checks + review |
| High | Auth/signing, fund movement, reconciliation, ledger, position calculation | Strongest validation + replay tests + explicit human review |

Encode this in the three-tier boundaries: high-risk paths go in the **Never** tier (never modify without explicit review) or the **Ask** tier with an explicit callout about required validation depth.

### Test Fixtures for Failure Modes

Generate a test fixtures directory structure:

```
tests/
├── fixtures/        # Recorded or synthetic external responses
│   ├── success/     # Happy-path responses per provider
│   ├── errors/      # Error responses (rate limits, auth failures, etc.)
│   └── edge-cases/  # Partial operations, out-of-order events, etc.
├── contract/        # Contract tests against external APIs
└── replay/          # Scenario replay tests (multi-step failure sequences)
```

### Connector Architecture

Document the expected connector structure in ARCHITECTURE.md:

```
connectors/
├── {provider-a}/
│   ├── client.ts        # HTTP/WS client (thin wrapper)
│   ├── parser.ts        # Raw response → typed intermediate
│   ├── normalizer.ts    # Intermediate → canonical domain types
│   ├── errors.ts        # Provider-specific error handling
│   └── __tests__/       # Unit tests with fixtures
├── {provider-b}/
│   └── ...
└── types.ts             # Shared connector interfaces
```

Each connector follows the same pattern: **client → parser → normalizer**. The service layer never sees provider-specific types.

---

## Integration with Standard Harness

Domain-aware artifacts complement the standard harness:

- **CLAUDE.md** — Add a "Domain Rules" section covering boundary validation, connector conventions, and security requirements.
- **AGENTS.md** — Add pointers to `docs/SECURITY.md`, `docs/RELIABILITY.md`, and the test fixtures directory in the "Where to Look" table.
- **ARCHITECTURE.md** — Document the connector layer, boundary validation pattern, and canonical domain types.
- **QUALITY_SCORE.md** — Grade connectors on test coverage, fixture completeness, and error handling.
- **Three-tier boundaries** — Place high-risk code paths (auth, payments, reconciliation) explicitly in the Ask or Never tier.
- **CI** — Add contract test and replay test stages.
- **verify-harness.sh** — Check that every connector has corresponding test fixtures.

---

## The Core Insight

For domain-aware projects, the harness is not just about code quality. It's about making the hostile external world legible and reproducible for agents. An agent that can replay a rate-limit scenario, inspect the retry trace, and verify the recovery behavior can fix connector bugs autonomously. An agent that can only read the connector source code is guessing.

The harness turns hostile external boundaries into predictable, testable, agent-legible interfaces.
