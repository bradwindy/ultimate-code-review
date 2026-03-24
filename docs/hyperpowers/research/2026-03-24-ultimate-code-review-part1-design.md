# Research Part 1: Original Design Document

> This is the verbatim design document consumed by research. Included for context preservation across phases.

---

# Ultimate Code Review Plugin - Design Document

## Problem Statement

Existing Claude Code review plugins are too shallow. Anthropic's official plugin does a "shallow scan for obvious bugs" with Sonnet agents, and most community plugins follow the same pattern - quick scans with low-cost models. None of them trace call graphs, verify claims against external sources, or push beyond surface-level analysis. The result is reviews that catch formatting issues and obvious mistakes but miss the deep, subtle bugs that actually cause production incidents.

Additionally, existing review agents rely too heavily on internal model knowledge. They make technical claims without verification, leading to false positives and missed issues when the model's training data is outdated or incorrect.

## Success Criteria

1. A single `/ultimate-code-review` command spawns an agent team of 22+ Opus agents that collectively examine every meaningful dimension of code quality
2. ALL agents verify technical claims against the web using WebSearch/WebFetch - no reliance on internal knowledge alone
3. False positives are aggressively filtered by a dedicated devil's advocate agent that verifies findings against multiple web sources
4. Output is organized by file and severity, actionable, and includes concrete fix suggestions
5. The plugin works with GitHub PRs, GitLab MRs, and local branch comparisons
6. Terminal output is always produced; PR/MR commenting is opt-in via `--post`
7. All agents are Opus with adaptive thinking and max effort level - no exceptions
8. 22 specialist agents must run - anything less is a failure

## Constraints

- **Model**: ALL agents MUST be Opus with adaptive thinking and effort level max. No Haiku, no Sonnet, no exceptions.
- **Web verification**: ALL agents MUST have WebSearch and WebFetch tools. Every agent's prompt includes explicit instruction to verify technical claims against the web using multiple sources rather than relying on internal knowledge.
- **Architecture**: Agent team (not sub-agents). 22 specialist agents that can communicate with each other via direct messaging.
- **No threshold filtering**: Agents report ALL findings. The devil's advocate agent handles false positive filtering.
- **Standalone**: No dependency on hyperpowers or other plugins.
- **Language-agnostic**: Agents adapt to whatever language/framework they encounter.
- **Read-only**: This is a review tool - no implementation code changes.
- **Platform support**: GitHub (gh CLI), GitLab (glab CLI), and local git diff.

## Out of Scope

- Automated code fixes / auto-remediation
- CI/CD integration (GitHub Actions, GitLab CI) - this is a local CLI plugin
- Language-specific specialist agents - all agents are universal
- Integration with external linters/type checkers - those run separately in CI

## Approach

### Three-Phase Architecture

#### Phase 1: Context Gathering (Sequential)

A single Opus agent (the team lead or first agent) collects the diff, identifies changed files, reads project guidelines, and creates a manifest that is distributed to all specialist agents.

**Agent: Diff Context Gatherer (Team Lead)**

Responsibilities:
1. Determine the diff source:
   - If given a PR/MR number: fetch via `gh pr diff` or `glab mr diff`
   - If given two branches: `git diff branch1...branch2`
   - Auto-detect platform from git remotes
2. Build a change manifest containing:
   - List of all changed files with change type (added/modified/deleted)
   - The full diff content
   - Full content of every changed file (not just diff hunks)
   - Full content of CLAUDE.md files (root + any in affected directories)
   - Project structure overview (key directories, config files)
3. For each changed file, collect:
   - Direct callers of changed functions (via grep/LSP)
   - Direct callees of changed functions
   - Related test files
4. Distribute the manifest to all 22 specialist agents via the task list and direct messages.
5. After all specialists complete, hand off to the synthesizer agent, then the devil's advocate.

Tools: Read, Grep, Glob, Bash, LSP, WebSearch, WebFetch

#### Phase 2: Deep Analysis (Parallel - 22 Agent Team Members)

All 22 specialist agents run simultaneously as members of an agent team. Each is Opus, adaptive thinking, max effort, with WebSearch and WebFetch. Each has clearly defined, non-overlapping boundaries.

##### Bug-Focused Agents (1-7)

**1. Deep Bug Scanner**
- Replaces Anthropic's "shallow scan for obvious bugs"
- Traces the FULL call graph of every changed function through all layers
- Looks for: logic errors, off-by-one errors, null/undefined handling, incorrect conditional logic, missing return statements, incorrect type coercions, boundary condition violations
- Follows function calls through all layers to find bugs that only manifest when the full execution path is considered
- Searches the web to verify whether suspected bug patterns are actually bugs in the specific framework/language version
- Tools: Read, Grep, Glob, Bash, LSP, WebSearch, WebFetch

**2. Side Effects Analyzer**
- Traces every state mutation caused by changed code
- Maps: global variable modifications, database writes, file system operations, external API calls, event emissions, cache invalidations, session/cookie modifications
- Maps the "blast radius" of each change
- Flags unintended side effects where a seemingly local change has far-reaching consequences
- Tools: Read, Grep, Glob, LSP, WebSearch, WebFetch

**3. Concurrency & Race Condition Reviewer**
- Dedicated to parallelism bugs that other agents miss
- Analyzes: shared mutable state access without synchronization, async/await correctness (missing awaits, promise handling), deadlock potential, atomicity violations, thread safety of data structures, TOCTOU (time-of-check-time-of-use) vulnerabilities
- Searches the web for known concurrency pitfalls in the specific framework being used
- Tools: Read, Grep, Glob, LSP, WebSearch, WebFetch

**4. Silent Failure Hunter**
- Based on Anthropic's PR Review Toolkit agent (one of the strongest existing agents)
- Audits every error handling path: empty catch blocks, swallowed errors, inappropriate fallbacks, missing logging, broad exception catching, retry exhaustion without notification
- Severity levels: CRITICAL, HIGH, MEDIUM
- Checks every catch block for what unexpected errors could be hidden
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**5. Data Flow Analyzer**
- Traces data from input to storage/output
- Validates transformations are correct and complete
- Checks for: data loss during transformations, PII leaking into logs/error messages, missing sanitization at boundaries, encoding/decoding errors, serialization roundtrip fidelity
- Tools: Read, Grep, Glob, LSP, WebSearch, WebFetch

**6. Memory & Resource Analyzer**
- Dedicated to memory-related issues distinct from general bugs
- Analyzes: memory leaks (unreleased allocations, unclosed streams/connections/handles), retain cycles (strong reference cycles in Swift/ObjC, circular references preventing GC in JS/Python), unbounded growth (arrays/maps that grow without limits, event listener accumulation), resource exhaustion (file descriptor limits, connection pool depletion)
- For managed languages: GC-defeating patterns
- For unmanaged languages: missing frees and double-frees
- Tools: Read, Grep, Glob, LSP, WebSearch, WebFetch

**7. Performance Analyzer**
- Platform-aware performance review
- First step: identify the framework stack and platform (e.g., Next.js on Vercel, Django on AWS, SwiftUI on iOS) by examining config files and imports
- Second step: search the web for platform-specific performance best practices, known performance pitfalls, and current recommendations for that stack
- Then analyzes: N+1 queries, blocking operations in async contexts, missing pagination, algorithmic complexity issues, unnecessary re-renders, slow queries, missing indexes, caching opportunities, bundle size impact
- Every finding grounded in platform-specific context from web research
- Tools: Read, Grep, Glob, LSP, WebSearch, WebFetch

##### Security & Type Agents (8-10)

**8. Security Auditor**
- Enhanced version covering OWASP Top 10 and beyond
- Covers: injection vulnerabilities (SQL, XSS, command, path traversal, SSRF), authentication/authorization gaps (missing auth checks, IDOR, broken access control, JWT issues), secrets exposure (hardcoded keys, secrets in logs, credentials in client-side code), cryptography (weak algorithms, insecure randomness, missing encryption), supply chain risks
- Uses WebSearch to look up known CVEs for libraries/versions found in changed code
- Verifies whether suspected vulnerability patterns are actually exploitable in the specific framework version
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**9. Type Design Reviewer**
- Based on Anthropic's PR Review Toolkit type-design-analyzer
- Evaluates type designs on four dimensions (each rated 1-10): encapsulation, invariant expression, invariant usefulness, invariant enforcement
- Flags: anemic domain models, exposed mutable internals, invariants enforced only through documentation, types with too many responsibilities, missing constructor validation
- Checks whether "illegal states are representable" - the gold standard for type design
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**10. API Contract Reviewer**
- Focused on interface boundaries
- Checks: breaking changes to public APIs, backwards compatibility, schema validation (REST/GraphQL/gRPC), documentation accuracy for endpoints, request/response type alignment, error response consistency, versioning correctness
- Uses web search to verify API design claims against framework documentation
- Tools: Read, Grep, Glob, WebSearch, WebFetch

##### Context & Quality Agents (11-22)

**11. Git Blame & Commit History Analyzer**
- Focused exclusively on historical code context via git blame
- For each changed line: examines git blame to understand who wrote it and when, reads commit messages for documented rationale, identifies patterns of repeated changes to the same code (churn indicating instability)
- Flags changes that contradict intent documented in prior commit messages
- Tools: Read, Grep, Glob, Bash (git commands), WebSearch, WebFetch

**12. Cross-PR/MR Learning Agent**
- Separate from git history - focused on PR/MR review comments
- Fetches previous PRs/MRs that touched the same files using `gh pr list` or `glab mr list`
- Reads review comments from those PRs/MRs
- Checks whether previous reviewer feedback applies to the current changes
- Surfaces recurring review themes for these files
- Tools: Read, Grep, Glob, Bash (gh/glab commands), WebSearch, WebFetch

**13. Guidelines Compliance Reviewer**
- Reads all CLAUDE.md files (root + directory-level), .editorconfig, linting configs, and project-specific coding standards
- Verifies every changed line against those explicit standards
- ONLY flags violations that are explicitly stated in project configuration - never invents rules
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**14. Code Comment Compliance Checker**
- Distinct from guidelines compliance
- Scans inline code comments in modified files for directives like "do not modify without updating X", "this must stay in sync with Y", "WARNING: changing this requires Z"
- Verifies whether the change honored those directives
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**15. Comment & Documentation Quality Reviewer**
- Based on Anthropic's PR Review Toolkit comment-analyzer
- Verifies factual accuracy of all code comments against actual implementation
- Checks: function signatures match documented params, described behavior matches code logic, referenced types/functions exist, edge cases mentioned are handled
- Flags misleading comments, stale TODOs, redundant "what" comments that should be "why" comments
- Identifies places where complex logic lacks explanation
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**16. Dependency & Import Analyzer**
- Reviews the dependency/import graph of changed code
- Checks: unused imports, circular dependencies, importing from internal/private modules, version constraint issues in package manifests, license compatibility of new dependencies
- Uses web search to check for known issues, deprecations, or security advisories with dependencies
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**17. Code Simplification Reviewer**
- Based on Anthropic's PR Review Toolkit code-simplifier
- Identifies unnecessary complexity: over-engineering, premature abstractions, dead code, redundant conditionals, overly defensive checks that can never fire, code that duplicates existing utilities
- Suggests concrete simplifications while preserving functionality
- Focused on reducing maintenance burden
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**18. Style Consistency Reviewer**
- Enhanced from hyperpowers' style-reviewer
- Compares changed code against existing project patterns (not generic style guides)
- Checks: naming conventions match project style, file organization follows project structure, import ordering is consistent, error handling patterns match existing code, formatting matches project norms
- Always references the existing code it's comparing against
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**19. Test Coverage Analyzer**
- Merged from hyperpowers' test-reviewer and Anthropic's pr-test-analyzer
- Maps every changed code path to its test coverage
- Identifies: untested error handling paths, missing edge case coverage, boundary conditions without tests
- Rates each gap 1-10 for criticality
- Reviews test quality: assertions that test behavior not implementation, test independence, determinism, DAMP naming
- Identifies tests too tightly coupled to implementation
- Tools: Read, Grep, Glob, Bash, WebSearch, WebFetch

**20. Architecture & Module Boundary Reviewer**
- Checks whether changes respect the existing architecture
- Looks for: layer violations (e.g., UI code calling database directly), inappropriate coupling between modules, circular module dependencies, separation of concerns violations, code placed in the wrong architectural layer
- Maps the module structure first, then evaluates changes against it
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**21. Logging & Observability Reviewer**
- Distinct from silent failure hunter (which checks errors aren't swallowed)
- Checks that code is properly instrumented for production: are important operations logged at appropriate levels? Is structured logging used? Are metrics/telemetry emitted for key operations? Are correlation IDs propagated? Would this code be debuggable in production?
- Tools: Read, Grep, Glob, WebSearch, WebFetch

**22. Migration & Deployment Risk Reviewer**
- Looks for changes that could cause deployment issues
- Checks: database migrations that could fail or cause downtime, config changes requiring environment variable updates, feature flags that need setting, backwards-incompatible changes requiring coordinated deployment, schema changes that need migration scripts
- Tools: Read, Grep, Glob, Bash, WebSearch, WebFetch

#### Phase 3: Synthesis & Adversarial Verification (Sequential)

**23. Synthesizer Agent**
Receives all 22 specialist reports. Responsibilities:
- **Deduplication**: Merge findings flagged by multiple agents from different angles into single findings with cross-references
- **Conflict resolution**: If agents disagree, flag the conflict explicitly rather than hiding it
- **Severity normalization**: Normalize to unified scale: CRITICAL / HIGH / MEDIUM / LOW / INFO
- **Organization**: Group findings by file, then by severity within each file. Each finding includes: description, severity, affected files/lines, which specialist agent(s) found it, concrete fix suggestion
- **Executive summary**: Total findings by severity, key risk areas, overall assessment (merge-ready / needs-work / high-risk)
- Tools: Read, WebSearch, WebFetch

**24. Devil's Advocate Agent**
The critical skepticism layer. Receives the synthesizer's report and adversarially challenges every single finding:
- For each finding: "Could this be a false positive? Is this actually a bug or intentional? Is the severity overstated?"
- **Web verification**: For any finding making a technical claim (e.g., "this API is deprecated", "this pattern causes memory leaks in React 19"), searches the web to verify against official documentation and authoritative sources. Multiple sources required.
- Checks whether the framework version in use actually has the claimed vulnerability or behavior
- Produces final report where each finding has a devil's advocate assessment: CONFIRMED (verified real), PLAUSIBLE (likely real but couldn't fully verify), QUESTIONABLE (might be false positive, needs human judgment), or REJECTED (verified false positive - removed from report)
- Tools: Read, Grep, Glob, WebSearch, WebFetch

### Plugin Structure

```
ultimate-code-review/
  .claude-plugin/
    plugin.json                    # Plugin manifest
  commands/
    ultimate-code-review.md                      # Main /ultimate-code-review command (user-invocable)
  agents/
    # Phase 2: Bug-focused (1-7)
    deep-bug-scanner.md
    side-effects-analyzer.md
    concurrency-reviewer.md
    silent-failure-hunter.md
    data-flow-analyzer.md
    memory-resource-analyzer.md
    performance-analyzer.md
    # Phase 2: Security & Types (8-10)
    security-auditor.md
    type-design-reviewer.md
    api-contract-reviewer.md
    # Phase 2: Context & Quality (11-22)
    git-history-analyzer.md
    cross-pr-learning-agent.md
    guidelines-compliance.md
    comment-compliance-checker.md
    comment-quality-reviewer.md
    dependency-import-analyzer.md
    code-simplification.md
    style-consistency.md
    test-coverage-analyzer.md
    architecture-boundary.md
    logging-observability.md
    migration-deployment-risk.md
    # Phase 3: Synthesis
    synthesizer.md
    devils-advocate.md
```

### Invocation

- `/ultimate-code-review` - reviews current branch against its upstream (main/develop)
- `/ultimate-code-review https://github.com/org/repo/pull/123` - reviews a specific PR
- `/ultimate-code-review https://gitlab.com/org/repo/-/merge_requests/456` - reviews a specific MR
- `/ultimate-code-review feature..main` - reviews a local branch comparison
- `/ultimate-code-review --post` - also posts summary to the PR/MR as a comment

### Agent Configuration

All agents share these frontmatter settings:
```yaml
model: opus
effort: max
```

All agents have these tools at minimum:
```yaml
tools: Read, Grep, Glob, WebSearch, WebFetch
```

Some agents additionally have: Bash, LSP (as specified per-agent above).

### Inter-Agent Communication

Because this is an agent team (not sub-agents), agents can communicate directly:
- Agents can alert other agents about findings that cross boundaries (e.g., security auditor alerts data flow analyzer about suspicious input paths)
- The team lead (context gatherer) coordinates task assignment and monitors progress
- All agents share findings via the team's task list

### Web Verification Mandate

Every agent prompt includes this instruction:

> You MUST verify all technical claims against the web using WebSearch and WebFetch before reporting them. Never rely on internal knowledge alone. When making a claim about a framework, library, API, or language behavior, search for the official documentation and at least one additional authoritative source. If you cannot verify a claim, mark it as UNVERIFIED in your report.

## Open Questions

1. Should there be a `--quick` mode that uses fewer agents for faster/cheaper reviews?
2. Should the plugin cache results so re-running on the same diff doesn't re-analyze unchanged findings?
3. For very large diffs (1000+ files), should agents be assigned subsets of files or should all 22 review everything?

## Sources & Inspirations

### Anthropic Official
- [anthropics/claude-code](https://github.com/anthropics/claude-code) - Official code-review plugin (5 Sonnet agents, confidence scoring)
- [anthropics/claude-code PR Review Toolkit](https://github.com/anthropics/claude-code) - 6 specialized agents (silent-failure-hunter, type-design-analyzer, comment-analyzer, pr-test-analyzer, code-reviewer, code-simplifier)
- [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) - Security-focused review action
- [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) - Official plugin marketplace

### Hyperpowers
- [bradwindy/hyperpowers](https://github.com/bradwindy/hyperpowers) - 4 specialized review agents (security, performance, style, test) + main code reviewer

### Community
- [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) (~101k stars) - 12 agents, domain-specific reviewers
- [ruvnet/ruflo](https://github.com/ruvnet/ruflo) (~23.9k stars) - 64 agents, swarm orchestration, code-review-swarm pattern
- [ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase) (~5.6k stars) - Code reviewer agent with GitHub Actions
- [hamelsmu/claude-review-loop](https://github.com/hamelsmu/claude-review-loop) - Cross-model review (Codex second opinion)
- [praneybehl/code-review-mcp](https://github.com/praneybehl/code-review-mcp) - MCP-based multi-LLM review server
