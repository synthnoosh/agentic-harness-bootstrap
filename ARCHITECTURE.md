# Architecture Map

This repo is a **meta-harness**: it contains playbooks, templates, and agent instructions that allow any engineer to point an AI agent at this repo and say "Make my repo AI-native."

It does not contain application code. It produces artifacts for other repos.

## Directory Map

| Directory | Contains | Does NOT belong here |
|-|-|-|
| `playbooks/` | Sequential phases (00-03) that agents execute in order. Each playbook is a set of instructions for one phase of the bootstrap process. | Templates, reference material, or educational content. |
| `templates/` | Mustache-style `{{variable}}` templates for artifacts emitted into target repos. Each template has YAML frontmatter documenting its variables. Subdirs: `ci/` (CI pipelines), `pre-commit/` (git hooks), `lint/` (linter configs). | Bootstrap-repo-specific files. These are fill-in-the-blank artifacts for *other* repos. |
| `reference/` | Educational material agents read for context — principles, guides, conventions. | Executable instructions. Agents read these to learn, not to follow step-by-step. |
| `examples/` | Complete example outputs for different stacks (Go, PHP/Laravel, React). Used as ground truth for validation. | Partial or work-in-progress examples. Every example must be a complete, valid output. |
| `scripts/` | Internal validation scripts for this repo (example integrity checks, sync verification). | Target-repo scripts — those are generated from templates. |
| `.github/` | GitHub-specific config: Copilot instructions, CI workflow for this repo. | CI templates for target repos (those live in `templates/ci/`). |

## Playbook Chain

```
00-discover --> 01-analyze --> 02-generate --> 03-verify
```

1. **00-discover** — Scans the target repo. Builds a repo profile: language, framework, package manager, test runner, directory structure, existing CI.
2. **01-analyze** — Reads the repo profile. Infers patterns (monorepo vs single, service vs library). Prescribes the harness structure: which templates to use, what boundaries to set, what linting to add.
3. **02-generate** — Emits artifacts into the target repo using templates. Fills in `{{variable}}` placeholders with values from the repo profile and analysis. Writes ARCHITECTURE.md, CI config, linter configs, pre-commit hooks, verification script, Makefile, and agent instructions.
4. **03-verify** — Validates everything works. Runs linters, type checkers, tests. Confirms generated files parse correctly. Checks that CI config is valid. Reports what passed and what needs manual attention.

Each phase produces output that the next phase consumes. Phases are idempotent — running them twice should produce the same result.

## Template Variable Conventions

- Variables use Mustache-style double braces: `{{variable_name}}`
- Names are `snake_case`
- Each template documents its variables in YAML frontmatter:
  ```yaml
  ---
  variables:
    repo_name: Name of the target repository
    primary_language: Detected primary language (go, typescript, python, etc.)
    test_command: Command to run the test suite
  ---
  ```
- Variables are populated from the repo profile built in phase 00.

## Key Principle

| Artifact type | What it is | How agents use it |
|-|-|-|
| Playbooks | Instructions for agents | Execute step-by-step |
| Templates | Fill-in-the-blank artifacts | Populate with repo-specific values |
| Reference docs | Educational context | Read to understand principles |
| Examples | Ground truth | Compare generated output against |

Playbooks tell agents *what to do*. Templates give agents *what to produce*. Reference docs tell agents *why*. Examples tell agents *what good looks like*.
