# Dashboard UI

<!-- Keep in sync with AGENTS.md and .github/copilot-instructions.md -->

React single-page application for analytics and data visualization. Built with TypeScript, Vite, React Router, and Zustand for state management. Communicates with a REST API backend.

## Build & Run

```bash
# Install dependencies
npm install

# Dev server with hot reload
npm run dev

# Production build
npm run build

# Preview production build locally
npm run preview
```

## Test

```bash
# Run all tests (Vitest)
npm test

# Run tests matching a pattern
npm test -- --grep "test name"

# Run tests for a specific file
npx vitest run src/services/api.test.ts

# Run in watch mode
npx vitest --watch

# Run with coverage
npx vitest run --coverage
```

## Lint, Format & Type Check

```bash
# Lint (ESLint)
npm run lint

# Lint with auto-fix
npm run lint -- --fix

# Format (Prettier)
npx prettier --write .

# Check formatting without writing
npx prettier --check .

# Type check (TypeScript)
npx tsc --noEmit

# Run all checks (prettier, lint, tsc, test) in order
make check  # or npm run check

# Validate harness integrity
make verify  # or ./scripts/verify-harness.sh
```

## Pre-commit Hooks

Husky + lint-staged runs ESLint and Prettier on staged files before each commit.

## Architecture

```
src/
  components/          # Reusable UI components (Button, Modal, DataTable, Chart)
    common/            # Shared primitives (Button, Input, Card, Spinner)
    charts/            # Chart components (LineChart, BarChart, PieChart)
    layout/            # Layout components (Sidebar, Header, PageContainer)
  hooks/               # Custom React hooks (useAuth, useFetch, useDebounce)
  services/            # API client functions — all backend communication lives here
  stores/              # Zustand state stores (authStore, dashboardStore, filterStore)
  types/               # TypeScript type definitions and interfaces
  utils/               # Pure utility functions (formatDate, calculatePercentage)
  pages/               # Route-level page components (DashboardPage, SettingsPage)
  styles/              # Global styles, theme tokens, Tailwind config extensions
  assets/              # Static assets (icons, images, fonts)
public/                # Public static files served as-is
```

### Layer Rules

- **pages** import components, hooks, stores, and services
- **components** import other components, hooks, utils, and types — never services or stores directly
- **hooks** import services, stores, types, and utils — never components
- **services** import types and utils only — pure API call functions, no React dependencies
- **stores** import types and services — no React imports, no component imports
- **utils** import types only — pure functions with zero side effects
- **types** import nothing — pure type definitions

### Key Patterns

- Components receive data via props — no internal data fetching in reusable components
- Pages orchestrate data loading via hooks and stores, pass data to components
- Custom hooks encapsulate reusable stateful logic (data fetching, subscriptions, timers)
- Zustand stores hold global state with actions — co-located selectors
- API functions in `services/` return typed promises — error handling at call site
- Co-located tests: `Component.test.tsx` next to `Component.tsx`

## Conventions

- **PascalCase** for components and types (`DashboardPage`, `UserProfile`, `ChartDataProps`)
- **camelCase** for functions, hooks, variables, and store names (`useAuth`, `fetchOrders`, `dashboardStore`)
- **One component per file** — file named after the component (`DataTable.tsx`)
- **Co-located tests** — `Component.test.tsx` alongside `Component.tsx`
- **Barrel exports** — each directory has an `index.ts` re-exporting public API
- **Props interfaces** named `ComponentNameProps` (e.g., `DataTableProps`, `LineChartProps`)
- **No default exports** — use named exports everywhere for better refactoring
- **Absolute imports** via `@/` alias (e.g., `import { Button } from '@/components/common'`)
- **Hooks prefix** — all custom hooks start with `use` (`useDebounce`, `usePagination`)

## Boundaries

### Always (do without asking)
- Run `make check` (or equivalent) before committing
- Run `npx tsc --noEmit` — code must pass type checking
- Run `npm run lint` and fix all warnings
- Run `npx prettier --write .` on changed files
- Write tests for new components and hooks
- Keep components pure — no direct API calls in reusable components
- Update ARCHITECTURE.md when adding new directories or layers

### Ask first
- Adding npm packages (`npm install`)
- Changing route structure or adding new routes
- Modifying shared types in `src/types/` that affect multiple modules
- Changing the state management approach or store structure
- Adding new third-party UI libraries

### Never
- Skip pre-commit hooks with `--no-verify`
- Install packages globally — use `npx` or project-local installs
- Use `any` type — use `unknown` and narrow, or define proper types
- Direct DOM manipulation — use React refs and state
- CSS-in-JS outside the established styled system (Tailwind)
- Import from `../../../` — use the `@/` path alias
- Put API calls directly in components — use services and hooks
- Mutate state directly — use Zustand store actions or React setState
- Skip writing tests for new components or hooks

## Harness Maintenance

When the project structure changes in ways that affect this file:
- **New directory under src/**: Add it to the Architecture section with its purpose and update layer rules
- **New script added to package.json**: Document in the relevant section (Build, Test, or Lint)
- **New convention adopted**: Add to Conventions section
- **Layer dependency changed**: Update Layer Rules to reflect the new boundary
- Keep all command examples runnable — verify against `package.json` scripts
