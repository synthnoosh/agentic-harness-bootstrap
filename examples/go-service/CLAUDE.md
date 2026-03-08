# Order Service

<!-- Keep in sync with AGENTS.md and .github/copilot-instructions.md -->

Go API microservice for order management. Exposes REST endpoints for creating, updating, and querying orders. Uses PostgreSQL for persistence and Redis for caching.

## Build & Run

```bash
# Build
go build ./...

# Run locally
go run ./cmd/order-service

# Run with hot reload (air)
air
```

## Test

```bash
# Run all tests
go test ./...

# Run tests for a specific package
go test ./internal/handler/...

# Run a single test by name
go test ./internal/handler/... -run TestCreateOrder

# Run tests with race detector
go test -race ./...

# Run tests with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run all checks (fmt, lint, build, test) in order
make check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Lint & Format

```bash
# Lint (includes vet, staticcheck, errcheck, and more)
golangci-lint run

# Format all Go files
gofmt -w .

# Tidy module dependencies
go mod tidy
```

## Pre-commit Hooks

Pre-commit hooks run `golangci-lint` and `gofmt` on staged files (configured in `.pre-commit-config.yaml`).

## Architecture

```
cmd/order-service/       # Application entrypoint, wires dependencies
internal/handler/        # HTTP handlers — parse requests, call services, write responses
internal/service/        # Business logic — orchestrates domain operations
internal/repository/     # Data access — SQL queries, Redis operations
internal/model/          # Domain types — structs, enums, validation
pkg/middleware/          # Shared HTTP middleware — auth, logging, recovery
migrations/              # SQL migration files (golang-migrate format)
```

### Layer Rules

- **handler** imports service (never repository directly)
- **service** imports repository and model
- **repository** imports model only
- **model** has zero internal imports — pure domain types
- **pkg/middleware** has zero internal imports — reusable across services
- Nothing imports **cmd** — it is the composition root

### Key Patterns

- Dependency injection via constructor functions (`NewOrderService(repo OrderRepository)`)
- Interfaces defined by the consumer, not the implementer
- Context propagation through all layers (`ctx context.Context` as first param)
- Errors wrap with `fmt.Errorf("operation description: %w", err)` for stack traces
- Table-driven tests with `t.Run()` subtests

## Conventions

- **Naming**: PascalCase for exported identifiers, camelCase for unexported, snake_case for filenames
- **Files**: One primary type per file, named after the type in snake_case (`order_handler.go`)
- **Tests**: Same package for white-box tests, `_test` suffix package for black-box tests
- **Errors**: Define sentinel errors in the package that owns the concept (`var ErrOrderNotFound = errors.New(...)`)
- **Logging**: Structured logging via `slog` — no `fmt.Println` in production code
- **Config**: Environment variables parsed in `cmd/`, passed down as typed config structs

## Boundaries

### Always (do without asking)
- Run `make check` (or equivalent) before committing
- Run `go test ./...` before committing
- Run `golangci-lint run` and fix all warnings
- Run `go mod tidy` if dependencies changed
- Update ARCHITECTURE.md when adding new packages or changing layer boundaries
- Write table-driven tests for new handler and service functions

### Ask first
- Adding new dependencies (`go get`)
- Changing API contracts (request/response types, endpoint paths)
- Modifying database schema or adding migrations
- Changing authentication or authorization logic
- Adding new `cmd/` entrypoints

### Never
- Skip pre-commit hooks with `--no-verify`
- Modify `go.sum` manually — always use `go mod tidy`
- Skip the linter or add `//nolint` without justification
- Commit the `vendor/` directory
- Put business logic in handlers — delegate to service layer
- Use `panic()` for error handling in library code
- Import `internal/` packages from outside this module

## Harness Maintenance

When the project structure changes in ways that affect this file:
- **New package added**: Add it to the Architecture section with a one-line description and update layer rules
- **New build step**: Add it to the Build & Run section
- **New convention adopted**: Document it in Conventions
- **Dependency rule changed**: Update the Layer Rules to reflect the new boundary
- Keep all command examples runnable — test them if unsure
