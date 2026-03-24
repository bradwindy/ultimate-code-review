# Ultimate Code Review

Deep code review plugin for Claude Code. Spawns a 23-agent team to review PRs, MRs, or branch comparisons.

## Quick Start

```
/plugin marketplace add bradwindy/ultimate-code-review
/plugin install ultimate-code-review@ultimate-code-review
/ultimate-code-review https://github.com/org/repo/pull/123
```

## Requirements

- Claude Code v1.0.33+
- Opus model access (Pro plan or higher)
- Agent teams enabled: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `gh` CLI (for GitHub PRs)
- `glab` CLI (for GitLab MRs)
- `git` (always required)

## Installation

### From Marketplace (recommended)

```bash
# Add the marketplace
/plugin marketplace add bradwindy/ultimate-code-review

# Install the plugin
/plugin install ultimate-code-review@ultimate-code-review
```

### Local Development

```bash
git clone git@github.com:bradwindy/ultimate-code-review.git
claude --plugin-dir ./ultimate-code-review
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
2. **Deep Analysis**: 23 specialist agents review in parallel (all Opus, max effort)
3. **Synthesis**: Findings merged, then adversarially challenged by devil's advocate

All agents verify technical claims against the web. No reliance on internal knowledge.

## Agents

23 specialist agents with non-overlapping scopes:

**Bug-Focused (1-7):** Deep Bug Scanner, Side Effects Analyzer, Concurrency Reviewer, Silent Failure Hunter, Data Flow Analyzer, Memory & Resource Analyzer, Performance Analyzer

**Security & Types (8-10):** Security Auditor, Type Design Reviewer, API Contract Reviewer

**Context & Quality (11-23):** Git History Analyzer, Cross-PR Learning Agent, Guidelines Compliance, Comment Compliance Checker, Comment Quality Reviewer, Dependency Analyzer, Code Simplification, Style Consistency, Test Coverage Analyzer, Architecture Boundary, Logging & Observability, Migration & Deployment Risk, Scope Relevance Reviewer

**Synthesis (24-25):** Synthesizer, Devil's Advocate

## Cost

This plugin uses 23+ Opus agents at max effort. Expect significant token usage ($5-50+ per review depending on diff size). This is by design -- depth over economy.

## License

MIT -- see [LICENSE](LICENSE) for details.
