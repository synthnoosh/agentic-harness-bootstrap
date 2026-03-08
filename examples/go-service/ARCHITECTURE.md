# Architecture — order-service

## Module Map

| Module | Path | Purpose |
|-|-|-|
| entrypoint | `cmd/order-service/` | Main func, config loading, dependency wiring, server startup |
| handlers | `internal/handler/` | HTTP handlers — request parsing, response writing, route registration |
| services | `internal/service/` | Business logic — order workflows, validation, orchestration |
| repositories | `internal/repository/` | Data access — PostgreSQL queries, Redis cache operations |
| models | `internal/model/` | Domain types — Order, LineItem, OrderStatus, value objects |
| middleware | `pkg/middleware/` | Shared HTTP middleware — authentication, request logging, panic recovery |
| migrations | `migrations/` | SQL schema migrations (golang-migrate format, sequential numbering) |

## Layer Diagram

```
┌─────────────────────────────────┐
│  cmd/order-service  (main)      │  Composition root — wires everything
├─────────────────────────────────┤
│  pkg/middleware                  │  Cross-cutting: auth, logging, recovery
├─────────────────────────────────┤
│  internal/handler               │  HTTP layer: routes, request/response
├─────────────────────────────────┤
│  internal/service               │  Business logic: workflows, rules
├─────────────────────────────────┤
│  internal/repository            │  Data access: SQL, cache
├─────────────────────────────────┤
│  internal/model                 │  Domain types: structs, enums
└─────────────────────────────────┘
```

## Dependency Rules

| Source | May Import | Must Not Import |
|-|-|-|
| cmd/order-service | handler, service, repository, model, middleware | — |
| internal/handler | service, model | repository, cmd |
| internal/service | repository, model | handler, cmd |
| internal/repository | model | handler, service, cmd |
| internal/model | stdlib only | any internal package |
| pkg/middleware | stdlib, third-party | any internal package |
| migrations | n/a (SQL files) | n/a |

## Key Data Flows

### Create Order
1. `POST /api/v1/orders` → `handler.CreateOrder` parses JSON body into `model.CreateOrderRequest`
2. Handler calls `service.CreateOrder(ctx, req)` — validates line items, calculates totals
3. Service calls `repository.InsertOrder(ctx, order)` — executes INSERT within transaction
4. Service publishes `OrderCreated` event (if event bus configured)
5. Handler writes `201 Created` with `model.OrderResponse`

### Get Order
1. `GET /api/v1/orders/:id` → `handler.GetOrder` extracts order ID from path
2. Handler calls `service.GetOrder(ctx, id)`
3. Service checks Redis cache first via `repository.GetCachedOrder(ctx, id)`
4. Cache miss → `repository.GetOrder(ctx, id)` queries PostgreSQL
5. Service populates cache, returns `model.Order`
6. Handler serializes to `model.OrderResponse`, writes `200 OK`

## What Doesn't Belong

| Location | What to avoid | Where it goes instead |
|-|-|-|
| internal/handler | Business logic, SQL queries, direct DB access | internal/service for logic, internal/repository for data |
| internal/service | HTTP concerns (status codes, headers), raw SQL | internal/handler for HTTP, internal/repository for SQL |
| internal/repository | Business rules, HTTP awareness, response formatting | internal/service for rules, internal/handler for HTTP |
| internal/model | Methods with side effects, database tags | Keep pure — validation logic only |
| pkg/middleware | Application-specific logic, service calls | internal/handler for app-specific concerns |
| cmd/ | Business logic, route definitions | Wiring only — construct and connect |

## External Dependencies

| Dependency | Purpose | Configured In |
|-|-|-|
| PostgreSQL | Primary data store for orders | `cmd/order-service/main.go` via env vars |
| Redis | Order cache, session store | `cmd/order-service/main.go` via env vars |
| golang-migrate | Schema migration runner | `migrations/` directory |
| chi (or gorilla/mux) | HTTP router | `internal/handler/router.go` |
| slog | Structured logging | stdlib, configured in `cmd/` |
