# Dashboard UI

<!-- Keep in sync with CLAUDE.md and .github/copilot-instructions.md -->

React SPA for analytics and data visualization. TypeScript, Vite, React Router, Zustand.

## Setup

```bash
npm install
```

## Testing

```bash
# All tests (Vitest)
npm test

# Single test by pattern
npm test -- --grep "test name"

# Single file
npx vitest run src/services/api.test.ts

# Watch mode
npx vitest --watch
```

## Linting

```bash
# ESLint
npm run lint

# Prettier
npx prettier --write .

# TypeScript type check
npx tsc --noEmit

# Run all checks (prettier, lint, tsc, test) in order
make check  # or npm run check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Pre-commit Hooks

Husky + lint-staged runs ESLint and Prettier on staged files before each commit.

## Structure

- `src/components/` — Reusable UI components (Button, Modal, DataTable, Chart)
  - `common/` — Shared primitives (Button, Input, Card, Spinner)
  - `charts/` — Chart components (LineChart, BarChart, PieChart)
  - `layout/` — Layout components (Sidebar, Header, PageContainer)
- `src/hooks/` — Custom React hooks (useAuth, useFetch, useDebounce)
- `src/services/` — API client functions, all backend communication
- `src/stores/` — Zustand state stores (authStore, dashboardStore)
- `src/types/` — TypeScript type definitions and interfaces
- `src/utils/` — Pure utility functions (formatDate, calculatePercentage)
- `src/pages/` — Route-level page components (DashboardPage, SettingsPage)
- `src/styles/` — Global styles, theme tokens
- `src/assets/` — Static assets (icons, images, fonts)

## Conventions

- PascalCase for components and types, camelCase for functions and hooks
- One component per file, named after the component
- Co-located tests: `Component.test.tsx` next to `Component.tsx`
- Barrel exports (`index.ts`) from each directory
- Props interfaces named `ComponentNameProps`
- Named exports only — no default exports
- Absolute imports via `@/` alias
- All custom hooks prefixed with `use`

## Layer Dependencies

```
types (zero imports) → utils → services → stores → hooks → components → pages
```

- pages import components, hooks, stores, services
- components import other components, hooks, utils, types — never services/stores
- hooks import services, stores, types, utils — never components
- services import types, utils only — no React dependencies
- stores import types, services — no React or component imports
- utils import types only — pure functions
- types import nothing

## Rules

**Always do:**
- Run `make check` (or equivalent) before committing
- Run `npx tsc --noEmit` — must pass type checking
- Run `npm run lint` and fix warnings
- Format changed files with Prettier
- Write tests for new components and hooks
- Update ARCHITECTURE.md for structural changes

**Ask first:**
- Adding npm packages
- Changing routes or adding pages
- Modifying shared types affecting multiple modules
- Changing state management approach
- Adding UI libraries

**Never do:**
- Skip pre-commit hooks with `--no-verify`
- Install packages globally
- Use `any` type
- Direct DOM manipulation (use React refs/state)
- CSS-in-JS outside Tailwind
- Use relative imports like `../../../` (use `@/`)
- Put API calls directly in components
- Mutate state directly
- Skip tests for new components or hooks

## Maintenance

Update this file when:
- New directories added under `src/` (update Structure and Layer Dependencies)
- New scripts added to `package.json` (update Setup/Testing/Linting)
- New conventions adopted (update Conventions)
- Layer boundaries change (update Layer Dependencies)
