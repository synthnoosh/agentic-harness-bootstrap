# Architecture — Storefront

## Module Map

| Module | Path | Purpose |
|-|-|-|
| Controllers | `app/Http/Controllers/` | Handle HTTP requests, delegate to services, return responses |
| Form Requests | `app/Http/Requests/` | Input validation and authorization for each endpoint |
| Middleware | `app/Http/Middleware/` | Cross-cutting HTTP concerns (auth, CORS, rate limiting) |
| Models | `app/Models/` | Eloquent models — relationships, scopes, accessors, mutators |
| Services | `app/Services/` | Business logic — checkout, inventory, pricing, order workflows |
| Repositories | `app/Repositories/` | Complex query builders, aggregation, reporting |
| Events | `app/Events/` | Domain event classes (OrderPlaced, PaymentReceived, ProductUpdated) |
| Listeners | `app/Listeners/` | Side-effect handlers (SendConfirmationEmail, UpdateInventory) |
| Policies | `app/Policies/` | Authorization rules per model (OrderPolicy, ProductPolicy) |
| Providers | `app/Providers/` | Service container bindings, event registration |
| Views | `resources/views/` | Blade templates — layouts, pages, components |
| Frontend JS | `resources/js/` | Vue/Alpine components, Vite entrypoint |
| Styles | `resources/css/` | Tailwind CSS source |
| Web Routes | `routes/web.php` | Session-based routes (storefront pages, cart, checkout) |
| API Routes | `routes/api.php` | Token-based routes (mobile app, integrations) |
| Migrations | `database/migrations/` | Schema changes (timestamped, sequential) |
| Factories | `database/factories/` | Model factories for test data generation |
| Seeders | `database/seeders/` | Database seeding for development and testing |
| Unit Tests | `tests/Unit/` | Isolated tests — no HTTP, no database |
| Feature Tests | `tests/Feature/` | Integration tests — full request lifecycle, database |
| Config | `config/` | Environment-aware configuration files |

## Layer Diagram

```
┌─────────────────────────────────────┐
│  routes/ (web.php, api.php)         │  Entrypoint — URL to controller mapping
├─────────────────────────────────────┤
│  Http/Middleware                     │  Cross-cutting: auth, CORS, throttle
├─────────────────────────────────────┤
│  Http/Controllers                   │  Request handling, response formatting
│  Http/Requests (validation)         │  Input validation via Form Requests
│  Policies (authorization)           │  Per-model authorization checks
├─────────────────────────────────────┤
│  Services                           │  Business logic and orchestration
│  Events / Listeners                 │  Async side effects
├─────────────────────────────────────┤
│  Repositories                       │  Complex queries and aggregation
├─────────────────────────────────────┤
│  Models                             │  Data layer — Eloquent ORM
├─────────────────────────────────────┤
│  database/migrations                │  Schema definitions
└─────────────────────────────────────┘

  resources/views  ──────────────────  UI layer (Blade templates)
  resources/js, resources/css  ──────  Frontend assets (Vite build)
```

## Dependency Rules

| Source | May Import | Must Not Import |
|-|-|-|
| Controllers | Services, Form Requests, Resources, Policies | Repositories directly, raw DB queries |
| Services | Repositories, Models, Events | Controllers, HTTP Request/Response |
| Repositories | Models, DB facades | Controllers, Services, HTTP layer |
| Models | Other Models (relationships) | Services, Controllers, Repositories |
| Events | Models (for payload) | Services, Controllers |
| Listeners | Services, Models | Controllers, HTTP layer |
| Form Requests | Models (for unique rules) | Services, Repositories |
| Policies | Models | Services, Repositories |

## Key Data Flows

### Checkout Flow
1. `POST /checkout` → `CheckoutController@store` with `CheckoutRequest` validation
2. Controller calls `CheckoutService::processCheckout($validatedData)`
3. Service validates inventory via `InventoryService::reserve($items)`
4. Service creates order via `OrderRepository::createWithItems($order, $items)`
5. Service processes payment via `PaymentService::charge($order)`
6. Service dispatches `OrderPlaced` event
7. `SendOrderConfirmation` listener sends email
8. `UpdateInventory` listener decrements stock
9. Controller returns `OrderResource` with 201

### Product Listing
1. `GET /products?category=electronics&sort=price` → `ProductController@index`
2. Controller calls `ProductRepository::filteredListing($filters, $sort, $perPage)`
3. Repository builds Eloquent query with scopes, eager-loads relationships
4. Controller returns `ProductResource::collection($products)` with pagination

## What Doesn't Belong

| Location | What to avoid | Where it goes instead |
|-|-|-|
| Controllers | Business logic, DB queries, complex validation | Services for logic, Repositories for queries, Form Requests for validation |
| Services | HTTP concerns (Request/Response), direct SQL | Controllers for HTTP, Repositories for queries |
| Repositories | Business rules, HTTP awareness, event dispatching | Services for rules and events |
| Models | Business logic, complex queries, HTTP concerns | Services for logic, Repositories for queries |
| Views | Business logic, direct DB queries | Controllers prepare data, Services compute it |
| Migrations | Seed data, business logic | Seeders for data, Services for logic |

## External Dependencies

| Dependency | Purpose | Configured In |
|-|-|-|
| MySQL | Primary data store | `config/database.php`, `.env` |
| Redis | Cache, sessions, queue driver | `config/database.php`, `config/cache.php` |
| Stripe (via cashier) | Payment processing | `config/services.php`, `config/cashier.php` |
| Vite | Frontend asset bundling | `vite.config.js` |
| Tailwind CSS | Utility-first CSS framework | `tailwind.config.js` |
| Laravel Pint | Code style enforcement | `pint.json` |
| PHPStan | Static analysis | `phpstan.neon` |
