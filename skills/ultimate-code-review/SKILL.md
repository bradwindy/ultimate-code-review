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

### Step 0: Clean Up Stale State

Before doing anything else, clean up any stale manifest from a prior run of this same review:

1. Parse the review target from $ARGUMENTS (see Step 1) to determine the `<ticket>` identifier
2. Delete `$TMPDIR/ucr-manifest-<ticket>.md` if it exists

**Only delete the manifest file for the current ticket. Do NOT touch manifest files for other tickets — they belong to other reviews.**

### Step 1: Parse Arguments

Parse $ARGUMENTS to determine the review target:

1. **PR URL** (contains `github.com` and `pull`): Extract owner/repo and PR number. Use `gh pr diff` and `gh pr view`. Set `<ticket>` to the PR number (e.g. `PR-123`).
2. **MR URL** (contains `gitlab.com` and `merge_requests`): Extract project and MR number. Use `glab mr diff` and `glab mr view`. Set `<ticket>` to the MR number (e.g. `MR-456`).
3. **Branch range** (contains `..`): Use `git diff <range>`. Set `<ticket>` to the branch range with `/` replaced by `-` (e.g. `feature-foo..main`).
4. **No arguments**: Detect upstream branch and diff against it.
   - Try: `git rev-parse --abbrev-ref @{upstream}` to find tracking branch
   - Fallback: diff against `main` or `master` (whichever exists)
   - Set `<ticket>` to the current branch name with `/` replaced by `-`

Store the `<ticket>` identifier for use in manifest and output filenames throughout this review.

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
   - Root `REVIEW.md` (if exists) -- review-specific guidance per Anthropic convention
   - `.editorconfig` (if exists)
5. **Project structure**: Read `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `build.gradle`, `pom.xml`, or similar config files to identify the tech stack
6. **File count classification**:
   - 1-100 files: Small diff (all agents review all files)
   - 100-300 files: Medium diff (all agents review all files, tight context)
   - 300+ files: Large diff (agents must use domain-scoped loading)

Write the manifest summary to a temporary file at `$TMPDIR/ucr-manifest-<ticket>.md` containing:
- File list with change types
- Tech stack summary
- Guidelines summary (including any REVIEW.md rules)
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

After spawning all 23 agents, you MUST actively monitor their progress and wait for completion. Do NOT proceed to Phase 3 until all agents have completed or the timeout is reached.

### Step 6a: Active Polling Loop

Execute the following loop. You MUST call `TaskList()` repeatedly — do NOT proceed after a single check.

1. Set `checks_done = 0` and `max_checks = 45` (each cycle ~20 seconds = ~15 minutes total)
2. Call `TaskList()` to get the current status of all 23 agent tasks
3. Count how many tasks have status `completed` vs `in_progress` vs `pending`
4. **If ALL 23 agent tasks are `completed`**: exit the loop and proceed to Phase 3
5. **If `checks_done >= max_checks`**: exit the loop (timeout) and proceed to Phase 3 with available results
6. Otherwise, increment `checks_done` and continue the loop from step 2

Between checks, process any incoming messages from agents. Agents may send you cross-boundary findings or status updates. Read and acknowledge these before the next TaskList check.

### Step 6b: Periodic Agent Monitoring

Every 5 checks (approximately every 100 seconds), perform the following:

1. **Stall detection**: If any agent's task has been `in_progress` for 3 or more consecutive checks without completing, send it a status check:
   ```
   SendMessage(to: "<agent-name>", message: "Status check: you have been running for a while. Please report your progress or complete your task. Remember: you MUST use WebSearch and/or WebFetch to verify all technical claims before reporting findings.")
   ```

2. **Web verification compliance**: If any agent's messages or findings contain no web verification URLs or references to WebSearch/WebFetch usage, send it a reminder:
   ```
   SendMessage(to: "<agent-name>", message: "REMINDER: The web verification mandate requires you to verify all technical claims using WebSearch and WebFetch against official documentation. Search for official sources before finalizing your findings. Mark any unverified claims as UNVERIFIED.")
   ```

3. **Progress logging**: After each monitoring cycle, note the status internally: "X/23 agents completed, Y in progress, Z pending."

### Step 6c: Timeout Handling

When the polling loop exits due to timeout (`checks_done >= max_checks`):

1. Record which agents completed and which did not
2. For each timed-out agent, record its last known status
3. Build a timeout summary to pass to the synthesizer in Phase 3:
   - List of completed agents with their task IDs
   - List of timed-out agents with their review domains (for coverage gap reporting)
4. Proceed to Phase 3 with whatever results are available

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

### Step 9: Ask User for Output Destination

**IMPORTANT: Do NOT output any review findings, summaries, or report content before the user answers this question.**

Before displaying or writing any review results, ask the user where they want the output using `AskUserQuestion`:

- **Output to this Claude Code session** — Display the full report directly in the terminal
- **Write to a file in the project** — Write the full report to `./code-review-<ticket>.md` in the current working directory, then display only a brief summary (overall assessment + finding counts) in the terminal
- **Write to a file in ~/Documents** — Write the full report to `~/Documents/code-review-<ticket>.md`, then display only a brief summary in the terminal
- **Other** — The user specifies a custom file path

Where `<ticket>` is the identifier derived in Step 1 (e.g. `PR-123`, `MR-456`, or the branch name).

For file output options, use the `Write` tool to create the file, then display only this brief summary in the terminal:

```
Review complete. Full report written to <path>.
Assessment: [merge-ready / needs-work / high-risk] | Agents: X/23 | Findings: X CRITICAL, X HIGH, X MEDIUM, X LOW
```

### Step 10: Present Results

If the user chose to output to this Claude Code session in Step 9, display the full report below. If they chose a file option, write the full report to the chosen file and display only the brief summary shown above.

Full report format:

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

### Step 11: Optional PR/MR Comment (--post)

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

### Step 12: Cleanup

Shut down all team members:
```
SendMessage(to: "*", message: {type: "shutdown_request", reason: "Review complete"})
```

Clean up temporary files:
```bash
rm -f $TMPDIR/ucr-manifest-<ticket>.md
```

Delete the team:
```
TeamDelete()
```
