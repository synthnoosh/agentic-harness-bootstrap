# Order Service

<!-- Keep in sync with CLAUDE.md and .github/copilot-instructions.md -->

Go API microservice for order management. REST API backed by PostgreSQL and Redis.

## Setup

```bash
go build ./...
```

## Testing

```bash
# All tests
go test ./...

# Single package
go test ./internal/handler/... -run TestCreateOrder

# With race detection
go test -race ./...
```

## Linting

```bash
golangci-lint run
gofmt -w .
go mod tidy

# Run all checks (fmt, lint, build, test) in order
make check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Pre-commit Hooks

Pre-commit hooks run `golangci-lint` and `gofmt` on staged files (configured in `.pre-commit-config.yaml`).

## Structure

- `cmd/order-service/` — Application entrypoint, dependency wiring
- `internal/handler/` — HTTP handlers (parse request, call service, write response)
- `internal/service/` — Business logic and domain orchestration
- `internal/repository/` — Data access (SQL, Redis)
- `internal/model/` — Domain types, structs, enums, validation
- `pkg/middleware/` — Shared HTTP middleware (auth, logging, recovery)
- `migrations/` — SQL migration files (golang-migrate)

## Conventions

- PascalCase for exports, camelCase for unexported, snake_case for filenames
- One primary type per file, named after the type (`order_handler.go`)
- Interfaces defined by the consumer, not the implementer
- Errors wrap with `fmt.Errorf("...: %w", err)`
- Table-driven tests with `t.Run()` subtests
- Context as first parameter in all layer functions
- Structured logging via `slog` — no `fmt.Println`
- Dependency injection via constructors

## Layer Dependencies

```
model (zero imports) → repository → service → handler → cmd
```

- handler imports service (never repository)
- service imports repository and model
- repository imports model only
- pkg/middleware has zero internal imports
- Nothing imports cmd

## Rules

**Always do:**
- Run `make check` (or equivalent) before committing
- Run `go test ./...` before committing
- Run `golangci-lint run` and fix warnings
- Run `go mod tidy` if dependencies changed
- Update ARCHITECTURE.md when adding packages or changing boundaries
- Write table-driven tests for handlers and services

**Ask first:**
- Adding dependencies (`go get`)
- Changing API contracts (paths, request/response types)
- Modifying database schema or migrations
- Changing auth logic
- Adding new `cmd/` entrypoints

**Never do:**
- Skip pre-commit hooks with `--no-verify`
- Modify `go.sum` manually
- Skip linter or add `//nolint` without justification
- Commit `vendor/`
- Put business logic in handlers
- Use `panic()` for error handling
- Import `internal/` from outside this module

## Maintenance

Update this file when:
- New packages are added (update Structure and Layer Dependencies)
- Build steps change (update Setup)
- New conventions are adopted (update Conventions)
- Dependency rules change (update Layer Dependencies)
