# Research Part 4: Dependencies, Architecture, Edge Cases, Open Question Deep-Dives

> Part of: [Ultimate Code Review Research](./2026-03-24-ultimate-code-review.md)

---

## Dependency Analysis

*From: Dependency Analyst Agent*

### Dependency Management Approach

Claude Code plugins use a **declarative, markdown-first approach** with no traditional package managers. No package.json, requirements.txt, or equivalent. Plugin metadata lives in plugin.json; agent configuration lives in YAML frontmatter of markdown files.

### External CLI Dependencies

| Dependency | Minimum Version | Purpose | Required? |
|-----------|----------------|---------|-----------|
| `claude-code` | v2.1.80+ | `effort` frontmatter support (including `max`) | Yes |
| `gh` (GitHub CLI) | v2.50+ | `gh pr diff`, `gh pr view`, `gh pr comment`, `gh pr list` | For GitHub PRs |
| `glab` (GitLab CLI) | v1.20+ | `glab mr diff`, `glab mr view`, `glab mr list` | For GitLab MRs |
| `git` | v2.20+ | `git log`, `git blame`, `git show`, `git diff` | Yes (always available) |

### Platform Detection and Fallback

External tools form a dependency chain:
1. Plugin initialization checks `gh` / `glab` availability
2. If `gh` missing but `git remote` points to GitHub: can still process local diffs, warn about missing PR features
3. If `glab` missing but `git remote` points to GitLab: same
4. Git is mandatory (always available in Claude Code environments)

Installation guidance per platform:
- macOS: `brew install gh glab`
- Linux: Package manager varies; direct installation via releases
- Windows: `winget install gh glab`
- WSL: Use Linux package managers; recommend WSL2

### Model Availability Constraints

- **Opus requires Pro/Max/Team/Enterprise plan** (1M context)
- Standard/Pro plans limited to older Opus versions or shorter context
- WebSearch/WebFetch available at all plan tiers (no restriction)
- LSP dependent on language servers being installed in the codebase

**Risk**: Users on lower tiers cannot run the plugin as designed. The plugin should detect this early and fail with a clear message rather than silently degrading.

### Version Constraints

- `effort` frontmatter added in Claude Code v2.1.80 (supports `low`, `medium`, `high`, `max`)
- Agent teams are experimental, require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Adaptive thinking is automatic with Opus (no manual configuration)
- `color` field for visual indicators observed in official plugins

### Agent Tool Requirements (Complete List)

| Agent | Tools (beyond base Read, Grep, Glob, WebSearch, WebFetch) |
|-------|----------------------------------------------------------|
| Diff Context Gatherer (Team Lead) | +Bash, +LSP |
| Deep Bug Scanner (#1) | +Bash, +LSP |
| Side Effects Analyzer (#2) | +LSP |
| Concurrency Reviewer (#3) | +LSP |
| Silent Failure Hunter (#4) | (base only) |
| Data Flow Analyzer (#5) | +LSP |
| Memory & Resource Analyzer (#6) | +LSP |
| Performance Analyzer (#7) | +LSP |
| Security Auditor (#8) | (base only) |
| Type Design Reviewer (#9) | (base only) |
| API Contract Reviewer (#10) | (base only) |
| Git History Analyzer (#11) | +Bash |
| Cross-PR Learning Agent (#12) | +Bash |
| Guidelines Compliance (#13) | (base only) |
| Comment Compliance (#14) | (base only) |
| Comment Quality (#15) | (base only) |
| Dependency Analyzer (#16) | (base only) |
| Code Simplification (#17) | (base only) |
| Style Consistency (#18) | (base only) |
| Test Coverage (#19) | +Bash |
| Architecture Boundary (#20) | (base only) |
| Logging & Observability (#21) | (base only) |
| Migration & Deployment Risk (#22) | +Bash |
| Synthesizer (#23) | (base only) |
| Devil's Advocate (#24) | (base only) |

---

## Architecture Boundaries Analysis

*From: Architecture Boundaries Analyst Agent*

### Communication Flow

```
User invokes /ultimate-code-review
    |
    v
[Command: ultimate-code-review.md]
    |
    v
[Phase 1: Diff Context Gatherer - Team Lead]
    |  Builds change manifest
    |  Creates tasks for all 22 specialists
    |
    +---> [Task List] ---> All 22 agents claim tasks
    |
    v
[Phase 2: 22 Parallel Specialists]
    |  Each reads manifest
    |  Each loads domain-relevant files via Grep/Read
    |  Each produces structured findings report
    |  Cross-boundary alerts via SendMessage
    |
    +---> [Findings Reports] ---> Synthesizer
    |
    v
[Phase 3a: Synthesizer]
    |  Deduplicates, normalizes severity
    |  Resolves conflicts
    |  Produces unified report
    |
    v
[Phase 3b: Devil's Advocate]
    |  Challenges every finding
    |  Verifies via web search
    |  Marks: CONFIRMED / PLAUSIBLE / QUESTIONABLE / REJECTED
    |
    v
[Final Output: Terminal + optional --post to PR/MR]
```

### Boundary Analysis: Where Agents Might Overlap

#### Data Flow Analyzer (#5) vs Security Auditor (#8)

Both analyze data at boundaries.
- **Data Flow**: Focuses on correctness (is data transformed correctly? PII leaking? encoding errors?)
- **Security Auditor**: Focuses on exploitation potential (can attacker bypass validation? inject SQL? traverse paths?)
- **Resolution**: Partition by responsibility, not by data path. Both are independent; findings may overlap but from different angles. This is intentional cross-verification. The synthesizer deduplicates.

#### Guidelines Compliance (#13) vs Comment Compliance (#14)

Completely separate data sources:
- **Guidelines Compliance**: Reads CLAUDE.md, .editorconfig, linting configs. ONLY flags violations explicitly stated in project configuration.
- **Comment Compliance**: Scans inline code comments for directives like "do not modify without updating X". Verifies whether changes honored those directives.
- **No overlap**: Different inputs, different outputs.

#### Memory Analyzer (#6) vs Performance Analyzer (#7)

Both could flag unbounded growth or missing pagination.
- **Memory Analyzer**: "This will run out of memory" (resource exhaustion)
- **Performance Analyzer**: "This will slow down as data grows" (latency impact)
- **Resolution**: Partition by consequence. Memory = resource exhaustion. Performance = latency degradation. Example: Unbounded array -> Memory flags retain cycle; Performance flags O(n^2) algorithm. Both valid for different audiences.

#### Comment Quality (#15) vs Comment Compliance (#14)

Different data flows:
- **Comment Quality**: Reads comments, checks if they're factually accurate against the implementation
- **Comment Compliance**: Reads comments, checks if the code honored inline directives
- **No overlap**: Quality checks accuracy; Compliance checks adherence to directives.

#### Type Design Reviewer (#9) vs Architecture Boundary (#20)

Different granularity:
- **Type Design**: Individual type invariants, encapsulation, field visibility, constructor validation
- **Architecture**: Module structure, layer violations, coupling, separation of concerns
- **Resolution**: Type design focuses on ONE type at a time. Architecture focuses on HOW types are used across modules. Example: Type designer says "UserAccount should validate email in constructor" (type-level). Architect says "UserAccount shouldn't be created by the HTTP layer directly" (architecture-level).

#### Guidelines Compliance (#13) vs Code Simplification (#17)

Independent concerns:
- **Guidelines**: Explicit CLAUDE.md requirements (never invents rules)
- **Simplification**: Reducing complexity while preserving functionality
- **Resolution**: These are independent. Complexity reduction might violate guidelines (in which case guidelines wins). The synthesizer handles conflicts.

### Standardized Phase 2 Output Format

All 22 specialist agents should produce reports in this format:

```markdown
## [Agent Name] Review Findings

### Critical (Severity: CRITICAL)
- **[Issue Type]** [Description] at `file:line`
  - Evidence: [Specific code evidence]
  - Impact: [User/production impact]
  - Fix: [Concrete fix suggestion]
  - Verification: [Web source confirming this is a real issue, or UNVERIFIED]

### High (Severity: HIGH)
- ...

### Medium (Severity: MEDIUM)
- ...

### Low (Severity: LOW)
- ...

### Info (Severity: INFO)
- ...

### Unverified Findings
- **[Claim]** at `file:line`
  - Attempted verification: [What was searched]
  - Status: Could not confirm against official documentation
```

### Devil's Advocate Output Format

```markdown
## Devil's Advocate Assessment

For each finding from synthesizer:

### Finding [N]: [Description]
- **Original Severity**: HIGH
- **Flagged By**: Security Auditor, Data Flow Analyzer
- **Challenge Questions**:
  1. Is this actually a vulnerability?
  2. Could this be intentional?
  3. Is severity overstated?
- **Web Verification**: [Sources checked, results]
- **Assessment**: CONFIRMED | PLAUSIBLE | QUESTIONABLE | REJECTED
- **Final Severity**: [Same or adjusted]
- **Reasoning**: [Evidence-based conclusion]
```

### Key Architectural Rules

1. **No sub-agent nesting**: Don't have agents launch other agents. Use team communication.
2. **Manifest as contract**: Team lead creates it once; all agents read it (read-only).
3. **Tool minimization**: Each agent gets minimal tools needed for its scope.
4. **Web verification**: Every technical claim verified against web (no exceptions).
5. **Non-overlapping scope**: If two agents report the same issue from different angles, that's cross-verification (good). If they report the same issue from the same angle, that's duplication (synthesizer deduplicates).
6. **Cross-boundary alerts encouraged**: Agents should message each other about findings that cross boundaries.
7. **Output standardization**: All Phase 2 agents use same severity scale and output format.
8. **Model consistency**: All agents use `model: opus` with `effort: max` (no exceptions per design constraint).

---

## Edge Cases & Gotchas

*Synthesized from all agents*

### Context Window Overflow

**The most critical edge case.** For diffs with 300+ files, the full content of changed files exceeds 1M tokens. Agents cannot receive everything. Solution: domain-scoped context loading where each agent uses Grep/LSP to find and load only files relevant to its specialty.

### Lost in the Middle

Stanford research (2024) demonstrates 30%+ accuracy degradation when relevant information is positioned in the middle of long context windows. For code review requiring multi-hop reasoning about interconnected changes, this creates compounding difficulties. Agents should structure their context so critical files are at the beginning and end of their window, not buried in the middle.

### Context Rot

Chroma (2025) research shows models exhibit significant performance degradation well before hitting maximum context. A 200K-token model shows measurable quality loss around 130K tokens (65% of capacity). For Opus with 1M context, practical usable capacity is ~650K tokens.

### Rate Limiting

22 parallel Opus agents with max effort will consume tokens rapidly. Account-level rate limits apply across all teammates. If limits are hit, agents queue and slow down. No published data exists on the exact impact of 22 concurrent Opus agents - requires empirical testing.

### Agent Team Experimental Status

Agent teams are experimental (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Known issues:
- No session resumption with in-process teammates
- Task status can lag
- Shutdown can be slow
- One team per session
- No nested teams

If the experimental flag is removed or the API changes, the plugin may need updates. This is a calculated risk.

### No CLAUDE.md in Target Project

Guidelines Compliance agent (#13) depends on CLAUDE.md files. If none exist, the agent should report "No project guidelines found" and skip, not fail. Similarly, Code Comment Compliance (#14) should handle projects with minimal comments gracefully.

### Mixed Platform Detection

If a repo has multiple remotes (e.g., both GitHub and GitLab mirrors), platform detection may be ambiguous. The team lead should use the primary remote (origin) and allow the user to override with explicit PR/MR URL.

### Agent Disagreement Escalation

If two agents independently reach opposite conclusions about the same code (e.g., "this is a bug" vs "this is intentional"), the synthesizer flags the conflict. The devil's advocate assigns QUESTIONABLE. But what if the devil's advocate ALSO can't resolve it? It should present both sides with evidence and let the human decide.

### WebSearch Rate Limiting

All 22 agents using WebSearch simultaneously could hit search rate limits. Agents should gracefully degrade to UNVERIFIED findings rather than failing entirely. Consider staggering web searches or implementing a shared search cache within the team.

### Large Binary Files in Diff

If the diff includes large binary files (images, compiled assets), agents should skip these. The team lead should filter binary files from the manifest.

### Monorepo with Unrelated Changes

A 1000-file diff in a monorepo might span completely unrelated services. The team lead should identify logical groupings (by directory/service) so agents can focus on coherent change sets rather than random file lists.

### Test Files vs Production Code

Some agents (like security auditor) should treat test files differently - a hardcoded API key in a test fixture is different from one in production code. Agents should be aware of test file conventions (test/, tests/, __tests__/, *.test.*, *.spec.*).

---

## Open Question Deep-Dives

### Deep-Dive: Quick Mode

*From: Best Practices Researcher (Quick Mode specialist)*

**Recommendation: AGAINST quick mode.**

Reasoning:
1. **Contradicts stated positioning**: Design says "22 specialist agents must run - anything less is a failure." Quick mode undermines this.
2. **Brand dilution**: Offering "lite" alongside "ultimate" only works when the quality gap is explained. Users will compare findings and lose trust when quick mode misses issues.
3. **Industry pattern differs**: Leading tools don't offer "fast vs thorough." They use dynamic agent deployment based on PR complexity - the system decides, not the user.
4. **Better alternative**: Use `effort: medium` instead of reducing agent count. This maintains the same 22 agents and positioning, just adjusts reasoning depth. Matches Anthropic's own recommendation.

If forced to implement a subset, minimum viable set: agents 1-7 (bug-focused) + 8 (security) + 24 (devil's advocate) = 9 agents covering ~80% of critical findings. But this contradicts the design.

**Sources**:
- [HubSpot Sidekick](https://www.infoq.com/news/2026/03/hubspot-ai-code-review-agent/)
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Anthropic - Opus 4.6 Features](https://www.anthropic.com/news/claude-opus-4-6)

### Deep-Dive: Caching

*From: Architecture Boundaries Analyst (Caching specialist)*

**Recommendation: DEFER to v2.**

Key findings:
1. **Anthropic's official code-review plugin does NOT cache.** It re-runs fresh analysis each time. The only "cache" is checking if Claude has already commented on the PR (skip condition, not result cache).
2. **Prompt caching provides zero benefit here.** In non-interactive workflows (parallel agents, each running once), the cache is written once and never read - a net cost with zero benefit. Source: GitHub issue anthropics/claude-code#34334.
3. **Cache invalidation is extremely complex**:
   - File content changed (easy: hash the file)
   - Framework updated (requires tracking version in cache key)
   - Agent prompt changed (requires tracking agent version)
   - External vulnerability disclosed (requires tracking CVE timestamps)
   - Code changed elsewhere affecting this file (requires dependency graph)
4. **No production AI code review tool caches this way.** ESLint is stateless. Copilot uses session-based context. GitHub Code Scanning stores baselines per push but doesn't cache individual findings.

**v1 approach**: Implement stateless runs. Focus on proving 22-agent architecture works.

**v2 approach** (post-validation):
- Cache key: SHA256(diff_content)
- Cache dir: `~/.cache/ultimate-code-review/diffs/`
- TTL: 48 hours or until agent prompts change (version bump)
- `--no-cache` flag to force re-run
- File-level change detection without finding caching as intermediate step

**Sources**:
- Anthropic code-review plugin source code
- GitHub issue anthropics/claude-code#34334
- Claude API Docs - Prompt Caching

### Deep-Dive: Large Diff Handling

*From: Best Practices Researcher (Large Diff specialist)*

**Recommendation: Domain-scoped context, not file partitioning or "all agents see everything."**

Key findings:

1. **Token math makes "all see everything" impossible at scale**: 1000 files x 1000-2500 tokens = 1M-2.5M tokens for file content alone, BEFORE the diff. Exceeds 1M context window.

2. **"Lost in the middle" is real**: Stanford research shows 30%+ accuracy degradation when relevant info is in the middle of long contexts. Security agent reviewing 1000 files may miss critical injection vulnerability buried at file #500.

3. **Context rot starts at ~65% capacity**: Chroma research shows measurable quality loss well before max context. For 1M window, practical limit is ~650K tokens.

4. **Anthropic's own system uses adaptive scaling**: Large or complex changes get more agents and deeper reads; trivial ones get lightweight passes. Not "everyone sees everything."

5. **Domain specialization beats file partitioning**: Don't randomly split 1000 files across 22 agents (each gets ~45 files out of context, missing cross-file bugs). Instead, let each agent load domain-relevant files:
   - Security agent: auth files, SQL files, external API calls
   - Performance agent: hot paths, queries, bundle files
   - Architecture agent: module boundaries, imports, not all implementation details

**Recommended approach**:

Phase 1 (Team Lead):
- Identify ALL changed files (mandatory)
- Classify files by risk level (security-sensitive, performance-critical, etc.)
- Build change manifest with: file paths, change type, risk level, related files
- For 1000-file diffs, expect ~50-200 "truly changed or affected files" after filtering

Phase 2 (Agents):
- Each agent gets the manifest (lightweight, ~10K tokens)
- Each agent uses Grep/LSP to search for and load domain-relevant files
- Agents prioritize: (a) high-risk files, (b) files matching their domain, (c) related code
- Target ~50K tokens of loaded context per agent (well within 1M budget)

Phase 3 (Synthesis):
- Especially important for large diffs because agents saw scoped context
- Some findings may be incomplete - devil's advocate flags these
- Verify cross-file implications that individual agents might have missed

**Size thresholds**:
- 1-100 files: All agents review all files (fits in context)
- 100-300 files: All agents review all files (tight but feasible with Opus 1M)
- 300+ files: Domain-scoped loading required (exceeds practical context limits)

**Sources**:
- [Stanford - Lost in the Middle](https://arxiv.org/abs/2307.03172)
- [Chroma - Context Rot Research](https://www.trychroma.com/research/context-rot)
- [Graphite - AI Code Review Context](https://graphite.com/guides/ai-code-review-context-full-repo-vs-diff)
- [Augment Code - Large Codebases Guide](https://www.augmentcode.com/guides/ai-code-review-tools-for-large-codebases-enterprise-guide)
- [Aviator - Code Reviews at Scale](https://www.aviator.co/blog/code-reviews-at-scale/)
- [TechCrunch - Anthropic Code Review](https://techcrunch.com/2026/03/09/anthropic-launches-code-review-tool-to-check-flood-of-ai-generated-code/)

---

## Contradictions Between Agents

Research agents produced several contradictions worth noting:

### Agent Count: 22 vs 3-5

**Best Practices agent** recommended 5-6 specialized agents by default, citing Claude docs stating "3-5 is the sweet spot." **Codebase analyst** found no existing plugin uses more than 8 agents. **Error handling agent** recommended 8 agents for quick mode.

**Design constraint overrides**: The design explicitly requires 22 agents and states "anything less is a failure." The user has been informed of cost implications and accepts them. The research notes this as a trade-off but does not recommend changing the design.

### Model: All Opus vs Mixed Models

**Best Practices agent** strongly recommended Sonnet for specialist agents (97-99% as capable at 5x lower cost), citing CodeRabbit's hybrid architecture.

**Design constraint overrides**: "ALL agents MUST be Opus - no exceptions." The user explicitly rejected Haiku and Sonnet alternatives during the brainstorming phase. No specific Opus version is required; `model: opus` in frontmatter resolves to the latest available Opus.

### Caching: Now vs Later

**Error handling agent** recommended implementing caching at diff level. **Caching specialist** recommended deferring to v2. **Best practices agent** recommended aggressive caching for cost control.

**Resolution**: Defer to v2. Focus on proving the architecture works first. Cache invalidation complexity isn't worth the v1 risk.

### Error Threshold: Hard Fail vs Graceful Degradation

**Design says**: "22 specialist agents must run - anything less is a failure" (success criteria #8).
**Error handling agent says**: "Aim for 'report honestly how many agents succeeded.' Partial results with transparency beat silence."

**Recommendation**: Implement graceful degradation at the agent level (agents handle their own failures) but report agent completion status transparently. If 20/22 complete, the review is still valuable - just note the gaps. The user should see: "20/22 agents completed. Missing: Silent Failure Hunter (timeout), Migration Risk (timeout)."

---

## Implementation Priority Summary

Based on all research findings, recommended implementation order:

1. **Plugin scaffold**: plugin.json, directory structure, main command
2. **Phase 1 team lead agent**: Diff context gatherer with platform detection and manifest building
3. **3 highest-value Phase 2 agents**: Deep Bug Scanner (#1), Security Auditor (#8), Silent Failure Hunter (#4)
4. **Synthesizer (#23)**: Start simple, grow as more agents are added
5. **Remaining bug agents**: Side Effects (#2), Concurrency (#3), Data Flow (#5), Memory (#6), Performance (#7)
6. **Type/API agents**: Type Design (#9), API Contract (#10)
7. **Context/quality agents**: All 12 of agents #11-22
8. **Devil's Advocate (#24)**: Add last, once all specialist agents are producing reliable output
9. **Testing**: Fast tests throughout, integration tests after all agents working
10. **--post flag**: PR/MR comment posting (after terminal output is solid)
