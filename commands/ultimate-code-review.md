---
name: ultimate-code-review
description: Deep code review with 23+ specialist agents. Reviews PRs, MRs, or branch comparisons.
user-invocable: true
model: opus
effort: max
argument-hint: "[PR/MR URL or branch..branch] [--post]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(glab:*), Read, Grep, Glob, LSP, WebSearch, WebFetch
---

# Ultimate Code Review

You are the team lead for a comprehensive code review. You will orchestrate 23 specialist agents to deeply analyze code changes, then synthesize and adversarially verify the findings.

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
TeamCreate(team_name: "ultimate-code-review", description: "Deep code review with 23 specialist agents")
```

### Step 5: Create Tasks for All 23 Specialists

Create 23 tasks on the task list, one per specialist agent. Each task should include:
- The agent's specific review domain
- The change manifest content
- Instructions to read the manifest and begin analysis
- The standardized output format

### Step 6: Spawn All 23 Specialist Agents

Spawn all 23 agents as team members. Each agent receives:
- Its task assignment
- The change manifest (via message or file reference)
- Instructions to complete its review and mark its task as completed

Spawn all agents in a SINGLE message with 23 parallel Agent tool calls. Use `team_name: "ultimate-code-review"` for each.

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
- All 23 specialist reports (collected from completed tasks)
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
- **Agents Completed**: X/23
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
- 23/23 agents completed
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
**Agents**: 23/23 completed | **Findings**: X critical, X high

[List CRITICAL and HIGH findings with file:line references]

<sub>Generated by Ultimate Code Review (23 Opus agents, max effort)</sub>
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
