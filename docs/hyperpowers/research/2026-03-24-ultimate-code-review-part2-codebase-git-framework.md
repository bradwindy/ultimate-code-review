# Research Part 2: Codebase Analysis, Git History, Framework Documentation

> Part of: [Ultimate Code Review Research](./2026-03-24-ultimate-code-review.md)

---

## Codebase Analysis

*From: Codebase Analyst Agent*

### Plugin Structure Standards

Claude Code plugins follow a consistent directory structure:
- `.claude-plugin/plugin.json` - Plugin manifest (minimal metadata)
- `commands/` - Slash commands in markdown format
- `agents/` - Autonomous agents in markdown format
- `skills/` - Reusable skills (alternative to commands, more flexible structure)
- `README.md` - Documentation

The `plugin.json` manifest is minimal. Only required fields: `name`, `description`, `author.name`, `author.email`. Optional but recommended: `version`, `homepage`, `repository`, `license`, `keywords`. No configuration of commands/agents in manifest - they're discovered by file structure.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-review/.claude-plugin/plugin.json`

### Naming Conventions

- Plugin names: lowercase, hyphenated (e.g., `code-review`, `pr-review-toolkit`, `feature-dev`)
- Agent names: lowercase, hyphenated, 2-4 words (e.g., `code-reviewer`, `silent-failure-hunter`, `type-design-analyzer`)
- Command names: lowercase, hyphenated (e.g., `review-pr`, `code-review`, `feature-dev`)
- Files use `.md` extension with matching name to the entity

### Agent Frontmatter Specification

Complete supported frontmatter fields for agent markdown files:

| Field | Type | Valid Values | Required | Notes |
|-------|------|-------------|----------|-------|
| `name` | string | kebab-case, no spaces | Yes (agents) | Unique identifier |
| `description` | string | Any text | Yes (agent teams) | Claude uses this to decide when to delegate |
| `model` | string | `opus`, `sonnet`, `haiku`, `inherit`, or full ID like `claude-opus-4-6` | No | Defaults to `inherit` |
| `effort` | string | `low`, `medium`, `high`, `max` (Opus only) | No | Overrides session effort level |
| `maxTurns` | integer | Any positive integer | No | Stops agent after N turns |
| `tools` | CSV string | Tool names | No | Allowlist; inherits all if omitted |
| `disallowedTools` | CSV string | Tool names to deny | No | Applied after tools list |
| `color` | string | `green`, `yellow`, `cyan`, `pink`, `magenta`, `red`, `blue` | No | Visual indicator |
| `skills` | CSV string | Skill names to preload | No | Full skill content injected at startup |
| `memory` | string | `user`, `project`, `local` | No | Persistent directory scope |
| `background` | boolean | `true`/`false` | No | Run concurrently |
| `isolation` | string | `worktree` only | No | Isolate in git worktree |

**Plugin-Only Restrictions**: For plugin-shipped agents, `hooks`, `mcpServers`, and `permissionMode` are NOT supported.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/command-development/references/frontmatter-reference.md`

### Agent Description Format (Pattern to Follow)

Agent descriptions follow a structured pattern used across all official plugins:

```markdown
Use this agent when [triggering conditions].

<example>
Context: [situation description]
user: "[user message]"
assistant: "[response before trigger]"
<commentary>[Why agent should trigger]</commentary>
</example>
```

Multiple `<example>` blocks (2-4) show different triggering scenarios. This format is critical for agent teams where Claude needs to know when to delegate.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/agents/silent-failure-hunter.md`

### Color Coding Convention

Colors observed across official plugins indicate agent purpose:
- `green` - approval/validation role (code-reviewer)
- `yellow` - warning/caution role (silent-failure-hunter)
- `cyan` - analysis role (pr-test-analyzer)
- `pink` - specialized domain role (type-design-analyzer)
- `magenta` - creation role

**Recommendation for Ultimate Code Review**:
- Agents 1-7 (Bug-focused): `red` or `yellow` (danger zone)
- Agents 8-10 (Security): `red` (high priority)
- Agents 11-22 (Context/Quality): `green`, `cyan`, `blue` (informational)
- Agent 23 (Synthesizer): `magenta` (meta/coordination)
- Agent 24 (Devil's Advocate): `yellow` (adversarial challenge)

### Tool Whitelisting Pattern

Official plugins use explicit tool lists, never wildcards. Examples:
- Read-only agents: `tools: Read, Grep, Glob` (no write/bash)
- Analysis agents: `tools: Read, Grep, Glob, WebSearch, WebFetch`
- System agents: `tools: Read, Grep, Glob, Bash` with filters like `Bash(git:*)`

**Critical for Ultimate Code Review**: All agents should have `Read, Grep, Glob, WebSearch, WebFetch` minimum. Some add `Bash` (git-history, cross-PR, test-coverage, migration-risk) and `LSP` (deep-bug-scanner, side-effects, concurrency, data-flow, memory, performance). None should have `Write` or `Edit` since this is a read-only review tool.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/feature-dev/agents/code-explorer.md`

### Web Verification Pattern (Existing)

Official plugins already include web verification patterns. The silent-failure-hunter searches for official documentation before claiming a pattern is dangerous. Security agents use WebSearch to verify CVEs and framework-specific vulnerabilities. This validates the design's web verification mandate as an extension of existing patterns, not an invention.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/pr-review-toolkit/agents/silent-failure-hunter.md`

### Confidence Scoring Pattern (Existing - Not Used in Design)

Anthropic's official code-review plugin uses 0-100 confidence scoring with threshold of 80. Issues below 80 are filtered out. The Ultimate Code Review design deliberately replaces this with the devil's advocate agent approach, which is more thorough but also more expensive.

**Source**: `/Users/bwindybank/.claude/plugins/marketplaces/claude-plugins-official/plugins/code-review/commands/code-review.md:20-26`

### Similar Implementations Found

- **Silent Failure Hunter**: Identical methodology to Agent #4. Battle-tested severity classification (CRITICAL, HIGH, MEDIUM). Source: `pr-review-toolkit/agents/silent-failure-hunter.md`
- **Type Design Analyzer**: Exact 4-dimension 1-10 rating used by Agent #9. Source: `pr-review-toolkit/agents/type-design-analyzer.md`
- **Code Comment Analyzer**: Agent #15 reuses this methodology. Source: `pr-review-toolkit/agents/comment-analyzer.md`
- **Code Simplifier**: Agent #17 reuses this methodology. Source: `pr-review-toolkit/agents/code-simplifier.md`
- **Feature-Dev Code Explorer**: Deep call-graph tracing similar to Agent #1. Source: `feature-dev/agents/code-explorer.md`

### Key Unknown: Scale

No official plugin uses more than 8 agents. The largest observed is hyperpowers with ~8 parallel research agents. The Ultimate Code Review design's 24 agents (22 specialists + synthesizer + devil's advocate) is unprecedented. No pattern exists for inter-agent coordination at this scale.

---

## Git History Insights

*From: Git History Analyzer Agent*

### Evolution of Code Review Plugins

The Anthropic Claude Code plugin ecosystem evolved with clear patterns:

1. **Multi-Agent Review Architecture** (commit 2cd88e7, Feb 6 2026): The code-review plugin introduced a 5-agent parallel system. Architecture separates concerns into specialized agents rather than a single monolithic reviewer.

2. **Confidence Scoring Pattern**: A confidence threshold of 80/100 was established as the filtering mechanism. This evolved from recognizing that multiple independent agents produce both signal and noise.

3. **Specialized Agent Teams**: The ecosystem converged on bundles of focused agents:
   - PR Review Toolkit: 6 specialized agents
   - Feature Development: Sequential teams (2-3 explorers, then 2-3 architects, then 3 reviewers)

4. **Idempotency and Early Exit**: Early eligibility checks prevent duplicate reviews and wasted work on closed PRs, drafts, or already-reviewed PRs.

### Key Historical Decisions

- **Confidence Thresholds** (code-review.md:26): "Filter out any issues with a score less than 80" - Precision matters more than recall for automated feedback
- **CLAUDE.md as Central Source of Truth** (code-review.md:15): Two redundant agents specifically audit CLAUDE.md compliance, reflecting that project-specific conventions are the most actionable signal
- **Context Isolation Between Phases** (feature-dev): Exploration, Questions, Architecture, Implementation, Review phases separated to prevent context contamination
- **Early Exit on Ineligible PRs**: Skip closed/draft PRs to prevent wasting computation

### Progressive Specialization Pattern

The ecosystem started with general code review and evolved toward specialized agents. Different agents use different confidence models:
- code-reviewer: 0-100 with 80 threshold
- silent-failure-hunter: CRITICAL/HIGH/MEDIUM severity
- type-design-analyzer: 1-10 scale for 4 dimensions
- test-analyzer: 1-10 for gaps

This pattern validates the design's approach of having 22 specialized agents with a unified severity scale (CRITICAL/HIGH/MEDIUM/LOW/INFO) normalized by the synthesizer.

### Dynamic Agent Team Sizing (Observed)

Official guidance suggests scaling team size to project complexity:
- 2 agents: Simple projects
- 3 agents: Medium projects
- 4 agents: Standard team size (confirmed baseline)
- 6 agents: Large projects
- 8 agents: Complex multi-component projects

The design's 22 agents exceeds all observed precedents but is not technically limited.

### False Positive Reduction Over Time

The code-review plugin developed an explicit exclusion list that grew as the plugin was refined:
- Pre-existing issues (not introduced by this PR)
- Known false positive patterns
- Issues catchable by linters
- General quality unless explicitly in CLAUDE.md
- Lint ignore comments

This validates the devil's advocate approach but also suggests that the plugin may need its own exclusion list over time.

### Contributors with Relevant Expertise

- **Boris Cherny** (boris@anthropic.com): Code review plugin architecture, confidence-based filtering
- **Daisy** (daisy@anthropic.com): PR Review Toolkit, specialized agent design patterns

---

## Framework & Documentation

*From: Framework Docs Researcher Agent*

### Plugin Manifest Schema

Source: [Plugins reference - Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)

```json
{
  "name": "ultimate-code-review",
  "version": "1.0.0",
  "description": "Comprehensive code review plugin with 22+ specialist agents",
  "author": { "name": "Brad Windy" },
  "commands": ["./commands/"],
  "agents": "./agents/"
}
```

Components must be at plugin root, NOT inside `.claude-plugin/`. Only `plugin.json` belongs in `.claude-plugin/`.

### Agent Team API

Source: [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)

**Requirements**:
- Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json or environment
- Architecture: Team lead + independent teammates with separate context windows
- Communication: Direct peer-to-peer messaging via SendMessage + shared task list
- Each teammate gets isolated 1M token context window (NOT shared)

**Key APIs**:
- Task list coordination: Teammates claim tasks from shared list
- Direct messaging: `SendMessage(to: <agent-name>, message: <text>)`
- Task dependencies: System manages blocking automatically
- Broadcast: Send to all teammates simultaneously (expensive)

**Team Size**:
- No hard limit on teammate count
- Practical recommendation: 3-5 for optimal coordination
- Token costs scale linearly
- Rate limits: Account-level, applies across all teammates

**Known Limitations (experimental)**:
- No session resumption with in-process teammates
- Task status can lag
- Shutdown can be slow
- One team per session
- No nested teams (teammates cannot spawn teammates)

### Model Configuration

Source: [Model configuration - Claude Code Docs](https://code.claude.com/docs/en/model-config)

Valid model specifications in frontmatter:
- `model: opus` - Latest Opus (currently 4.6)
- `model: sonnet` - Latest Sonnet (currently 4.6)
- `model: haiku` - Latest Haiku (currently 4.5)
- `model: opus[1m]` - Opus with explicit 1M context
- `model: claude-opus-4-6` - Specific version
- `model: inherit` - Use session's model

**Effort Levels** (Opus and Sonnet only):
- `low`: Most efficient; skips thinking on simple problems
- `medium`: Balanced approach
- `high`: Default; almost always thinks deeply
- `max`: Absolute maximum capability; Opus only; no persistence across sessions

### Extended Thinking

Source: [Building with extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)

For Claude Opus:
- Uses **adaptive thinking** (`thinking: {type: "adaptive"}`) by default
- Manual thinking budget (`{type: "enabled", budget_tokens: N}`) is deprecated
- At `high` effort, Claude almost always thinks; at `max` effort, absolute maximum capability (Opus only)
- Interleaved thinking enabled by default (reasoning between tool calls)
- No explicit configuration needed in Claude Code - just set `effort: max` for maximum capability

### Skill/Command Definition Format

Source: [Extend Claude with skills](https://code.claude.com/docs/en/skills)

```yaml
---
name: ultimate-code-review
description: Execute comprehensive code review with specialist agents
disable-model-invocation: true
user-invocable: true
model: opus
effort: max
---

# Execution Instructions
[Markdown content with instructions Claude follows]
```

Key fields:
- `disable-model-invocation: true` - Only user can invoke (prevents auto-triggering)
- `user-invocable: true` - Appears in `/` autocomplete
- `argument-hint` - Shown in autocomplete (e.g., `[PR URL or branch..branch]`)

### Plugin Distribution

Source: [Create and distribute a plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces)

Plugin sources in marketplace.json:
- Relative path: `"source": "./plugins/my-plugin"` (local, requires git)
- GitHub: `"source": {"source": "github", "repo": "owner/repo", "ref": "v1.0", "sha": "..."}`
- Git URL: `"source": {"source": "url", "url": "https://gitlab.com/org/repo.git"}`
- npm: `"source": {"source": "npm", "package": "@org/plugin", "version": "^1.0.0"}`

Cache location: `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`

### Context Window Specifications

Source: [Context windows - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/context-windows)

- Opus with 1M context: Available on Pro/Max/Team/Enterprise plans
- Each teammate in an agent team gets its own isolated 1M token window
- Default context: 200K tokens (upgraded to 1M on Max/Team/Enterprise)
- Practical usable context: ~65% of max before quality degradation (per "context rot" research)

### Configuration Requirements for Ultimate Code Review

1. **Enable agent teams** in settings.json or environment:
   ```json
   "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" }
   ```

2. **Plugin manifest** (`.claude-plugin/plugin.json`):
   ```json
   {
     "name": "ultimate-code-review",
     "version": "1.0.0",
     "description": "22+ specialist agents for deep code review",
     "agents": "./agents/",
     "commands": "./commands/"
   }
   ```

3. **All agent frontmatter**:
   ```yaml
   model: opus
   effort: max
   tools: Read, Grep, Glob, WebSearch, WebFetch
   ```

### Documentation Gaps

- Exact SendMessage API parameter names and response format not fully detailed
- Task list file format (`.claude/teams/{team-name}/`) not fully documented
- Whether non-lead agents can message each other directly (docs suggest yes but not specified)
- Broadcast semantics (fire-and-forget vs wait for replies)
- Rate limit behavior when teammate hits account-level limit
- Extended thinking token cost multiplier not published

### Sources

1. [Plugins reference](https://code.claude.com/docs/en/plugins-reference)
2. [Agent teams](https://code.claude.com/docs/en/agent-teams)
3. [Skills](https://code.claude.com/docs/en/skills)
4. [Sub-agents](https://code.claude.com/docs/en/sub-agents)
5. [Plugin marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
6. [Model configuration](https://code.claude.com/docs/en/model-config)
7. [Extended thinking](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)
8. [Effort](https://platform.claude.com/docs/en/build-with-claude/effort)
9. [Context windows](https://platform.claude.com/docs/en/build-with-claude/context-windows)
