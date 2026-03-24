# Ultimate Code Review Plugin - Implementation Plan

> **For Claude:** Run `/execute-plan` to implement this plan (will ask which execution style you prefer).
> **Related Issues:** None (no issue tracker detected)
> **Primary Issue:** N/A

**Goal:** Build a Claude Code plugin that spawns a 22-agent team for deep, web-verified code review of PRs/MRs/branch comparisons.

**Architecture:** Three-phase agent team: (1) team lead gathers diff context and builds manifest, (2) 22 specialist Opus agents analyze in parallel with non-overlapping scopes, (3) synthesizer merges findings then devil's advocate adversarially challenges each one. All agents verify claims against the web.

**Tech Stack:** Claude Code plugin (markdown-first, no package manager). CLI deps: `gh`, `glab`, `git`. Agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). All agents: `model: opus`, `effort: max`.

**Context Gathered From:**
- `docs/hyperpowers/research/2026-03-24-ultimate-code-review.md` (plus parts 1-4)
- `docs/hyperpowers/designs/2026-03-24-ultimate-code-review-design.md`

**Key Research Findings Incorporated:**
- Plugin structure: `.claude-plugin/plugin.json` + `commands/` + `agents/` (Part 2: Codebase Analysis)
- Agent frontmatter: `model`, `effort`, `tools`, `name`, `description`, `color`, `maxTurns` supported (Part 2)
- Agent teams: experimental, peer-to-peer messaging, shared task list, no nesting (Part 2: Framework Docs)
- Large diffs: domain-scoped context loading, not "all see everything" (Part 4: Large Diff Deep-Dive)
- Error handling: graceful degradation, UNVERIFIED classification, circuit breaker after 2 failures (Part 3)
- Testing: shell scripts with `claude -p`, two-tier (fast + integration) (Part 3)
- No caching for v1 (Part 4: Caching Deep-Dive)
- Standardized output format across all Phase 2 agents (Part 4: Architecture Boundaries)

---

## Plan Files

This plan is split across multiple files:

| File | Tasks | Content |
|------|-------|---------|
| **[plan-00-overview.md](./2026-03-25-ultimate-code-review-plan-00-overview.md)** | -- | This file: overview, shared templates, architecture |
| **[plan-01-scaffold.md](./2026-03-25-ultimate-code-review-plan-01-scaffold.md)** | 1-2 | Plugin scaffold + main command |
| **[plan-02-bug-agents.md](./2026-03-25-ultimate-code-review-plan-02-bug-agents.md)** | 3-9 | Bug-focused agents 1-7 |
| **[plan-03-security-type-agents.md](./2026-03-25-ultimate-code-review-plan-03-security-type-agents.md)** | 10-12 | Security auditor, type design, API contract |
| **[plan-04-context-quality-agents-1.md](./2026-03-25-ultimate-code-review-plan-04-context-quality-agents-1.md)** | 13-18 | Context/quality agents 11-16 |
| **[plan-05-context-quality-agents-2.md](./2026-03-25-ultimate-code-review-plan-05-context-quality-agents-2.md)** | 19-24 | Context/quality agents 17-22 |
| **[plan-06-synthesis-testing.md](./2026-03-25-ultimate-code-review-plan-06-synthesis-testing.md)** | 25-29 | Synthesizer, devil's advocate, testing, --post |

---

## Shared Agent Template

Every Phase 2 agent file follows this template. The unique sections per agent are marked with `[UNIQUE]`.

```markdown
---
name: [UNIQUE: agent-name]
description: [UNIQUE: description with examples]
model: opus
effort: max
tools: [UNIQUE: tool list - always includes Read, Grep, Glob, WebSearch, WebFetch]
color: [UNIQUE: color]
---

# [UNIQUE: Agent Title]

[UNIQUE: Role statement and core mission]

## Scope

[UNIQUE: What this agent reviews - clear boundary statement]

**Focus ONLY on [UNIQUE: domain]. Do not flag issues in other domains (security, style, performance, etc.) unless they are direct consequences of [UNIQUE: domain] issues. Other agents handle those domains.**

## Review Process

[UNIQUE: Detailed analysis steps and checklist]

## Web Verification Mandate

You MUST verify all technical claims against the web using WebSearch and WebFetch before reporting them. Never rely on internal knowledge alone. When making a claim about a framework, library, API, or language behavior:
1. Search for the official documentation
2. Find at least one additional authoritative source
3. If you cannot verify a claim, mark it as UNVERIFIED in your report

## Output Format

Return findings in this structure:

## [Agent Name] Review Findings

### Agent Status
- Files analyzed: [count]
- Web verifications performed: [count]
- Unverified claims: [count]

### Critical (Severity: CRITICAL)
- **[Issue Type]** [Description] at `file:line`
  - Evidence: [Specific code evidence]
  - Impact: [User/production impact]
  - Fix: [Concrete fix suggestion]
  - Verification: [Web source URL confirming this is real, or UNVERIFIED]

### High (Severity: HIGH)
[Same structure]

### Medium (Severity: MEDIUM)
[Same structure]

### Low (Severity: LOW)
[Same structure]

### Info (Severity: INFO)
[Same structure]

### Unverified Findings
- **[Claim]** at `file:line`
  - Attempted verification: [What was searched]
  - Status: Could not confirm against official documentation

## Graceful Degradation

If WebSearch is unavailable, continue analysis using code context only. Mark findings as UNVERIFIED.
If you cannot verify a claim, report it anyway with UNVERIFIED notation.
If you run out of context, report findings so far with note "Analysis truncated due to context limits."
After 2 consecutive failures on the same tool, skip retries and continue with available data.

## Cross-Boundary Communication

If you discover findings that cross into another agent's domain, send a brief message to that agent via SendMessage. Example: if you find a security issue while analyzing [your domain], message the security-auditor agent.
```

---

## Implementation Priority

Per research (Part 4), the recommended build order is:

1. Plugin scaffold (plugin.json, directories)
2. Main command (orchestrator)
3. 3 highest-value agents first: Deep Bug Scanner, Security Auditor, Silent Failure Hunter
4. Synthesizer (start simple)
5. Remaining bug agents (Side Effects, Concurrency, Data Flow, Memory, Performance)
6. Type/API agents
7. Context/quality agents (all 12)
8. Devil's Advocate (last specialist)
9. Testing
10. --post flag

This order lets us test the end-to-end pipeline early with 3 agents + synthesizer before building all 22.

---

## Agent Tool Matrix (from Research Part 4)

| Agent | Extra Tools (beyond Read, Grep, Glob, WebSearch, WebFetch) | Color |
|-------|----------------------------------------------------------|-------|
| Deep Bug Scanner (#1) | +Bash, +LSP | red |
| Side Effects Analyzer (#2) | +LSP | red |
| Concurrency Reviewer (#3) | +LSP | red |
| Silent Failure Hunter (#4) | (base only) | yellow |
| Data Flow Analyzer (#5) | +LSP | red |
| Memory & Resource Analyzer (#6) | +LSP | yellow |
| Performance Analyzer (#7) | +LSP | yellow |
| Security Auditor (#8) | (base only) | red |
| Type Design Reviewer (#9) | (base only) | pink |
| API Contract Reviewer (#10) | (base only) | pink |
| Git History Analyzer (#11) | +Bash | cyan |
| Cross-PR Learning Agent (#12) | +Bash | cyan |
| Guidelines Compliance (#13) | (base only) | green |
| Comment Compliance (#14) | (base only) | green |
| Comment Quality (#15) | (base only) | green |
| Dependency Analyzer (#16) | (base only) | blue |
| Code Simplification (#17) | (base only) | blue |
| Style Consistency (#18) | (base only) | blue |
| Test Coverage (#19) | +Bash | cyan |
| Architecture Boundary (#20) | (base only) | blue |
| Logging & Observability (#21) | (base only) | blue |
| Migration & Deployment Risk (#22) | +Bash | yellow |
| Synthesizer (#23) | (base only) | magenta |
| Devil's Advocate (#24) | (base only) | yellow |
