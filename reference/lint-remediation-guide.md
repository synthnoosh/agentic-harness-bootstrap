# Lint Remediation Guide

How to write custom linter rules with error messages that teach agents how to fix violations.

## The Core Insight

Agents read error messages literally. A message that says "fix this" without saying how leads to random attempts. A message that says "move X to Y" gets done in one shot.

The quality of your linter's error message is the single biggest factor in whether an agent fixes a violation in one attempt or five. Default linter messages are written for humans who have surrounding context. Agents don't have that context unless you put it in the message.

## The Error Message Pattern

Every actionable error message has three parts:

```
[WHAT went wrong] [WHY it's wrong] [HOW to fix it]
```

- **WHAT**: The specific violation, with file, line, and symbol names.
- **WHY**: The rule or convention being enforced, in one sentence.
- **HOW**: The exact action to take — move, rename, extract, wrap, delete.

If your error message is missing any of these three parts, agents will guess at the missing piece. They guess wrong often enough to matter.

## Language-Specific Examples

### ESLint Custom Rule (TypeScript/JavaScript)

A rule that detects direct database calls outside the `services/` layer:

```javascript
// eslint-plugin-architecture/rules/no-direct-db-in-controllers.js
module.exports = {
  meta: {
    type: "problem",
    docs: {
      description: "Database calls must go through the service layer",
    },
    messages: {
      directDbCall:
        "Direct database call in {{ layerName }} layer ({{ filePath }}). " +
        "Database access must go through the service layer. " +
        "Move this query to 'services/{{moduleName}}.service.ts' and " +
        "call that service method from here instead.",
    },
  },
  create(context) {
    const filename = context.getFilename();
    if (!filename.includes("/controllers/") && !filename.includes("/routes/")) {
      return {};
    }
    return {
      CallExpression(node) {
        const callee = node.callee;
        if (isDbCall(callee)) {
          const moduleName = inferModuleName(filename);
          context.report({
            node,
            messageId: "directDbCall",
            data: {
              layerName: filename.includes("/controllers/") ? "controller" : "route",
              filePath: filename,
              moduleName,
            },
          });
        }
      },
    };
  },
};
```

The agent reads: *"Move this query to `services/users.service.ts` and call that service method from here instead."* It does exactly that.

### Ruff / Python Custom Rule

Enforcing import ordering with remediation hints via Ruff configuration and a complementary wrapper script:

```toml
# pyproject.toml
[tool.ruff.lint]
select = ["I", "E", "F"]  # isort, pycodestyle, pyflakes

[tool.ruff.lint.isort]
known-first-party = ["myapp"]
section-order = ["future", "standard-library", "third-party", "first-party", "local-folder"]
```

When Ruff's default message isn't sufficient, wrap it with a script that enriches the output:

```python
# scripts/lint_imports.py
"""Wrapper around ruff that adds remediation hints to import violations."""

import subprocess, sys, re

result = subprocess.run(["ruff", "check", "--select", "I"], capture_output=True, text=True)

for line in result.stdout.splitlines():
    if "I001" in line:
        print(f"{line}")
        print(f"  FIX: Run 'ruff check --select I --fix' to auto-sort imports,")
        print(f"  or manually reorder: standard library -> third-party -> first-party -> local.")
    else:
        print(line)

sys.exit(result.returncode)
```

### Go (golangci-lint)

Using custom `revive` rules with actionable messages:

```yaml
# .golangci.yml
linters:
  enable:
    - revive
    - nolintlint

linters-settings:
  revive:
    rules:
      - name: package-comments
        severity: error
        arguments:
          - "Package {{.Name}} is missing a doc comment. Add a comment above the package declaration: // Package {{.Name}} provides ..."
      - name: exported
        severity: error
        arguments:
          - "Exported {{.Kind}} {{.Name}} is missing a doc comment. Add a comment directly above it: // {{.Name}} does ..."
  nolintlint:
    require-explanation: true
    require-specific: true
    # Forces agents to explain WHY they're suppressing a lint, not just slap //nolint on it
```

For custom architectural rules, use `go vet` with analysis passes or a wrapper:

```go
// Message format for custom analyzers
fmt.Sprintf(
    "%s: function %s in package %s calls %s directly. "+
    "Database calls must go through the repository layer. "+
    "Create a method on %sRepository and call that instead.",
    pass.Fset.Position(call.Pos()), funcName, pkgName, calledFunc, entityName,
)
```

### PHP (PHPStan) — Laravel Conventions

Custom rules for enforcing Laravel architectural patterns:

```php
// phpstan-rules/NoEloquentInControllersRule.php
class NoEloquentInControllersRule implements Rule
{
    public function processNode(Node $node, Scope $scope): array
    {
        $filename = $scope->getFile();
        if (!str_contains($filename, '/Controllers/')) {
            return [];
        }

        if ($this->isEloquentCall($node)) {
            $model = $this->getModelName($node);
            return [
                RuleErrorBuilder::message(
                    "Direct Eloquent call to {$model} in controller. " .
                    "Database queries must go through a repository or service class. " .
                    "Create app/Services/{$model}Service.php with this query, " .
                    "inject it into the controller constructor, and call the service method."
                )->build(),
            ];
        }
        return [];
    }
}
```

## Structuring Messages for Maximum Agent Comprehension

Follow this order in every error message:

1. **Rule name first** — Agents use this to search for documentation and prior fixes.
   `[no-direct-db] Direct database call in controller layer.`

2. **Expected vs. found** — Remove ambiguity about what the violation is.
   `Expected: database calls only in services/. Found: db.query() in controllers/users.ts:42.`

3. **Exact fix action** — Use imperative verbs: move, rename, extract, wrap, delete, replace.
   `Move this query to services/users.service.ts and export a function getUserById().`

Bad messages the agent has to interpret:
```
Error: architectural violation
Error: this doesn't belong here
Error: wrong layer
```

Good messages the agent can act on:
```
[layer-violation] db.query() called in controllers/users.ts:42.
Database calls belong in the services/ layer.
Move this query to services/users.service.ts, export it as getUserById(),
and import/call it from controllers/users.ts.
```

## Testing Your Linter Messages

The litmus test: **Can an agent fix the violation using only the error message?**

1. Write a piece of code that deliberately violates the rule.
2. Run the linter.
3. Give the error message to an agent with no other context.
4. If the agent fixes it in one attempt, the message is good.
5. If it takes two or more attempts, improve the message.

Common failure modes:
- Message says *what* is wrong but not *where to put the fix* — agent creates a new file in the wrong location.
- Message says *where* but not *what to name it* — agent invents a name that doesn't match conventions.
- Message is too generic — "fix the import" could mean reorder, remove, add, or rename.

Every round-trip the agent needs to fix a lint violation is wasted time and tokens. Invest in your error messages. They are the single highest-leverage improvement you can make to agent productivity in your codebase.
