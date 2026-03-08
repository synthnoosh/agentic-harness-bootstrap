# Phase 0: Discover

Discover the target repository's characteristics. This phase produces a **repo profile** that all subsequent phases consume.

There are two paths through this phase:

- **Brownfield** — existing code detected; map what exists.
- **Greenfield** — empty or near-empty repo; ask structured questions.

---

## Step 1: Determine Brownfield vs Greenfield

Scan the repository root and one level of subdirectories for **source files** (exclude config files, dotfiles, LICENSE, README, and lock files).

- **5 or more source files** → **Brownfield**. Proceed to Step 3.
- **Fewer than 5 source files** → **Greenfield**. Proceed to Step 2.

---

## Step 2: Greenfield Questions

When the repo is empty or near-empty, ask the engineer the following questions before proceeding:

1. **What are you building?** — API service, web app, CLI tool, library, mobile app, monorepo, or something else?
2. **What language and framework?** — e.g., TypeScript + Next.js, Python + FastAPI, Go + stdlib, Rust + Axum.
3. **What CI provider?** — GitHub Actions, GitLab CI, CircleCI, Jenkins, or none yet?
4. **Any architectural preferences?** — Monorepo vs polyrepo, specific patterns (hexagonal, MVC, etc.), or constraints?

Record answers and skip to Step 4 (Repo Profile), filling in what you know and marking the rest as TBD.

---

## Step 3: Detection Signals (Brownfield)

For each signal below, run the detection method and record findings.

| Signal | Detection Method |
|-|-|
| Language(s) | File extensions, config files (package.json, pyproject.toml, go.mod, Cargo.toml, build.sbt, pom.xml, *.csproj) |
| Framework | Framework-specific files (next.config.*, angular.json, manage.py, rails, Gemfile with Rails, nuxt.config.*, vite.config.*, etc.) |
| Package manager | Lock files (package-lock.json, yarn.lock, pnpm-lock.yaml, poetry.lock, Pipfile.lock, go.sum, Cargo.lock, Gemfile.lock) |
| Build system | Makefile, build.gradle, CMakeLists.txt, npm scripts in package.json, Taskfile.yml, justfile, Rakefile |
| Test framework | Test directories (test/, tests/, __tests__, spec/), config files (jest.config.*, pytest.ini, vitest.config.*, .rspec, phpunit.xml) |
| CI provider | .github/workflows/, .gitlab-ci.yml, Jenkinsfile, .circleci/, bitbucket-pipelines.yml, .travis.yml |
| Module structure | Top-level directories, src/ layout, monorepo workspace config (pnpm-workspace.yaml, lerna.json, nx.json, turbo.json) |
| Existing agent files | CLAUDE.md, AGENTS.md, .cursorrules, .github/copilot-instructions.md, .windsurfrules, .clinerules |
| Code style | .eslintrc, .prettierrc, ruff.toml, .editorconfig, .stylelintrc, biome.json, rustfmt.toml, .golangci.yml |
| Monorepo structure | Workspace config (`workspaces` in package.json, `pnpm-workspace.yaml`, go.work, Cargo workspace in Cargo.toml), multiple distinct apps/packages in subdirectories |

Run relevant build/test/lint commands to confirm they work. Record the exact invocations.

---

## Step 4: Repo Profile Schema

Assemble findings into the following structured profile:

```yaml
project_name: ""            # Repository or project name
has_existing_code: false     # true if brownfield
greenfield: true             # true if fewer than 5 source files
project_type: ""             # If greenfield: API, web-app, CLI, library, etc.

# Language & framework
languages: []                # All detected languages, e.g. ["TypeScript", "Python"]
primary_language: ""         # The dominant language
framework: ""                # Primary framework, e.g. "Next.js", "FastAPI"

# Toolchain
package_manager: ""          # npm, yarn, pnpm, poetry, cargo, go modules, etc.
build_system: ""             # Build tool or task runner
test_framework: ""           # jest, pytest, vitest, go test, etc.
test_cmd: ""                 # Exact command to run tests
build_cmd: ""                # Exact command to build
lint_cmd: ""                 # Exact command to lint

# Infrastructure
ci_provider: ""              # GitHub Actions, GitLab CI, etc.

# Structure
module_structure: []         # Top-level modules/packages, e.g. ["src/api", "src/ui", "lib/"]
monorepo: false              # Whether the repo is a monorepo
workspace_packages: []       # If monorepo: list of {name, path, language} for each package/app
existing_agent_files: []     # Paths to any pre-existing agent instruction files
code_style_tools: []         # Linters/formatters in use, e.g. ["eslint", "prettier"]
```

For greenfield repos, fill in what the engineer specified and mark unknowns as `"TBD"`.

For brownfield repos, every field should be populated from detection.

---

## Monorepo Discovery

If a monorepo structure is detected (or specified during greenfield questioning), run discovery for each workspace package independently.

- **Per-package profile**: Build a separate repo profile for each workspace package. Each package profile captures the package-specific language, framework, commands, and conventions.
- **Root-level profile**: Build an aggregate root profile that captures shared CI configuration, shared tooling, and workspace-level commands (e.g., `pnpm -r build`, `cargo build --workspace`, `go build ./...`).
- **Package enumeration**: Populate `workspace_packages` with `{name, path, language}` for every package found — parse the workspace config file (`pnpm-workspace.yaml`, `workspaces` in `package.json`, `go.work`, or `[workspace]` in `Cargo.toml`) and scan each listed path.

The root profile and per-package profiles together form the complete repo profile that subsequent phases consume.

---

## Step 5: Carry Forward

Carry this repo profile as your working context through all subsequent phases.

- Phase 1 (Analyze) will use it to infer architecture and conventions.
- Phase 2 (Generate) will use it to fill templates.
- Phase 3 (Verify) will use it to validate outputs.

Do not discard or summarize this profile — keep the full structured data available.

---

## Checklist Before Proceeding

- [ ] Brownfield/greenfield determination is made
- [ ] All detection signals checked (brownfield) or questions answered (greenfield)
- [ ] Repo profile schema is fully populated
- [ ] Build/test/lint commands confirmed working (brownfield only)
- [ ] Profile is ready to carry into Phase 1
