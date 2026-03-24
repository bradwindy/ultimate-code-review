# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
