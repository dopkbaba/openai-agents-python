# Issue Triage Skill

This skill automatically triages new GitHub issues by analyzing their content, applying appropriate labels, assigning priority, and providing an initial response to the issue author.

## What It Does

1. **Analyzes issue content** — Reads the issue title, body, and any attached files or logs
2. **Classifies the issue type** — Bug report, feature request, question, documentation gap, etc.
3. **Applies labels** — Adds relevant labels based on classification (e.g., `bug`, `enhancement`, `question`, `docs`, `good first issue`)
4. **Assigns priority** — Determines priority level (`P0`/`P1`/`P2`/`P3`) based on impact and severity signals
5. **Identifies affected components** — Tags the relevant subsystem (e.g., `tracing`, `tools`, `handoffs`, `streaming`)
6. **Posts an initial response** — Acknowledges the issue, asks clarifying questions if needed, and sets expectations
7. **Detects duplicates** — Searches existing issues for potential duplicates and links them

## Trigger

This skill runs automatically when:
- A new issue is opened in the repository
- An issue is reopened after being closed
- Manually triggered via `@agent triage` comment on an issue

## Labels Applied

### Type Labels
- `bug` — Something is not working as expected
- `enhancement` — New feature or improvement request
- `question` — General usage question
- `docs` — Documentation issue or request
- `performance` — Performance-related concern
- `security` — Security vulnerability or concern

### Priority Labels
- `P0` — Critical: data loss, security vulnerability, complete breakage
- `P1` — High: significant functionality broken, no workaround
- `P2` — Medium: functionality impaired, workaround exists
- `P3` — Low: minor issue, cosmetic, nice-to-have

### Component Labels
- `component: agents` — Core agent functionality
- `component: tools` — Tool definitions and execution
- `component: handoffs` — Agent handoff mechanism
- `component: tracing` — Tracing and observability
- `component: streaming` — Streaming responses
- `component: memory` — Memory and context management
- `component: guardrails` — Input/output guardrails

### Status Labels
- `needs-info` — Requires more information from the reporter
- `needs-reproduction` — Bug needs a reproducible test case
- `duplicate` — Duplicate of an existing issue
- `wont-fix` — Out of scope or intentional behavior

## Agent Behavior

### For Bug Reports
- Check if a stack trace or error message is included; if not, request one
- Ask for the SDK version (`openai-agents` package version)
- Ask for a minimal reproducible example if not provided
- Assess severity based on keywords (crash, data loss, security, etc.)

### For Feature Requests
- Acknowledge the request and thank the contributor
- Ask for use-case context if not provided
- Note if a similar feature already exists or is in progress

### For Questions
- Point to relevant documentation sections
- Suggest related examples in the `examples/` directory
- Encourage moving to GitHub Discussions if it's a general how-to question

## Configuration

The skill uses the agent configuration defined in `agents/openai.yaml`.

Customize triage behavior by editing the prompt or label mappings in the agent config.
