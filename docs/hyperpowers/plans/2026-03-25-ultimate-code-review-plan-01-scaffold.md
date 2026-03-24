# Plan Part 1: Plugin Scaffold & Main Command

> Part of: [Ultimate Code Review Implementation Plan](./2026-03-25-ultimate-code-review-plan-00-overview.md)

---

## Task 1: Create Plugin Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `commands/` (directory)
- Create: `agents/` (directory)
- Create: `README.md`

**Step 1: Create directory structure**

```bash
mkdir -p .claude-plugin commands agents tests/claude-code
```

**Step 2: Write plugin.json**

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "ultimate-code-review",
  "version": "1.0.0",
  "description": "Deep code review with 22+ specialist Opus agents. Full call-graph tracing, web-verified findings, adversarial false-positive filtering. Supports GitHub PRs, GitLab MRs, and local branch comparisons.",
  "author": {
    "name": "Brad Windy"
  },
  "license": "MIT",
  "keywords": [
    "code-review",
    "agent-team",
    "security",
    "performance",
    "testing",
    "opus"
  ]
}
```

**Step 3: Write README.md**

Create `README.md`:

```markdown
# Ultimate Code Review

Deep code review plugin for Claude Code. Spawns a 22-agent team to review PRs, MRs, or branch comparisons.

## Requirements

- Claude Code v2.1.80+
- Opus model access (Pro plan or higher)
- Agent teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `gh` CLI (for GitHub PRs)
- `glab` CLI (for GitLab MRs)
- `git` (always required)

## Installation

```bash
claude plugin add /path/to/ultimate-code-review
```

Or from GitHub:

```bash
claude plugin add owner/ultimate-code-review
```

## Usage

```bash
# Review current branch vs upstream
/ultimate-code-review

# Review a specific PR
/ultimate-code-review https://github.com/org/repo/pull/123

# Review a specific MR
/ultimate-code-review https://gitlab.com/org/repo/-/merge_requests/456

# Review local branch comparison
/ultimate-code-review feature..main

# Also post summary to PR/MR
/ultimate-code-review --post https://github.com/org/repo/pull/123
```

## Architecture

Three-phase review:

1. **Context Gathering**: Team lead collects diff, builds change manifest
2. **Deep Analysis**: 22 specialist agents review in parallel (all Opus, max effort)
3. **Synthesis**: Findings merged, then adversarially challenged by devil's advocate

All agents verify technical claims against the web. No reliance on internal knowledge.

## Agents

22 specialist agents with non-overlapping scopes:

**Bug-Focused (1-7):** Deep Bug Scanner, Side Effects Analyzer, Concurrency Reviewer, Silent Failure Hunter, Data Flow Analyzer, Memory & Resource Analyzer, Performance Analyzer

**Security & Types (8-10):** Security Auditor, Type Design Reviewer, API Contract Reviewer

**Context & Quality (11-22):** Git History Analyzer, Cross-PR Learning Agent, Guidelines Compliance, Comment Compliance Checker, Comment Quality Reviewer, Dependency Analyzer, Code Simplification, Style Consistency, Test Coverage Analyzer, Architecture Boundary, Logging & Observability, Migration & Deployment Risk

**Synthesis (23-24):** Synthesizer, Devil's Advocate

## Cost

This plugin uses 22+ Opus agents at max effort. Expect significant token usage ($5-50+ per review depending on diff size). This is by design - depth over economy.
```

**Step 4: Verify structure**

```bash
find . -type f | head -20
```

Expected:
```
./.claude-plugin/plugin.json
./README.md
```

**Step 5: Commit**

```bash
git init && git add .claude-plugin/plugin.json README.md && git commit -m "feat: initialize plugin scaffold with manifest and README"
```

---

## Task 2: Create Main Command (Orchestrator)

**Files:**
- Create: `commands/ultimate-code-review.md`

**Step 1: Write the main command file**

Create `commands/ultimate-code-review.md`:

```markdown
---
name: ultimate-code-review
description: Deep code review with 22+ specialist agents. Reviews PRs, MRs, or branch comparisons.
user-invocable: true
model: opus
effort: max
argument-hint: "[PR/MR URL or branch..branch] [--post]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(glab:*), Read, Grep, Glob, LSP, WebSearch, WebFetch
---

# Ultimate Code Review

You are the team lead for a comprehensive code review. You will orchestrate 22 specialist agents to deeply analyze code changes, then synthesize and adversarially verify the findings.

## Phase 1: Context Gathering

### Step 1: Parse Arguments

Parse $ARGUMENTS to determine the review target:

1. **PR URL** (contains `github.com` and `pull`): Extract owner/repo and PR number. Use `gh pr diff` and `gh pr view`.
2. **MR URL** (contains `gitlab.com` and `merge_requests`): Extract project and MR number. Use `glab mr diff` and `glab mr view`.
3. **Branch range** (contains `..`): Use `git diff <range>`.
4. **No arguments**: Detect upstream branch and diff against it.
   - Try: `git rev-parse --abbrev-ref @{upstream}` to find tracking branch
   - Fallback: diff against `main` or `master` (whichever exists)

Check for `--post` flag. If present, store for Phase 3 output.

### Step 2: Verify Prerequisites

Before proceeding, verify:
1. We are in a git repository
2. The diff is non-empty (if empty, report "No changes to review" and exit)
3. If PR/MR URL given, verify `gh` or `glab` is available

If prerequisites fail, report the issue clearly and exit.

### Step 3: Build Change Manifest

Collect the following information:

1. **Changed files list**: Run `git diff --name-status <range>` to get file paths and change types (A/M/D)
2. **Filter binary files**: Exclude files detected as binary by `git diff --numstat` (lines show `-` for binary)
3. **Full diff content**: `git diff <range>` (the complete patch)
4. **Project guidelines**: Search for and read:
   - Root `CLAUDE.md` (if exists)
   - Any `CLAUDE.md` in directories containing changed files
   - `.editorconfig` (if exists)
5. **Project structure**: Read `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `build.gradle`, `pom.xml`, or similar config files to identify the tech stack
6. **File count classification**:
   - 1-100 files: Small diff (all agents review all files)
   - 100-300 files: Medium diff (all agents review all files, tight context)
   - 300+ files: Large diff (agents must use domain-scoped loading)

Write the manifest summary to a temporary file at `$TMPDIR/ucr-manifest.md` containing:
- File list with change types
- Tech stack summary
- Guidelines summary
- Diff size classification
- The diff content (for small/medium diffs) or file list only (for large diffs)

### Step 4: Create the Agent Team

Create a team named `ultimate-code-review`:

```
TeamCreate(team_name: "ultimate-code-review", description: "Deep code review with 22 specialist agents")
```

### Step 5: Create Tasks for All 22 Specialists

Create 22 tasks on the task list, one per specialist agent. Each task should include:
- The agent's specific review domain
- The change manifest content
- Instructions to read the manifest and begin analysis
- The standardized output format

### Step 6: Spawn All 22 Specialist Agents

Spawn all 22 agents as team members. Each agent receives:
- Its task assignment
- The change manifest (via message or file reference)
- Instructions to complete its review and mark its task as completed

Spawn all agents in a SINGLE message with 22 parallel Agent tool calls. Use `team_name: "ultimate-code-review"` for each.

For each agent, the prompt should include:
1. The full change manifest
2. The agent's specific review instructions (from its agent definition)
3. The standardized output format
4. The web verification mandate
5. Graceful degradation instructions

## Phase 2: Monitor and Wait

After spawning all agents:
1. Agents work independently in parallel
2. Each agent marks its task as completed when done
3. Monitor the task list for completion
4. Cross-boundary messages between agents are automatic

Wait for all agents to complete or timeout (15 minutes per agent).

If an agent times out, note it in the status report but proceed with available results.

## Phase 3: Synthesis

### Step 7: Spawn Synthesizer Agent

Once all (or most) Phase 2 agents complete:

Spawn the synthesizer agent with:
- All 22 specialist reports (collected from completed tasks)
- Agent completion status (which agents finished, which timed out)
- Instructions to deduplicate, normalize severity, resolve conflicts

The synthesizer produces a unified report.

### Step 8: Spawn Devil's Advocate Agent

After the synthesizer completes:

Spawn the devil's advocate agent with:
- The synthesizer's unified report
- The original diff/manifest for context
- Instructions to challenge every finding
- Web verification mandate for technical claims

The devil's advocate produces the final report with assessments: CONFIRMED, PLAUSIBLE, QUESTIONABLE, REJECTED.

### Step 9: Present Results

Display the final report to the user in the terminal:

```markdown
# Ultimate Code Review Results

## Summary
- **Overall Assessment**: [merge-ready / needs-work / high-risk]
- **Agents Completed**: X/22
- **Findings**: X CRITICAL, X HIGH, X MEDIUM, X LOW, X INFO
- **Devil's Advocate**: X CONFIRMED, X PLAUSIBLE, X QUESTIONABLE, X REJECTED

## Findings by File

### `path/to/file.ts`

#### CRITICAL
- **[Issue Type]** [Description] (line X)
  - Found by: [Agent Name(s)]
  - Evidence: [Code evidence]
  - Fix: [Suggestion]
  - DA Assessment: CONFIRMED
  - Source: [Web verification URL]

[... more findings grouped by file, then severity ...]

## Agent Status
- 22/22 agents completed
- 0 agents timed out

## Unresolved Conflicts
[Any findings where agents disagreed and DA couldn't resolve]
```

### Step 10: Optional PR/MR Comment (--post)

If `--post` flag was set:

1. Condense the report to a summary (CRITICAL and HIGH findings only)
2. Format for PR/MR comment
3. Post via `gh pr comment` or `glab mr comment`

Comment format:
```markdown
### Ultimate Code Review

**Assessment**: [merge-ready / needs-work / high-risk]
**Agents**: 22/22 completed | **Findings**: X critical, X high

[List CRITICAL and HIGH findings with file:line references]

<sub>Generated by Ultimate Code Review (22 Opus agents, max effort)</sub>
```

### Step 11: Cleanup

Shut down all team members:
```
SendMessage(to: "*", message: {type: "shutdown_request", reason: "Review complete"})
```

Clean up temporary files:
```bash
rm -f $TMPDIR/ucr-manifest.md
```

Delete the team:
```
TeamDelete()
```
```

**Step 2: Verify the command file**

Check that the file:
- Has correct frontmatter (name, description, model, effort, argument-hint, allowed-tools)
- Covers all 3 phases
- Includes --post logic
- Includes cleanup/shutdown

**Step 3: Commit**

```bash
git add commands/ultimate-code-review.md && git commit -m "feat: add main /ultimate-code-review command with 3-phase orchestration"
```
