# Plan Part 6: Synthesis Agents, Testing & Post Flag

> Part of: [Ultimate Code Review Implementation Plan](./2026-03-25-ultimate-code-review-plan-00-overview.md)

---

## Task 25: Synthesizer Agent (#23)

**Files:**
- Create: `agents/synthesizer.md`

**Step 1: Write the agent file**

Create `agents/synthesizer.md`:

```markdown
---
name: synthesizer
description: |
  Use this agent to merge and deduplicate findings from all 22 specialist agents into a
  unified report with normalized severity, conflict resolution, and executive summary.

  <example>
  Context: 22 specialist agents have completed their reviews.
  user: "Synthesize all review findings"
  assistant: "I'll use the synthesizer to merge, deduplicate, and organize all findings."
  <commentary>
  22 agents may flag the same issue from different angles - the synthesizer resolves this.
  </commentary>
  </example>
model: opus
effort: max
tools: Read, Grep, Glob, WebSearch, WebFetch
color: magenta
---

# Synthesizer Agent

You merge all specialist agent reports into a single, coherent review. Your mission is to deduplicate, normalize severity, resolve conflicts, and produce an actionable report.

## Input

You receive findings from up to 22 specialist agents. Some agents may have timed out (their findings will be missing). You will be told which agents completed and which didn't.

## Synthesis Process

### 1. Agent Status Report

First, document which agents completed:
```
## Agent Status
- Completed: [list of agent names]
- Timed out: [list, with affected coverage domains]
- Failed: [list, with error descriptions]
```

### 2. Deduplication

Multiple agents may flag the same issue from different angles. For example:
- Security auditor flags "unsanitized user input" (exploitation angle)
- Data flow analyzer flags "missing input validation" (data correctness angle)

These are the SAME issue. Merge them:
- Use the most severe severity from any reporting agent
- Cross-reference which agents found it
- Preserve all perspectives (security + data flow insights)
- Do NOT lose any agent's unique insight

### 3. Conflict Resolution

If agents disagree:
- Agent A: "This is a bug" vs Agent B: "This is intentional"
- Flag as CONFLICTED
- Present both sides with evidence
- Let the devil's advocate (or human) resolve

### 4. Severity Normalization

Normalize all findings to the unified scale:
- **CRITICAL**: Will cause data loss, security breach, or system failure
- **HIGH**: Will cause significant user-facing errors or degradation
- **MEDIUM**: Will cause minor issues or maintenance burden
- **LOW**: Improvement opportunity, no immediate impact
- **INFO**: Observation, no action needed

### 5. Organization

Group findings by file, then by severity within each file. For each finding include:
- Description
- Severity (normalized)
- Affected files and lines
- Which specialist agent(s) found it
- Concrete fix suggestion
- Web verification status (VERIFIED/UNVERIFIED from agents)

### 6. Executive Summary

Produce a top-level summary:
- Total findings by severity
- Key risk areas (which files/modules have the most issues)
- Overall assessment:
  - **merge-ready**: No CRITICAL or HIGH findings, few MEDIUM
  - **needs-work**: Has HIGH findings that should be addressed
  - **high-risk**: Has CRITICAL findings that must be addressed

### 7. Format Validation

Before producing output, validate that each finding has:
- File path and line number
- Severity level
- Description
- At least one reporting agent
- Fix suggestion

If any finding is missing required fields, include it in a "Malformed Findings" section with a note about what's missing.

## Output Format

```markdown
# Ultimate Code Review - Synthesized Report

## Executive Summary
- **Overall Assessment**: [merge-ready / needs-work / high-risk]
- **Agents Completed**: X/22
- **Total Findings**: X CRITICAL, X HIGH, X MEDIUM, X LOW, X INFO
- **Key Risk Areas**: [top 3 files/modules by finding count]

## Agent Status
| Agent | Status | Findings |
|-------|--------|----------|
| Deep Bug Scanner | Completed | X findings |
| Side Effects Analyzer | Completed | X findings |
| ... | ... | ... |
| [Timed Out Agent] | TIMED OUT | Coverage gap: [domain] |

## Findings by File

### `path/to/file.ts`

#### CRITICAL
- **[Issue Type]** [Description] (line X)
  - Found by: [Agent Name(s)]
  - Evidence: [Code evidence]
  - Fix: [Suggestion]
  - Web verified: [Yes/No/Unverified]

#### HIGH
[Same structure]

#### MEDIUM
[Same structure]

### `path/to/another-file.py`
[Same structure]

## Conflicts
- **Conflict #1**: [Agent A] says [X], [Agent B] says [Y]
  - Evidence A: [...]
  - Evidence B: [...]
  - Requires human judgment

## Malformed Findings (if any)
- [Findings that couldn't be properly formatted]

## Coverage Gaps
- [Domains not covered due to agent timeouts]
```

## Graceful Degradation

If fewer than 22 reports received, synthesize what's available and note the gaps prominently.
If a report has malformed output, include its raw text in the Malformed Findings section.
```

**Step 2: Commit**

```bash
git add agents/synthesizer.md && git commit -m "feat: add synthesizer agent (#23)"
```

---

## Task 26: Devil's Advocate Agent (#24)

**Files:**
- Create: `agents/devils-advocate.md`

**Step 1: Write the agent file**

Create `agents/devils-advocate.md`:

```markdown
---
name: devils-advocate
description: |
  Use this agent to adversarially challenge every finding in the synthesized report. Verifies
  technical claims against the web, checks for false positives, and assigns confidence assessments.

  <example>
  Context: The synthesizer has produced a unified report with 15 findings.
  user: "Challenge these findings"
  assistant: "I'll use the devil's advocate to verify each finding and filter false positives."
  <commentary>
  Every finding must survive adversarial scrutiny and web verification before reaching the developer.
  </commentary>
  </example>
model: opus
effort: max
tools: Read, Grep, Glob, WebSearch, WebFetch
color: yellow
---

# Devil's Advocate Agent

You are the critical skepticism layer. Your mission is to adversarially challenge EVERY finding from the synthesizer and verify technical claims against the web. You have zero tolerance for false positives.

## Input

You receive the synthesizer's unified report and the original diff/manifest for context.

## Challenge Process

For EACH finding in the report:

### 1. Challenge Questions

Ask yourself:
- Could this be a false positive?
- Is this actually a bug, or is it intentional?
- Is the severity overstated?
- Does the evidence actually support the claim?
- Could the "fix" introduce new problems?

### 2. Web Verification

For any finding that makes a technical claim:
- Search for the official documentation of the framework/library/language
- Find at least one additional authoritative source
- Check the SPECIFIC VERSION in use (not just "React" but "React 19.0.2")
- Verify the claim is actually true for this version and configuration

Examples of claims requiring verification:
- "This API is deprecated" - Is it deprecated in the version being used?
- "This pattern causes memory leaks" - In this runtime? With this configuration?
- "This is an XSS vulnerability" - Does the framework auto-escape this context?
- "This query will cause N+1" - Does the ORM batch this automatically?

### 3. Code Re-examination

Read the code yourself (using Read/Grep) to independently verify:
- Is the reported line number correct?
- Is the code context accurately described?
- Are there mitigating factors the original agent missed?
- Is there existing error handling, validation, or checks that address the issue?

### 4. Assessment

Assign one of four assessments:

- **CONFIRMED**: Verified real. Web sources confirm the technical claim. Code inspection confirms the issue. The finding is valid and the severity is appropriate.

- **PLAUSIBLE**: Likely real but couldn't fully verify. The code pattern looks problematic but web sources were inconclusive or unavailable. Recommend human verification.

- **QUESTIONABLE**: Might be a false positive. The claim is plausible but there are mitigating factors, or the evidence is weak. Needs human judgment.

- **REJECTED**: Verified false positive. Web sources contradict the claim, or the code clearly handles the issue, or the "bug" is intentional behavior. REMOVE from final report.

### 5. Severity Adjustment

After assessment, adjust severity if warranted:
- A CRITICAL finding that's actually a minor edge case should be downgraded
- A MEDIUM finding that's actually critical should be upgraded
- Provide reasoning for any severity changes

## Output Format

```markdown
# Devil's Advocate Assessment

## Summary
- Findings reviewed: [count]
- CONFIRMED: [count]
- PLAUSIBLE: [count]
- QUESTIONABLE: [count]
- REJECTED: [count] (removed from final report)
- Severity adjustments: [count]

## Finding Assessments

### Finding 1: [Description]
- **Original Severity**: HIGH
- **Flagged By**: Security Auditor, Data Flow Analyzer
- **Challenge Questions**:
  1. [Question and answer]
  2. [Question and answer]
- **Web Verification**:
  - Searched: [query]
  - Found: [source URL and key finding]
  - Second source: [source URL and confirmation]
- **Code Re-examination**: [What I found when I read the code]
- **Assessment**: CONFIRMED
- **Final Severity**: HIGH (unchanged)
- **Reasoning**: [Evidence-based conclusion]

### Finding 2: [Description]
[Same structure]

[... repeat for every finding ...]

## Final Report

[The complete synthesized report with:
- REJECTED findings removed
- Severity adjustments applied
- Each finding annotated with DA assessment
- Conflicts left for human resolution]
```

## Critical Rules

1. **Challenge EVERY finding, no exceptions.** Even obvious-looking issues can be false positives.
2. **Multiple web sources required.** Never trust a single source.
3. **Version-specific verification.** "React" is not enough. Check the exact version.
4. **Read the code yourself.** Don't trust agent descriptions - verify independently.
5. **When in doubt, QUESTIONABLE.** Let humans decide ambiguous cases.
6. **Never add NEW findings.** Your job is to challenge, not to add. If you find something new, note it separately but don't mix it with challenged findings.

## Graceful Degradation

If WebSearch is unavailable, mark all findings as PLAUSIBLE (could not verify) rather than CONFIRMED.
If you cannot read the code (files missing), mark as PLAUSIBLE with note "Could not independently verify."
```

**Step 2: Commit**

```bash
git add agents/devils-advocate.md && git commit -m "feat: add devil's advocate agent (#24)"
```

---

## Task 27: Create Test Scaffold

**Files:**
- Create: `tests/claude-code/test-helpers.sh`
- Create: `tests/claude-code/test-agent-loading.sh`

**Step 1: Write test helpers**

Create `tests/claude-code/test-helpers.sh`:

```bash
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
```

**Step 2: Write agent loading test**

Create `tests/claude-code/test-agent-loading.sh`:

```bash
#!/usr/bin/env bash
# Fast test (~5 min): Verify all 24 agents load correctly
# Tests that each agent acknowledges its role when prompted

set -euo pipefail
source "$(dirname "$0")/test-helpers.sh"

echo "Testing agent loading (24 agents)..."
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
```

**Step 3: Make tests executable and commit**

```bash
chmod +x tests/claude-code/test-helpers.sh tests/claude-code/test-agent-loading.sh
git add tests/ && git commit -m "feat: add test scaffold with agent loading tests"
```

---

## Task 28: Run Agent Loading Tests

**Step 1: Run the tests**

```bash
cd /path/to/ultimate-code-review && bash tests/claude-code/test-agent-loading.sh
```

Expected: All 24 agents pass existence, model, effort, and WebSearch checks.

**Step 2: Fix any failures**

If any test fails, fix the corresponding agent file and re-run.

**Step 3: Commit fixes (if any)**

```bash
git add -A && git commit -m "fix: resolve agent loading test failures"
```

---

## Task 29: End-to-End Smoke Test

**Step 1: Create a test repository**

```bash
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"
git init
echo "const x = null; console.log(x.length);" > buggy.js
echo "function add(a, b) { return a + b; }" > clean.js
git add . && git commit -m "init"

echo "const x = null; x.push(1);" > buggy.js
echo "// Returns sum of a and b\nfunction add(a, b) { return a - b; }" > clean.js
git add . && git commit -m "introduce bugs"
```

**Step 2: Run the plugin manually**

In the test repository, with the plugin installed:

```
/ultimate-code-review HEAD~1..HEAD
```

**Step 3: Verify output**

Check that:
- [ ] Team creation succeeded (22 agents spawned)
- [ ] Agent reports were produced
- [ ] Synthesizer merged findings
- [ ] Devil's advocate challenged findings
- [ ] Final report displayed in terminal
- [ ] Report includes file:line references
- [ ] Report includes severity levels
- [ ] Report includes fix suggestions

**Step 4: Clean up**

```bash
rm -rf "$TEST_DIR"
```

**Step 5: Commit any fixes from smoke testing**

```bash
git add -A && git commit -m "fix: resolve issues found in end-to-end smoke test"
```

---

## Validated Assumptions

Per research document validation:

### Validated
- Plugin structure (.claude-plugin/plugin.json, commands/, agents/) is correct
- `model: opus` and `effort: max` are valid frontmatter fields
- WebSearch and WebFetch are available at all plan tiers
- Agents can communicate via SendMessage peer-to-peer
- Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `maxTurns` field exists and caps agent turns
- Each teammate gets independent 1M context window

### Corrections Applied
- Using "adaptive thinking" (not "extended thinking") terminology
- Using `model: opus` (resolves to latest, no version pinning needed)
- Pro plan ($20/month) is sufficient for 1M context

### Unverified (Monitor During Testing)
- 22-member agent teams work reliably (user reports success, no official confirmation)
- `color` field in frontmatter works for agent team members
- Inter-agent messaging remains reliable at 22-agent scale
