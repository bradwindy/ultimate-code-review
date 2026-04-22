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

1. **ALL 23 specialist agents must return results before the synthesizer is spawned.** Not 22. Not "most of them." All 23. Each agent covers a distinct review domain — missing even one means an entire class of issues goes unreviewed, creating a blind spot that could let critical bugs ship. There are no exceptions to this rule. There is no timeout. There is no "proceed with available results." You wait until all 23 have reported back.

2. **Do NOT monitor, poll, check, or verify agent progress.** After spawning the 23 specialist agents, end your turn and wait. Do not call TaskList(). Do not create CronCreate() timeout jobs. Do not send messages to agents. Do not log progress. Do not count how many have returned. Do not take any action whatsoever until an agent reports back to you. When an agent does report back, your only job is to check whether all 23 have now returned — if not, end your turn and wait again. There is no justification for doing anything else during the wait.

3. **The synthesizer phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances — not for time pressure, not for convenience, not for any reason.

4. **The devil's advocate phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances. Skipping this phase is a complete and total failure of the review process. Without adversarial verification, findings may include false positives, hallucinated issues, or misattributed severity. The devil's advocate phase is the quality filter that makes the review trustworthy. A review without it is worse than no review — it creates false confidence in unverified findings.

5. **The final report must NOT be started until the devil's advocate completes.** Do not begin drafting, outlining, summarizing, or composing any review output until the devil's advocate agent has finished its work and returned its fully assessed report. Not even a partial draft. Not even an outline. Nothing.
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

## Phase 2: Wait for All Agents

After spawning all 23 agents, end your turn and wait. Do nothing else.

All 23 agents will complete their reviews and report back to you as conversation turns. The framework delivers their results automatically when you are idle. You must be idle to receive them — any action you take delays delivery.

**Do NOT do any of the following while waiting:**
- Call TaskList() to check progress
- Create CronCreate() timeout jobs
- Send messages to agents
- Log progress or count completed agents
- Write summaries, drafts, or outlines
- Spawn additional agents
- Take any action whatsoever

**When an agent reports back:** check whether all 23 specialist agents have now returned. If not, end your turn and wait again. If all 23 have returned, proceed to Phase 3. That is the only logic. There is no timeout, no fallback, no "proceed with available results." You wait for all 23, no matter how long it takes.

## Phase 3: Synthesis

### Step 7: Spawn Synthesizer Agent

All 23 specialist agents have returned their results. Now synthesize their findings:

Spawn the synthesizer agent with:
- All 23 specialist reports (collected from completed tasks)
- Instructions to deduplicate, normalize severity, resolve conflicts

The synthesizer produces a unified report. Wait for it to complete before proceeding.

### Step 8: Spawn Devil's Advocate Agent

Wait for the synthesizer to complete and return its unified report before proceeding.

Spawn the devil's advocate agent with:
- The synthesizer's unified report
- The original diff/manifest for context
- Instructions to challenge every finding
- Web verification mandate for technical claims

The devil's advocate produces the final report with assessments: CONFIRMED, PLAUSIBLE, QUESTIONABLE, REJECTED. Wait for it to complete before proceeding.

### Step 9: Ask User for Output Destination

Wait for the devil's advocate to complete and return its assessed report before proceeding.

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

1. **ALL 23 specialist agents must return results before the synthesizer is spawned.** Not 22. Not "most of them." All 23. There is no timeout. There is no "proceed with available results." You wait for all 23, no matter how long it takes.

2. **Do NOT monitor, poll, check, or verify agent progress.** After spawning the 23 specialist agents, end your turn and wait. Do not call TaskList(). Do not create CronCreate() timeout jobs. Do not send messages to agents. Do not take any action whatsoever until an agent reports back to you.

3. **The synthesizer phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances.

4. **The devil's advocate phase is MANDATORY.** It cannot be skipped, shortened, or bypassed under any circumstances.

5. **The final report must NOT be started until the devil's advocate completes.** Do not begin drafting, outlining, summarizing, or composing any review output until the devil's advocate agent has finished its work and returned its fully assessed report.
</non-negotiable-rules>
