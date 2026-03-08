# Storefront

<!-- Keep in sync with CLAUDE.md and .github/copilot-instructions.md -->

Laravel e-commerce application. Product catalog, shopping cart, checkout, and order management.

## Setup

```bash
composer install && npm install && npm run build
php artisan migrate
```

## Testing

```bash
# All tests
php artisan test

# Single test
php artisan test --filter=OrderTest::test_checkout_creates_order

# By suite
php artisan test --testsuite=Unit
php artisan test --testsuite=Feature
```

## Linting

```bash
# Code style (PSR-12 + Laravel preset)
./vendor/bin/pint

# Static analysis
./vendor/bin/phpstan analyse

# Run all checks (pint, phpstan, test) in order
make check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Pre-commit Hooks

GrumPHP runs Pint and PHPStan on staged files before each commit (configured in `grumphp.yml`).

## Structure

- `app/Http/Controllers/` — HTTP request handling, delegates to services
- `app/Http/Middleware/` — HTTP middleware (auth, CORS, rate limiting)
- `app/Http/Requests/` — Form request validation classes
- `app/Models/` — Eloquent models, relationships, scopes, accessors
- `app/Services/` — Business logic (checkout, inventory, pricing)
- `app/Repositories/` — Complex query builders, reporting queries
- `app/Events/` — Domain events (OrderPlaced, PaymentReceived)
- `app/Listeners/` — Event handlers (email, inventory updates)
- `app/Policies/` — Authorization policies
- `app/Providers/` — Service providers, dependency binding
- `resources/views/` — Blade templates
- `resources/js/` — Frontend JavaScript components
- `resources/css/` — Stylesheets (Tailwind CSS)
- `routes/web.php` — Web routes (session-based)
- `routes/api.php` — API routes (token-based)
- `database/migrations/` — Schema migrations (timestamped)
- `database/factories/` — Model factories for testing
- `database/seeders/` — Database seeders
- `tests/Unit/` — Isolated unit tests
- `tests/Feature/` — Full HTTP request lifecycle tests

## Conventions

- PSR-12 coding standard (Laravel Pint)
- PascalCase classes, camelCase methods, snake_case DB columns
- Form Requests for all input validation
- Service layer for business logic — thin controllers
- Repositories for complex queries only; simple CRUD on Models
- Resource classes for API responses
- PHP 8.1+ enums for status fields
- Typed properties and return types on all new code
- `config()` helper only — never `env()` outside config files

## Layer Dependencies

```
Models → Repositories → Services → Controllers → Routes
Events/Listeners handle side effects (dispatched by Services)
Form Requests validate input (used by Controllers)
Policies authorize actions (used by Controllers)
```

- Controllers call Services, never contain business logic
- Services call Repositories and Models, never touch HTTP
- Repositories encapsulate complex queries, simple queries stay on Model
- Models define relationships and scopes, no business logic

## Rules

**Always do:**
- Run `make check` (or equivalent) before committing
- Run `php artisan test` before committing
- Run `./vendor/bin/pint` to fix style
- Run `./vendor/bin/phpstan analyse` and fix issues
- Write Feature tests for endpoints, Unit tests for services
- Update ARCHITECTURE.md for structural changes

**Ask first:**
- Adding Composer or npm packages
- Creating or modifying migrations
- Changing routes or URL structure
- Modifying auth logic
- Adding service providers

**Never do:**
- Skip pre-commit hooks with `--no-verify`
- Edit `public/build/` (compiled assets)
- Modify `vendor/`
- Write raw SQL outside Repositories or migrations
- Put business logic in Controllers
- Use `env()` outside config files
- Commit `.env` files
- Skip Pint or PHPStan

## Maintenance

Update this file when:
- New directories are added under `app/` (update Structure)
- Build steps change (update Setup)
- New conventions adopted (update Conventions)
- Layer boundaries change (update Layer Dependencies)
