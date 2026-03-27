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

<non-negotiable-rules>
## ABSOLUTE RULES — READ BEFORE PROCEEDING

These rules are non-negotiable. Violating any of them means the review has failed completely.

1. **ALL 23 specialist agents must return results before the synthesizer is spawned.** Not 22. Not "most of them." All 23. Each agent covers a distinct review domain — missing even one means an entire class of issues goes unreviewed, creating a blind spot that could let critical bugs ship. If an agent failed to start (its task is still `pending` after ~5 minutes), kill it and spawn a replacement. All 23 review domains must produce completed results before synthesis begins.

2. **The synthesizer phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances — not for time pressure, not for convenience, not for any reason.

3. **The devil's advocate phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances. Skipping this phase is a complete and total failure of the review process. Without adversarial verification, findings may include false positives, hallucinated issues, or misattributed severity. The devil's advocate phase is the quality filter that makes the review trustworthy. A review without it is worse than no review — it creates false confidence in unverified findings.

4. **The final report must NOT be started until the devil's advocate completes.** Do not begin drafting, outlining, summarizing, or composing any review output until the devil's advocate agent has finished its work and returned its fully assessed report. Not even a partial draft. Not even an outline. Nothing.

5. **Slow agents are expected and must not be killed.** Some agents (deep-bug-scanner, security-auditor, performance-analyzer, data-flow-analyzer) legitimately take much longer than others because they trace full call graphs, verify claims against the web, or analyze complex data flows. An agent may run for 15+ minutes on a single turn and cannot respond to messages during that time. This is normal. Do NOT kill or replace agents based on duration alone. Only replace agents whose tasks are still `pending` (they never started).

### Pre-Phase-Transition Checklist

Before transitioning from Phase 2 to Phase 3, you MUST verify:
- [ ] Exactly 23 specialist agent tasks show status `completed`
- [ ] Every review domain has a result (no gaps)
- [ ] All replacement agents (if any) have also completed

Before spawning the devil's advocate, you MUST verify:
- [ ] The synthesizer has completed and produced a unified report

Before composing any output, you MUST verify:
- [ ] The devil's advocate has completed and produced its assessed report
</non-negotiable-rules>

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

After spawning all 23 agents, you MUST actively monitor their progress and wait for ALL of them to complete. Do NOT proceed to Phase 3 until all 23 specialist agent tasks have status `completed`. There is no shortcut past this requirement.

### Step 6a: Active Polling Loop

Execute the following loop. You MUST call `TaskList()` repeatedly — do NOT proceed after a single check.

1. Set `checks_done = 0` and `max_checks = 45` (each cycle ~20 seconds = ~15 minutes total)
2. Call `TaskList()` to get the current status of all specialist agent tasks
3. Count how many tasks have status `completed` vs `in_progress` vs `pending`
4. **If ALL 23 specialist agent tasks are `completed`**: exit the loop and proceed to Step 6d (Pre-Synthesis Verification Gate)
5. **If `checks_done >= max_checks`**: proceed to Step 6c (Timeout Recovery) — do NOT proceed to Phase 3
6. Otherwise, increment `checks_done` and continue the loop from step 2

Between checks, process any incoming messages from agents. Agents may send you cross-boundary findings or status updates. Read and acknowledge these before the next TaskList check.

### Step 6b: Periodic Agent Monitoring

Every 5 checks (approximately every 100 seconds), perform the following:

#### 1. Failed-to-launch detection (CRITICAL)

Check if any agent's task is still `pending`. An agent whose task remains `pending` after 15 checks (~5 minutes) never started — it failed to spawn or initialize. This is the primary failure mode (typically affects 1-2 agents per session).

**Action for failed-to-launch agents:**
1. Log which agent failed to start and its review domain
2. Kill the failed agent
3. Spawn a fresh replacement agent with the exact same task assignment, manifest, and instructions
4. Create a new task for the replacement and track it in your completion count
5. The replacement starts fresh — it does not inherit state from the failed agent

#### 2. Status checks for active agents

If any agent's task has been `in_progress` for 5 or more consecutive checks, send a non-urgent status check:
```
SendMessage(to: "<agent-name>", message: "Status check: please report your progress when you finish your current step. Take as long as you need for thorough analysis.")
```

**Agents mid-turn cannot respond to messages.** When an agent is executing tool calls (bash commands, web searches, file reads), incoming messages queue in its inbox and are only processed when the current turn ends. An agent doing a 15-minute deep call-graph trace looks identical to a crashed agent — both are silent. Do NOT interpret silence as a failure. The task status (`in_progress` vs `pending`) is the only reliable signal.

Some agents legitimately take much longer than others. Deep-bug-scanner traces full call graphs. Security-auditor verifies CVEs against the web. Performance-analyzer researches framework-specific patterns. These agents may run for 15-20 minutes. A thorough agent is a good agent. Do NOT rush or kill active agents based on duration alone.

#### 3. Web verification compliance

If any agent's messages or findings contain no web verification URLs or references to WebSearch/WebFetch usage, send a reminder:
```
SendMessage(to: "<agent-name>", message: "REMINDER: The web verification mandate requires you to verify all technical claims using WebSearch and WebFetch against official documentation. Search for official sources before finalizing your findings. Mark any unverified claims as UNVERIFIED.")
```

#### 4. Progress logging

After each monitoring cycle, note the status: "X/23 agents completed, Y in progress, Z pending. [List any agents replaced due to failed-to-launch.]"

### Step 6c: Timeout Recovery

When the polling loop reaches `max_checks` (45) without all 23 agents completing, do NOT proceed to Phase 3. Instead, investigate and recover:

1. **Check each incomplete agent's task status:**
   - Task still `pending`: the agent never started. Kill and replace immediately (same procedure as Step 6b failed-to-launch detection).
   - Task `in_progress`: the agent is working. Do NOT kill it.

2. **Extend the polling loop** by 15 more checks (~5 more minutes) to allow active agents to finish. Continue monitoring per Step 6b during this extension.

3. **If the extended window also expires** with agents still `in_progress`:
   - If only 1-2 agents remain and all others (21-22) have completed, apply late-straggler recovery:
     1. Send a final status check message to the remaining agent(s)
     2. Wait 3 more polling cycles (~60 seconds)
     3. If still no response and task still `in_progress`: kill and spawn a replacement
   - If 3+ agents are still `in_progress`, extend polling by another 10 checks (~3 more minutes). Multiple agents still working likely indicates a legitimately large review.

4. **Absolute last resort** (after ~25 minutes total with recovery attempts): if agents still have not completed despite replacements and extended polling, record which review domains are missing and proceed to Phase 3 with available results. Pass the missing domain list to the synthesizer for coverage gap reporting.

This last-resort path should be extremely rare. The failed-to-launch detection in Step 6b should catch the primary problem (agents that never started) within the first 5 minutes.

### Step 6d: Pre-Synthesis Verification Gate

Before proceeding to Phase 3, you MUST complete this verification. Do not skip it.

1. Call `TaskList()` one final time
2. Confirm the following — every item must pass:
   - [ ] Exactly 23 specialist agent tasks show status `completed` (count them)
   - [ ] Every review domain is covered (cross-reference the 23 domains: deep-bug-scanner, security-auditor, data-flow-analyzer, side-effects-analyzer, silent-failure-hunter, concurrency-reviewer, memory-resource-analyzer, performance-analyzer, type-design-reviewer, api-contract-reviewer, architecture-boundary, dependency-import-analyzer, test-coverage-analyzer, code-simplification, style-consistency, comment-quality-reviewer, comment-compliance-checker, guidelines-compliance, logging-observability, migration-deployment-risk, git-history-analyzer, scope-relevance-reviewer, cross-pr-learning-agent)
   - [ ] No replacement agents are still `in_progress` or `pending`
   - [ ] If any agents were killed and replaced, their replacements show `completed`
3. **If ANY check fails**: DO NOT proceed to Phase 3. Return to the polling loop and resolve the gap.
4. **If ALL checks pass**: proceed to Phase 3.

## Phase 3: Synthesis

**Every step in Phase 3 is MANDATORY. No step can be skipped, shortened, or bypassed. Skipping any step is a complete failure of the review.**

### Step 7: Spawn Synthesizer Agent

**This step is MANDATORY. It cannot be skipped regardless of time pressure or any other consideration.**

All 23 specialist agents have completed (verified in Step 6d). Now synthesize their findings:

Spawn the synthesizer agent with:
- All 23 specialist reports (collected from completed tasks)
- Agent completion status (which agents finished on first attempt, which required replacement)
- Instructions to deduplicate, normalize severity, resolve conflicts

The synthesizer produces a unified report. Wait for it to complete before proceeding.

### Step 8: Spawn Devil's Advocate Agent

**This step is MANDATORY. It cannot be skipped regardless of time pressure or any other consideration.** Skipping this phase renders the entire review worthless — every finding must survive adversarial scrutiny before reaching the developer. A review without devil's advocate verification is worse than no review at all, because it creates false confidence in unverified findings.

**STOP. Before spawning the devil's advocate, confirm:** the synthesizer has completed and produced a unified report. If the synthesizer has not completed, wait for it. Do not proceed.

Spawn the devil's advocate agent with:
- The synthesizer's unified report
- The original diff/manifest for context
- Instructions to challenge every finding
- Web verification mandate for technical claims

The devil's advocate produces the final report with assessments: CONFIRMED, PLAUSIBLE, QUESTIONABLE, REJECTED. Wait for it to complete before proceeding.

### Step 9: Ask User for Output Destination

**STOP. Before proceeding to output, confirm:** the devil's advocate has completed and produced its final assessed report. Do NOT display, write, summarize, draft, outline, or begin composing any review output until this gate passes. If the devil's advocate has not completed, wait for it.

**Do NOT output any review findings, summaries, or report content before the user answers the question below.**

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

<non-negotiable-rules>
## REMINDER — ABSOLUTE RULES (repeated for emphasis)

These rules are non-negotiable. Violating any of them means the review has failed completely.

1. **ALL 23 specialist agents must return results before the synthesizer is spawned.** Not 22. Not "most of them." All 23. Each agent covers a distinct review domain — missing even one means an entire class of issues goes unreviewed, creating a blind spot that could let critical bugs ship. If an agent failed to start (its task is still `pending` after ~5 minutes), kill it and spawn a replacement. All 23 review domains must produce completed results before synthesis begins.

2. **The synthesizer phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances — not for time pressure, not for convenience, not for any reason.

3. **The devil's advocate phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances. Skipping this phase is a complete and total failure of the review process. Without adversarial verification, findings may include false positives, hallucinated issues, or misattributed severity. The devil's advocate phase is the quality filter that makes the review trustworthy. A review without it is worse than no review — it creates false confidence in unverified findings.

4. **The final report must NOT be started until the devil's advocate completes.** Do not begin drafting, outlining, summarizing, or composing any review output until the devil's advocate agent has finished its work and returned its fully assessed report. Not even a partial draft. Not even an outline. Nothing.

5. **Slow agents are expected and must not be killed.** Some agents (deep-bug-scanner, security-auditor, performance-analyzer, data-flow-analyzer) legitimately take much longer than others because they trace full call graphs, verify claims against the web, or analyze complex data flows. An agent may run for 15+ minutes on a single turn and cannot respond to messages during that time. This is normal. Do NOT kill or replace agents based on duration alone. Only replace agents whose tasks are still `pending` (they never started).
</non-negotiable-rules>
