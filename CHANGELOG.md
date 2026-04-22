# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.6.0] - 2026-04-22

### Changed

- Phase 2 simplified to passive waiting — main agent ends turn after spawning 23 agents and takes no action until all return
- Synthesizer and devil's advocate phases unchanged but no longer gated behind monitoring checks

### Removed

- Startup verification polling (Step 6a) — no TaskList() calls after spawn
- Safety-net timeout CronCreate (Step 6b) — no timeout monitoring
- Passive monitoring with progress logging (Step 6c) — no progress tracking
- Pre-synthesis verification gate (Step 6d) — no gate checks
- Agent kill-and-replace logic for failed-to-launch agents
- Non-negotiable rules about slow agents and pre-phase-transition checklists

## [1.5.0] - 2026-04-14

### Changed

- Replaced Phase 2 active polling loop with event-driven notification processing
- Startup verification (Step 6a) now uses short-lived polling (~3 min) only to confirm agents launched
- Completion waiting (Step 6c) is now fully passive — orchestrator goes idle and processes framework notifications
- Reduced timeout recovery to a single 10-minute safety-net cron with one 5-minute extension

### Removed

- Continuous TaskList() polling loop (45+ calls per review)
- Status check messages to agents mid-turn (agents cannot respond mid-turn)
- Web verification compliance reminders (already in agent prompts)
- Multi-stage timeout extension cascades

## [1.3.0] - 2026-03-26

### Added

- Active polling loop in Phase 2 — main agent now calls TaskList() repeatedly until all 23 agents complete or timeout
- Periodic agent monitoring with stall detection and web verification compliance enforcement
- Output destination choice (terminal, project file, ~/Documents, or custom path) via AskUserQuestion before displaying results
- Ticket-scoped manifest files (`ucr-manifest-<ticket>.md`) to isolate concurrent reviews

### Changed

- Output filenames now include ticket/PR/branch identifier (e.g. `code-review-PR-123.md`)
- Stale manifest cleanup at start of each review (own ticket only)

### Fixed

- Main agent no longer proceeds to synthesis before agents have completed

## [1.2.0] - 2026-03-25

### Changed

- Migrated from commands/ to skills/ format per Claude Code conventions
- Added REVIEW.md support for review-specific project guidance

## [1.1.0] - 2026-03-25

### Added

- Scope Relevance Reviewer agent (#23) - detects out-of-scope code changes by comparing changes against PR/MR description and linked tickets

### Changed

- Updated specialist agent count from 22 to 23 across orchestrator, synthesizer, and plugin metadata

## [1.0.0] - 2025-03-25

### Added

- 22 specialist review agents covering bug detection, security, performance, types, context, and quality
- Synthesizer agent for merging and deduplicating findings across all specialists
- Devil's advocate agent for adversarial false-positive filtering
- `/ultimate-code-review` slash command for orchestrating the full review pipeline
- Support for GitHub PRs (`gh`), GitLab MRs (`glab`), and local branch comparisons
- `--post` flag for posting review summaries directly to PRs/MRs
- Web verification mandate requiring all agents to verify technical claims against official sources
- Marketplace support for distribution via `/plugin marketplace add`
