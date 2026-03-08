# Architecture — Dashboard UI

## Module Map

| Module | Path | Purpose |
|-|-|-|
| Pages | `src/pages/` | Route-level components — DashboardPage, SettingsPage, LoginPage |
| Common Components | `src/components/common/` | Shared UI primitives — Button, Input, Card, Spinner, Modal |
| Chart Components | `src/components/charts/` | Data visualization — LineChart, BarChart, PieChart, Sparkline |
| Layout Components | `src/components/layout/` | Page structure — Sidebar, Header, PageContainer, Footer |
| Hooks | `src/hooks/` | Custom React hooks — useAuth, useFetch, useDebounce, usePagination |
| Services | `src/services/` | API client layer — all HTTP calls to backend REST API |
| Stores | `src/stores/` | Zustand state stores — authStore, dashboardStore, filterStore |
| Types | `src/types/` | Shared TypeScript interfaces and type aliases |
| Utils | `src/utils/` | Pure utility functions — formatDate, calculatePercentage, debounce |
| Styles | `src/styles/` | Global CSS, Tailwind config extensions, theme tokens |
| Assets | `src/assets/` | Static files — SVG icons, images, fonts |
| Public | `public/` | Unprocessed static files served at root |

## Layer Diagram

```
┌─────────────────────────────────────┐
│  src/pages                          │  Route entrypoints — compose full views
├─────────────────────────────────────┤
│  src/components                     │  UI layer — reusable, stateless where possible
├─────────────────────────────────────┤
│  src/hooks                          │  Stateful logic — data fetching, subscriptions
├─────────────────────────────────────┤
│  src/stores                         │  Global state — Zustand stores with actions
├─────────────────────────────────────┤
│  src/services                       │  API client — typed HTTP functions
├─────────────────────────────────────┤
│  src/utils                          │  Pure functions — formatting, calculation
├─────────────────────────────────────┤
│  src/types                          │  Type definitions — zero runtime code
└─────────────────────────────────────┘

  src/styles   ──────────────────────  Global styles and theme
  src/assets   ──────────────────────  Static assets
```

## Dependency Rules

| Source | May Import | Must Not Import |
|-|-|-|
| pages | components, hooks, stores, services, types, utils | — |
| components | other components, hooks, utils, types | services, stores (no data fetching) |
| hooks | services, stores, types, utils | components, pages |
| stores | services, types | components, hooks, pages |
| services | types, utils | React, components, hooks, stores, pages |
| utils | types | anything with side effects |
| types | nothing | any module |

## Key Data Flows

### Dashboard Page Load
1. React Router renders `DashboardPage`
2. Page calls `useDashboardData()` hook on mount
3. Hook reads filters from `filterStore` (Zustand)
4. Hook calls `dashboardService.fetchMetrics(filters)` and `dashboardService.fetchChartData(filters)`
5. Service makes typed HTTP requests, returns `DashboardMetrics` and `ChartData[]`
6. Hook updates `dashboardStore` with response data
7. Page renders `MetricsGrid` and `ChartPanel` components with data via props

### Filter Change
1. User interacts with `FilterBar` component, which calls `onFilterChange` prop
2. Page handler calls `filterStore.setFilters(newFilters)`
3. `useDashboardData` hook reacts to store change via Zustand selector
4. Hook re-fetches data from API with new filters
5. Components re-render with updated data via props

### Authentication Flow
1. `LoginPage` renders `LoginForm` component
2. User submits → form calls `authService.login(credentials)`
3. Service posts to `/api/auth/login`, receives JWT token
4. `authStore.setToken(token)` stores in memory + localStorage
5. `authStore.setUser(decodedUser)` updates user state
6. React Router navigates to `/dashboard`
7. `useAuth` hook provides `isAuthenticated` and `user` to layout components
8. `services/api.ts` base client attaches token to all subsequent requests

## Component Patterns

| Pattern | Example | When to use |
|-|-|-|
| Presentational | `DataTable`, `BarChart` | Pure display, all data via props |
| Container/Page | `DashboardPage` | Route-level, orchestrates hooks and state |
| Compound | `Tabs` + `TabPanel` | Related components sharing implicit state |
| Hook-driven | `usePagination` + `DataTable` | Reusable stateful logic extracted to hook |

## What Doesn't Belong

| Location | What to avoid | Where it goes instead |
|-|-|-|
| components | API calls, store mutations, route logic | hooks for data, stores for state, pages for routing |
| hooks | JSX rendering, direct DOM manipulation | components render, use refs for DOM |
| services | React hooks, component state, UI logic | Pure async functions only |
| stores | React components, JSX, side effects | Stores hold state and actions only |
| utils | Side effects, API calls, stateful logic | Pure functions only — input in, output out |
| types | Runtime code, implementations | Type definitions and interfaces only |
| pages | Reusable UI logic, shared components | Extract to components/ or hooks/ |

## External Dependencies

| Dependency | Purpose | Configured In |
|-|-|-|
| React 18 | UI framework | `package.json` |
| TypeScript | Type safety | `tsconfig.json` |
| Vite | Build tool and dev server | `vite.config.ts` |
| React Router | Client-side routing | `src/pages/` route definitions |
| Zustand | State management | `src/stores/` |
| Tailwind CSS | Utility-first styling | `tailwind.config.js` |
| Vitest | Unit and component testing | `vitest.config.ts` |
| Testing Library | Component test utilities | used in `*.test.tsx` files |
| ESLint | Code linting | `.eslintrc.cjs` |
| Prettier | Code formatting | `.prettierrc` |
| Axios (or fetch wrapper) | HTTP client | `src/services/api.ts` |
