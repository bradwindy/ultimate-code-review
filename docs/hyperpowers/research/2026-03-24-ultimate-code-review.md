# Research: Ultimate Code Review Plugin

> Generated: 2026-03-24
> Design Doc: docs/hyperpowers/designs/2026-03-24-ultimate-code-review-design.md
> Agents Dispatched: 11 (8 core + 3 open question specialists)

## Document Structure

This research is split across multiple files due to size:

- **This file**: Executive summary, resolved questions, validated assumptions, open questions
- **[Part 1: Original Design](./2026-03-24-ultimate-code-review-part1-design.md)**: Full design document verbatim
- **[Part 2: Codebase, Git History, Framework](./2026-03-24-ultimate-code-review-part2-codebase-git-framework.md)**: Codebase Analyst, Git History Analyzer, Framework Docs Researcher findings
- **[Part 3: Best Practices, Testing, Error Handling](./2026-03-24-ultimate-code-review-part3-practices-testing-errors.md)**: Best Practices Researcher, Test Coverage Analyst, Error Handling Analyst findings
- **[Part 4: Dependencies, Architecture, Edge Cases](./2026-03-24-ultimate-code-review-part4-deps-architecture-edge.md)**: Dependency Analyst, Architecture Boundaries Analyst findings, edge cases, and open question deep-dives

---

## Resolved Questions

| Question | Resolution | Source |
|----------|------------|--------|
| Should there be a `--quick` mode that uses fewer agents for faster/cheaper reviews? | **No.** Recommend against quick mode. It contradicts the "22 agents must run - anything less is a failure" design constraint and dilutes "ultimate" positioning. Industry pattern is dynamic agent deployment based on PR complexity, not static tiers. If cost control is needed, use `effort: medium` instead of reducing agent count. | Best Practices Researcher (Quick Mode specialist) |
| Should the plugin cache results so re-running on the same diff doesn't re-analyze unchanged findings? | **Defer to v2.** Anthropic's official code-review plugin does NOT cache. Cache invalidation is extremely complex (file changes, framework updates, CVE disclosures, agent prompt changes all invalidate). For v1, implement stateless runs. For v2, consider file-level change detection with conservative invalidation (48hr TTL). Prompt caching at the API level provides zero benefit for single-pass parallel agents. | Architecture Boundaries Analyst (Caching specialist) |
| For very large diffs (1000+ files), should agents be assigned subsets of files or should all 22 review everything? | **Domain-scoped context, not file partitioning.** 1000 files at 1000-2500 tokens each = 1M-2.5M tokens, exceeding the 1M context window. "Lost in the middle" research shows 30%+ accuracy degradation in long contexts. Context rot begins at ~65% of max capacity. Solution: Phase 1 team lead builds change manifest; each Phase 2 agent uses Grep/LSP to load only domain-relevant files (security agent loads auth/crypto files, performance agent loads hot paths, etc.). All agents see the manifest but load files selectively. | Best Practices Researcher (Large Diff specialist) |

---

## Executive Summary

Research dispatched 11 parallel agents (8 core + 3 open question specialists) to investigate the Ultimate Code Review Plugin design. Key findings:

1. **Plugin architecture is well-documented and straightforward.** Claude Code plugins use `.claude-plugin/plugin.json` manifests with `commands/` and `agents/` directories. Agent frontmatter supports `model`, `effort`, `tools`, `name`, `description`, and `color` fields. The design's file structure is valid and follows established patterns.

2. **Agent teams are experimental but viable.** Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. No hard limit on team size exists. Each teammate gets an independent 1M context window. Rate limits are account-level. Known limitations: no session resumption, one team per session, no nested teams. The 22-agent design is unprecedented in the ecosystem but not technically prohibited.

3. **The 22-agent design is the key differentiator.** No existing plugin uses more than 8 agents. The largest observed is hyperpowers with ~8 research agents. This plugin's 24 agents (22 specialists + synthesizer + devil's advocate) would be a first. Research confirms non-overlapping boundaries are achievable across all 22 specialists.

4. **Web verification mandate is well-supported.** Existing plugins (silent-failure-hunter, security agents) already include web verification patterns. The design's mandate to include WebSearch/WebFetch on ALL agents with explicit verification instructions is an extension of proven patterns, not an invention.

5. **Large diffs require intelligent context scoping.** "All agents see everything" breaks at ~300+ files due to context window limits and "lost in the middle" degradation. Domain-scoped context loading (each agent loads files relevant to its specialty) is the production-proven approach. The Phase 1 team lead should build a change manifest that agents use to selectively load files.

6. **Caching should be deferred.** No production Claude Code plugin implements result caching. Cache invalidation is too complex for v1. Focus on proving the 22-agent architecture works first.

7. **Cost will be significant but the user accepts this.** Running 22 Opus agents with adaptive thinking and max effort is expensive (~$5-50 per medium PR). Multiple research agents recommend using Sonnet for specialist agents (97-99% as capable at 5x lower cost), but this directly contradicts the design constraint "ALL agents MUST be Opus - no exceptions." The design explicitly accepts high token costs as a feature, not a bug.

8. **Error handling needs graceful degradation.** When agents timeout or WebSearch is unavailable, agents should continue with reduced capability and mark findings as UNVERIFIED. The synthesizer should report agent completion status. Partial results with transparency beat silence.

9. **Testing uses shell scripts with `claude -p` invocations.** No traditional unit testing framework exists for Claude Code plugins. Tests invoke Claude Code directly in headless mode, capture output, and assert patterns. Two-tier strategy: fast tests (~5 min) for prompt compliance, integration tests (~30 min) for full workflow validation.

10. **Critical contradiction noted**: Multiple research agents recommend fewer agents (3-5 is the "sweet spot" per Claude docs) and cheaper models (Sonnet 4.6 for specialists). These recommendations are documented but DO NOT override the design constraints, which explicitly require 22 Opus agents. The user has been informed of the cost implications and accepts them.

---

## Validated Assumptions

*Validated by assumption-checker agent against official Anthropic documentation*

### Validated (10/15)

- Each agent in a team gets independent 1M context window (not shared). Source: [Agent teams docs](https://code.claude.com/docs/en/agent-teams)
- `effort` is a valid frontmatter field for agents (added in Claude Code v2.1.80), with `max` being the highest level (Opus only). Source: [Changelog](https://code.claude.com/docs/en/changelog), [Sub-agents docs](https://code.claude.com/docs/en/sub-agents)
- WebSearch and WebFetch are available at all plan tiers. Source: [Web search docs](https://support.claude.com/en/articles/10684626-enabling-and-using-web-search)
- Agents can communicate via SendMessage peer-to-peer (not just to team lead). Source: [Agent teams docs](https://code.claude.com/docs/en/agent-teams)
- Plugin structure (.claude-plugin/plugin.json, commands/, agents/) is correct. Source: [Plugins docs](https://code.claude.com/docs/en/plugins)
- No nested teams allowed (teammates cannot spawn teammates). Source: [Agent teams docs](https://code.claude.com/docs/en/agent-teams)
- Rate limits are account-level across all teammates. Source: [Costs docs](https://code.claude.com/docs/en/costs)
- Plugin-shipped agents cannot use hooks, mcpServers, or permissionMode. Source: [Sub-agents docs](https://code.claude.com/docs/en/sub-agents)
- `maxTurns` frontmatter field exists and caps agent turns. Source: [Sub-agents docs](https://code.claude.com/docs/en/sub-agents)
- Agent teams require CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1. Source: [Agent teams docs](https://code.claude.com/docs/en/agent-teams)

### Invalid (3/15) - CORRECTIONS NEEDED

- **`model: opus` has a known resolution bug**: There is a known bug (GitHub issue #25588) where the Task tool's `model="opus"` parameter resolves to an older Opus version instead of the latest. However, the user does not require a specific Opus version - `model: opus` in agent frontmatter is the correct approach and will resolve to whatever the latest Opus is. No workaround needed; just use `model: opus`. Source: [GitHub issue #25588](https://github.com/anthropics/claude-code/issues/25588)

- **"Extended thinking" terminology**: Opus uses "adaptive thinking" (not "extended thinking"). Adaptive thinking dynamically decides when and how much to think. No manual configuration needed at max effort, but the correct term is "adaptive thinking." Extended thinking is the older API feature with explicit budget_tokens. Source: [Adaptive thinking docs](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)

- **Opus does NOT require Max/Team/Enterprise plan for 1M context**: INCORRECT in earlier research. Pro plan ($20/month) ALSO includes the full 1M context window for Opus. Source: [1M context GA announcement](https://claude.com/blog/1m-context-ga)

### Unverified (2/15)

- **Agent teams support 22+ members with no hard limit**: Docs say "no hard limit" but recommend 3-5. No official documentation confirms or denies 22-member teams specifically. The user has reported running 22-agent teams successfully, but this is anecdotal. Manual verification recommended.
- **`color` field in agent frontmatter is supported**: Observed in PR Review Toolkit agents but NOT listed in the official supported frontmatter fields table. GitHub issue #21501 requests this feature. Status unclear; may work in practice but is undocumented. Manual testing recommended.

### Additional Findings from Validation

- **"All agents review all files"**: Invalid for large diffs (1000+ files exceed 1M context). Must use domain-scoped loading. (Confirmed by large diff research agent.)
- **"Agent teams are stable and reliable"**: Agent teams are EXPERIMENTAL. Known issues: session resumption, task status lag, slow shutdown. Must handle gracefully.
- **Cost is acceptable**: 22 Opus agents with max effort could cost $5-50+ per review. User accepts this but should be informed per-run. Pro plan ($20/month) is sufficient for 1M context (not just Max/Team/Enterprise).

### Still Unknown

- Exact token cost per agent run with adaptive thinking at max effort (no published benchmarks)
- Whether 22 parallel Opus agents hit account-level rate limits
- Whether inter-agent messaging (SendMessage) works reliably at scale (>10 agents messaging concurrently)

---

## Related Issues

No issue tracker detected for this project. Consider configuring one in CLAUDE.md.

---

## Open Questions

These are NEW questions surfaced by research (distinct from the 3 design questions resolved above):

1. **Rate limiting at scale**: Will 22 parallel Opus agents with max effort hit account-level rate limits? No published data on concurrent agent team token consumption rates. Requires empirical testing.

2. **Inter-agent messaging reliability**: SendMessage between agents is documented but untested at 22-agent scale. Does message delivery remain reliable? Is there queueing? Can agents message peers they weren't introduced to?

3. **Agent timeout strategy**: The design doesn't specify per-agent timeouts. Should each agent get 5 minutes? 15 minutes? Should bug-focused agents (which trace call graphs) get longer than style agents? Research suggests monitoring with 15-minute default timeout.

4. **Report format validation**: Each agent's expected output format is implied but not formally specified. If an agent produces malformed output, does the synthesizer crash? Need format validation in synthesizer.

5. **Color field for agent teams**: The `color` frontmatter field was observed in PR Review Toolkit agents (sub-agents), but it's unclear if it works for agent team members. May need testing.

6. **Cost tracking**: Should the plugin track and report token costs per run? Multiple agents recommended this. Would help users understand the cost/value tradeoff.

7. **Optimal manifest distribution**: Should the team lead send the full manifest to all 22 agents via message, or should agents read it from a shared file? Messages have size limits; files are more reliable for large manifests.

8. **Agent prompt versioning**: If agent prompts change between plugin versions, cached findings (when v2 caching is implemented) would be stale. Need a versioning strategy for agent prompts.

---

## Handoff

The full design document has been preserved in Part 1 of this research.

Research complete and saved to `docs/hyperpowers/research/2026-03-24-ultimate-code-review.md` (plus parts 1-4).

To continue:
/compact ready to plan docs/hyperpowers/research/2026-03-24-ultimate-code-review.md
/hyperpowers:writing-plans docs/hyperpowers/research/2026-03-24-ultimate-code-review.md
