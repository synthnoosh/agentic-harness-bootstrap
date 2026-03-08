# Storefront

<!-- Keep in sync with AGENTS.md and .github/copilot-instructions.md -->

Laravel e-commerce application. Handles product catalog, shopping cart, checkout, and order management. Uses MySQL for persistence, Redis for sessions and cache, and Stripe for payments.

## Build & Run

```bash
# Install dependencies
composer install
npm install

# Build frontend assets
npm run build

# Dev server with hot reload
npm run dev     # Vite dev server (assets)
php artisan serve  # Laravel dev server (API/pages)

# Generate application key (first-time setup)
php artisan key:generate

# Run migrations
php artisan migrate

# Seed database
php artisan db:seed
```

## Test

```bash
# Run all tests
php artisan test

# Run a specific test class
php artisan test --filter=OrderTest

# Run a specific test method
php artisan test --filter=OrderTest::test_checkout_creates_order

# Run only unit tests
php artisan test --testsuite=Unit

# Run only feature tests
php artisan test --testsuite=Feature

# Run with coverage
php artisan test --coverage --min=80
```

## Lint & Format

```bash
# Fix code style (Laravel Pint — PSR-12 + Laravel preset)
./vendor/bin/pint

# Check style without fixing
./vendor/bin/pint --test

# Static analysis
./vendor/bin/phpstan analyse

# Full check (style + static analysis)
./vendor/bin/pint --test && ./vendor/bin/phpstan analyse

# Run all checks (pint, phpstan, test) in order
make check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Pre-commit Hooks

GrumPHP runs Pint and PHPStan on staged files before each commit (configured in `grumphp.yml`).

## Architecture

```
app/
  Http/
    Controllers/       # Handle HTTP requests, delegate to services, return responses
    Middleware/         # HTTP middleware (auth, CORS, rate limiting)
    Requests/          # Form request validation classes
  Models/              # Eloquent models — relationships, scopes, accessors
  Services/            # Business logic — checkout flow, inventory, pricing
  Repositories/        # Complex query builders, reporting queries
  Events/              # Domain events (OrderPlaced, PaymentReceived)
  Listeners/           # Event handlers (SendConfirmationEmail, UpdateInventory)
  Policies/            # Authorization policies (OrderPolicy, ProductPolicy)
  Providers/           # Service providers — dependency binding
resources/
  views/               # Blade templates
  js/                  # Frontend JavaScript (Vue/Alpine components)
  css/                 # Stylesheets (Tailwind CSS)
routes/
  web.php              # Web routes (session-based)
  api.php              # API routes (token-based)
database/
  migrations/          # Schema migrations (timestamped)
  factories/           # Model factories for testing
  seeders/             # Database seeders
tests/
  Unit/                # Unit tests — isolated, no HTTP, no DB
  Feature/             # Feature tests — full HTTP request lifecycle
config/                # Configuration files (per-environment via .env)
```

### Layer Rules

- **Controllers** call Services — never contain business logic directly
- **Services** call Repositories and Models — never touch HTTP request/response
- **Repositories** encapsulate complex Eloquent queries — simple queries stay on the Model
- **Models** define relationships, scopes, and accessors — no business logic
- **Form Requests** handle all input validation — controllers don't validate manually
- **Events/Listeners** handle side effects (email, notifications) — services dispatch events

## Conventions

- **PSR-12** coding standard, enforced by Laravel Pint
- **PascalCase** for classes, **camelCase** for methods and variables, **snake_case** for database columns and config keys
- **Form Requests** for all input validation (`StoreOrderRequest`, `UpdateProductRequest`)
- **Service layer** for business logic — controllers are thin
- **Repositories** only for complex queries — simple CRUD uses Eloquent directly
- **Resource classes** for API response formatting (`OrderResource`, `ProductResource`)
- **Config over constants** — use `config()` helper, not hardcoded values
- **Typed properties** and return types on all new code
- **Enums** (PHP 8.1+) for status fields (`OrderStatus::Pending`)

## Boundaries

### Always (do without asking)
- Run `make check` (or equivalent) before committing
- Run `php artisan test` before committing
- Run `./vendor/bin/pint` to fix code style
- Run `./vendor/bin/phpstan analyse` and fix issues
- Write Feature tests for new endpoints, Unit tests for services
- Update ARCHITECTURE.md when adding new directories or layers

### Ask first
- Adding Composer or npm packages
- Creating or modifying migrations (irreversible in production)
- Changing route definitions or URL structure
- Modifying authentication or authorization logic
- Adding new service providers

### Never
- Skip pre-commit hooks with `--no-verify`
- Edit compiled/built assets (`public/build/`)
- Modify `vendor/` — it is gitignored and managed by Composer
- Write raw SQL outside of Repository classes or migrations
- Put business logic in Controllers — delegate to Services
- Use `env()` outside of config files — always use `config()` helper
- Commit `.env` files — use `.env.example` as the template
- Skip Pint or PHPStan to "fix later"

## Harness Maintenance

When the project structure changes in ways that affect this file:
- **New directory added under app/**: Add it to the Architecture section with its purpose
- **New artisan command**: Document in Build & Run if it is part of the dev workflow
- **New convention adopted**: Add to Conventions section
- **Layer boundary changed**: Update Layer Rules
- Keep command examples runnable — verify against the actual `composer.json` and `artisan` commands
