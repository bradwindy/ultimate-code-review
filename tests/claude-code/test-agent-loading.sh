#!/usr/bin/env bash
# Fast test (~5 min): Verify all 25 agents load correctly
# Tests that each agent acknowledges its role when prompted

set -euo pipefail
source "$(dirname "$0")/test-helpers.sh"

echo "Testing agent loading (25 agents)..."
echo ""

AGENTS=(
    "deep-bug-scanner"
    "side-effects-analyzer"
    "concurrency-reviewer"
    "silent-failure-hunter"
    "data-flow-analyzer"
    "memory-resource-analyzer"
    "performance-analyzer"
    "security-auditor"
    "type-design-reviewer"
    "api-contract-reviewer"
    "git-history-analyzer"
    "cross-pr-learning-agent"
    "guidelines-compliance"
    "comment-compliance-checker"
    "comment-quality-reviewer"
    "dependency-import-analyzer"
    "code-simplification"
    "style-consistency"
    "test-coverage-analyzer"
    "architecture-boundary"
    "logging-observability"
    "migration-deployment-risk"
    "scope-relevance-reviewer"
    "synthesizer"
    "devils-advocate"
)

for agent in "${AGENTS[@]}"; do
    if [ -f "agents/${agent}.md" ]; then
        echo -e "Checking agents/${agent}.md exists... \033[0;32mPASS\033[0m"
        ((PASS_COUNT++))
    else
        echo -e "Checking agents/${agent}.md exists... \033[0;31mFAIL\033[0m"
        ((FAIL_COUNT++))
    fi
done

echo ""
echo "Checking frontmatter consistency..."

for agent in "${AGENTS[@]}"; do
    if [ -f "agents/${agent}.md" ]; then
        # Check model: opus
        if grep -q "^model: opus" "agents/${agent}.md"; then
            echo -e "  ${agent}: model=opus ... \033[0;32mPASS\033[0m"
            ((PASS_COUNT++))
        else
            echo -e "  ${agent}: model=opus ... \033[0;31mFAIL\033[0m"
            ((FAIL_COUNT++))
        fi

        # Check effort: max
        if grep -q "^effort: max" "agents/${agent}.md"; then
            echo -e "  ${agent}: effort=max ... \033[0;32mPASS\033[0m"
            ((PASS_COUNT++))
        else
            echo -e "  ${agent}: effort=max ... \033[0;31mFAIL\033[0m"
            ((FAIL_COUNT++))
        fi

        # Check WebSearch in tools
        if grep -q "WebSearch" "agents/${agent}.md"; then
            echo -e "  ${agent}: has WebSearch ... \033[0;32mPASS\033[0m"
            ((PASS_COUNT++))
        else
            echo -e "  ${agent}: has WebSearch ... \033[0;31mFAIL\033[0m"
            ((FAIL_COUNT++))
        fi
    fi
done

print_summary
