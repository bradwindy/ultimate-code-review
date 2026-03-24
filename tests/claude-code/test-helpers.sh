#!/usr/bin/env bash
# Test helpers for Ultimate Code Review plugin tests
# Based on hyperpowers testing patterns

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

run_claude() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-Read,Grep,Glob}"

    timeout "$timeout" claude -p "$prompt" \
        --allowedTools "$allowed_tools" \
        --output-format text 2>&1 || echo "[TIMEOUT after ${timeout}s]"
}

assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="$3"

    if echo "$output" | grep -qi "$pattern"; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASS_COUNT++))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected to find: $pattern"
        echo "  Output (first 200 chars): ${output:0:200}"
        ((FAIL_COUNT++))
    fi
}

assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="$3"

    if echo "$output" | grep -qi "$pattern"; then
        echo -e "${RED}FAIL${NC}: $test_name (found pattern that should be absent)"
        ((FAIL_COUNT++))
    else
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASS_COUNT++))
    fi
}

print_summary() {
    echo ""
    echo "================================"
    echo "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${SKIP_COUNT} skipped"
    echo "================================"
    if [ "$FAIL_COUNT" -gt 0 ]; then
        exit 1
    fi
}

create_test_project() {
    local dir
    dir=$(mktemp -d)
    cd "$dir"
    git init -q
    echo '{}' > package.json
    echo '# Test Project' > README.md
    git add . && git commit -q -m "init"
    echo "$dir"
}

cleanup_test_project() {
    local dir="$1"
    rm -rf "$dir"
}
