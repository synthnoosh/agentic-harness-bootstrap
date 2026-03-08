#!/usr/bin/env bash
set -euo pipefail

EXAMPLES_DIR="${1:-examples}"
EXAMPLES=("go-service" "php-laravel" "react-app")

# Each entry is "display_name:pattern1|pattern2|..." — matches any pattern variant
CLAUDE_SECTIONS=(
  "Commands:Build|Test|Commands"
  "Architecture:Architecture|Structure"
  "Conventions:Conventions"
  "Boundaries:Boundaries|Always|Never"
  "Harness Maintenance:Harness Maintenance|Maintenance"
)
AGENTS_SECTIONS=(
  "Commands:Setup|Testing|Linting|Commands"
  "Architecture:Architecture|Structure"
  "Conventions:Conventions"
  "Boundaries:Boundaries|Rules|Always|Never"
  "Harness Maintenance:Maintenance|Harness"
)
ARCH_SECTIONS=(
  "Module Map:Module Map"
  "Layer Diagram:Layer Diagram|Layer"
  "Dependency Rules:Dependency Rules|Dependency|Dependencies"
  "What Doesn't Belong:Doesn't Belong|Doesn.t Belong"
)

total=0
passed=0
failed=0
fail_details=()

check_file_exists() {
  local file="$1"
  total=$((total + 1))
  if [ -f "$file" ]; then
    passed=$((passed + 1))
    return 0
  else
    failed=$((failed + 1))
    fail_details+=("MISSING: $file")
    return 1
  fi
}

check_sections() {
  local file="$1"
  shift
  local sections=("$@")

  for entry in "${sections[@]}"; do
    local display_name="${entry%%:*}"
    local patterns="${entry#*:}"
    total=$((total + 1))
    # Convert pipe-separated patterns to grep -E alternation
    if grep -qiE "^##.*(${patterns})" "$file" 2>/dev/null; then
      passed=$((passed + 1))
    else
      failed=$((failed + 1))
      fail_details+=("MISSING SECTION: '$display_name' in $file")
    fi
  done
}

echo "Validating examples in $EXAMPLES_DIR/"
echo "======================================="
echo ""

for example in "${EXAMPLES[@]}"; do
  dir="$EXAMPLES_DIR/$example"
  echo "--- $example ---"

  if [ ! -d "$dir" ]; then
    echo "  ERROR: Directory $dir does not exist."
    failed=$((failed + 1))
    total=$((total + 1))
    fail_details+=("MISSING DIR: $dir")
    continue
  fi

  # Check required files exist
  check_file_exists "$dir/CLAUDE.md"
  check_file_exists "$dir/AGENTS.md"
  check_file_exists "$dir/ARCHITECTURE.md"

  # Check required sections
  if [ -f "$dir/CLAUDE.md" ]; then
    check_sections "$dir/CLAUDE.md" "${CLAUDE_SECTIONS[@]}"
  fi

  if [ -f "$dir/AGENTS.md" ]; then
    check_sections "$dir/AGENTS.md" "${AGENTS_SECTIONS[@]}"
  fi

  if [ -f "$dir/ARCHITECTURE.md" ]; then
    check_sections "$dir/ARCHITECTURE.md" "${ARCH_SECTIONS[@]}"
  fi

  echo "  Done."
done

echo ""
echo "======================================="
echo "Results: $passed passed, $failed failed, $total total"

if [ "$failed" -gt 0 ]; then
  echo ""
  echo "Failures:"
  for detail in "${fail_details[@]}"; do
    echo "  - $detail"
  done
  exit 1
fi

echo "All checks passed."
