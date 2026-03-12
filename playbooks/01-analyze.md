# Phase 1: Analyze

Using the repo profile from Phase 0, infer the project's architecture and conventions (brownfield) or prescribe them (greenfield).

---

## Brownfield Analysis

If `has_existing_code` is true, perform the following analysis on the existing codebase.

### 1. Architecture Layers

Map the directory structure to conceptual layers. Not every project has all layers — record only what exists.

| Layer | Purpose | Example directories |
|-|-|-|
| Types | Shared type definitions, interfaces, schemas | types/, models/, schemas/, interfaces/ |
| Config | Configuration loading and validation | config/, settings/, env/ |
| Data | Database access, repositories, data transformations | db/, repositories/, dal/, store/ |
| Service | Business logic, use cases, domain operations | services/, domain/, usecases/, core/ |
| Runtime | Application entry points, server setup, CLI commands | cmd/, server/, main.*, app.*, bin/ |
| UI | Presentation layer, components, templates | components/, views/, templates/, pages/, routes/ |

Identify **dependency directions**: layers should depend downward (UI → Service → Data → Types). Flag any upward dependencies as architectural concerns.

### 2. Conventions

Examine existing code for patterns. Record:

- **Naming**: File naming (camelCase, kebab-case, snake_case), export naming, test file naming.
- **File organization**: One class/function per file vs. grouped, barrel exports (index files), co-located tests vs. separate test directory.
- **Import conventions**: Absolute vs. relative imports, path aliases, import ordering.
- **Error handling**: Exceptions, Result types, error codes, error boundary patterns.

### 3. Build / Test / Lint Commands

Document the exact commands from the repo profile. Include:

- **Build**: `build_cmd` — full invocation, any required environment variables.
- **Test**: `test_cmd` — how to run all tests, how to run a single test file.
- **Lint**: `lint_cmd` — linting and formatting commands, auto-fix variants.

### 4. Module Boundaries

For each top-level module in `module_structure`:

- What is its responsibility?
- What does it depend on?
- What depends on it?
- Is it independently testable?

### 5. Three-Tier Boundaries

Classify agent actions into three tiers based on the project's risk profile:

| Tier | Meaning | Examples |
|-|-|-|
| **Always** | Agent can do this autonomously | Fix lint errors, add tests, update docs, refactor within a module |
| **Ask** | Agent should propose and wait for approval | Cross-module changes, new dependencies, API changes, schema migrations |
| **Never** | Agent must not do this | Delete production data paths, modify auth/security without review, change CI secrets |

Derive these from the codebase's maturity, test coverage, and risk areas.

### 6. Existing Harness Gaps

Compare what the project already has against what a complete harness provides:

- [ ] Agent instruction files (CLAUDE.md, AGENTS.md)
- [ ] ARCHITECTURE.md
- [ ] Knowledge base (`docs/` directory with design-docs, exec-plans, references)
- [ ] Core beliefs (`docs/design-docs/core-beliefs.md`)
- [ ] Quality scoring (`docs/QUALITY_SCORE.md`)
- [ ] Tech debt tracking (`docs/tech-debt-tracker.md`)
- [ ] ADR directory and template
- [ ] CI agent-lint job
- [ ] .editorconfig
- [ ] Documented build/test/lint commands
- [ ] Pre-commit hooks (husky/lint-staged, pre-commit framework, grumphp)
- [ ] Lint configuration (eslint, ruff, golangci-lint, phpstan)
- [ ] Composite `check` command (runs format → lint → build → test in sequence)
- [ ] Architectural enforcement linters (custom rules for layer violations)

Mark each as **exists**, **partial**, or **missing**.

Determine the lint configuration strictness level: **minimal** (errors only), **moderate** (errors + key warnings), or **strict** (all recommended rules enabled). Record this as part of the fail-fast feedback analysis alongside pre-commit hook configuration.

### 7. Monorepo Analysis

If `monorepo` is true in the repo profile, perform the following additional analysis:

- **Per-package analysis**: Analyze each workspace package independently using its per-package profile from Phase 0. Apply the same architecture layers, conventions, and module boundary analysis to each package.
- **Cross-package dependency mapping**: Determine which packages import or depend on which other packages. Use workspace dependency declarations and actual import statements.
- **Shared vs. package-specific conventions**: Identify conventions that are consistent across all packages (shared) versus those that differ per package (package-specific). Examples: a monorepo may share a single prettier config but have different lint rules per package.
- **Workspace-level boundaries**: Define what is shared (CI pipelines, root-level tooling config, workspace commands) versus what is isolated to individual packages (package-specific build steps, internal module structure).
- **Greenfield monorepo recommendation**: For greenfield monorepos, recommend a workspace structure based on the chosen stack — e.g., `packages/` for libraries, `apps/` for deployable applications, `tooling/` for shared build config.

---

## Greenfield Prescription

If `greenfield` is true, prescribe the following based on the engineer's answers from Phase 0.

### Minimal Scaffolding Principle

**CRITICAL**: Greenfield scaffolding must be **minimal**. Only generate the framework's bare minimum working skeleton — the smallest set of files needed for `build`, `test`, and `lint` to pass.

**Do NOT** create domain-specific modules, directories, or code based on the user's feature description. At greenfield stage, the architecture and problem space have not been properly designed. Creating premature structure leads to:

- Directories that get reorganized or deleted as design evolves
- Misleading ARCHITECTURE.md that describes aspiration, not reality
- Agents treating placeholder directories as established boundaries

Instead:
- Create only what the framework requires to boot (e.g., `app.module.ts`, `main.ts` for NestJS)
- List planned domains in ARCHITECTURE.md under a `## Planned Modules` section with `<!-- EVOLVE -->` markers
- Let modules emerge organically as features are built

### 1. Architecture Layers — Recommended Structure

Prescribe the **minimal** idiomatic project structure for the chosen language and framework. Only include directories that the framework requires to function:

- **Go**: `cmd/{appname}/`, `internal/`, `configs/`
- **Laravel**: `app/`, `routes/`, `resources/`, `database/`, `config/`, `tests/`
- **React / Next.js**: `src/app/` or `src/pages/`, `src/lib/`
- **Python (general)**: `src/{package}/`, `tests/`
- **FastAPI**: `app/`, `tests/`
- **NestJS**: `src/`, `test/`
- **Rust**: `src/`
- **Ruby on Rails**: `app/`, `config/`, `db/`, `lib/`, `spec/` or `test/`

Do not add domain-specific subdirectories (e.g., `src/market/`, `src/auth/`). Those will be created when the features are actually built.

If the language/framework is not listed, research the community-standard layout.

### 1a. Monorepo Structure

If `monorepo` is true in the repo profile, prescribe a workspace structure using the chosen monorepo tooling:

**Turborepo + pnpm** (recommended for Node/TS):
```
apps/
  {app-name}/          # The primary application (e.g., NestJS API)
packages/              # Shared libraries (created as needed)
turbo.json             # Turborepo pipeline configuration
pnpm-workspace.yaml    # Workspace package globs
package.json           # Root package.json (workspace scripts, shared devDependencies)
```

**Nx**:
```
apps/
  {app-name}/
libs/
nx.json
package.json
```

**Cargo workspace**:
```
crates/
  {crate-name}/
Cargo.toml             # [workspace] config
```

**Go workspace**:
```
cmd/{app-name}/
internal/
go.work
```

Start with a single app and zero shared packages. Add packages to `packages/` only when code needs to be shared between multiple apps.

### 2. Conventions — Language Defaults

Prescribe community-standard conventions:

- **Naming**: Follow language idioms (snake_case for Python/Rust, camelCase for JS/TS, PascalCase for Go exported names).
- **File organization**: One module per file (Go), feature-grouped (React), or as the framework dictates.
- **Formatting**: Use the canonical formatter (gofmt, black, prettier, rustfmt).

### 3. Build / Test / Lint Commands

Prescribe the standard toolchain. For monorepos, prescribe both workspace-level and per-package commands:

- **Go**: `go build ./...`, `go test ./...`, `golangci-lint run`
- **Node/TS (single)**: `npm run build`, `npm test`, `npm run lint`
- **Node/TS (turbo monorepo)**: `pnpm build` / `turbo build`, `pnpm test` / `turbo test`, `pnpm lint` / `turbo lint`
- **Python**: `python -m build`, `pytest`, `ruff check .`
- **Rust**: `cargo build`, `cargo test`, `cargo clippy`

### 4. Three-Tier Boundaries — Defaults

For greenfield projects, lean heavier on the **Ask** tier since conventions are not yet established:

| Tier | Scope |
|-|-|
| **Always** | Fix lint/format, add unit tests, update generated docs |
| **Ask** | Create new modules, add dependencies, define API contracts, set up infrastructure, choose patterns |
| **Never** | Skip tests, commit secrets, bypass CI, remove safety checks |

### 5. Evolution Markers

Tag prescriptive sections with `<!-- EVOLVE: description -->` so they can be refined as the project matures:

```markdown
<!-- EVOLVE: Refine module boundaries once initial features land -->
<!-- EVOLVE: Tighten "Ask" tier as conventions solidify -->
<!-- EVOLVE: Add integration test strategy when external dependencies are introduced -->
```

---

### 8. Knowledge Base Assessment

Evaluate the project's readiness for a structured knowledge base:

- **Existing documentation**: Check for any docs/, documentation/, or wiki/ directories. Note what exists and what format it's in.
- **Design decisions**: Look for ADRs, design docs, RFCs, or decision logs in any format. These will be migrated to the knowledge base structure.
- **Dependency documentation**: Identify key dependencies that would benefit from LLM-optimized reference docs in `docs/references/`.
- **Quality signals**: Assess test coverage, lint compliance, and documentation freshness across modules to seed initial quality grades.

---

## Output

The analysis output is consumed by Phase 2 (Generate). Ensure all of the following are ready:

- Architecture layer mapping (inferred or prescribed)
- Conventions documentation
- Exact build/test/lint commands
- Module boundary definitions
- Three-tier boundary classification
- Gap analysis (brownfield) or evolution markers (greenfield)
- Pre-commit hook configuration (detected or prescribed)
- Lint configuration strictness level (minimal, moderate, or strict)
- Composite `check` command definition (format → lint → build → test)
- Knowledge base assessment (existing docs, design decisions, dep docs, quality signals)
- Monorepo analysis (if applicable): per-package profiles, cross-package dependency map, shared vs. package-specific conventions, workspace-level boundaries

Do not generate files yet — that is Phase 2's responsibility.
