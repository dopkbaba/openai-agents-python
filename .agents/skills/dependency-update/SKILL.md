# Dependency Update Skill

This skill automates the process of checking for outdated dependencies, evaluating upgrade safety, and generating pull requests with dependency updates.

## Overview

The dependency update skill performs the following tasks:
1. Scans `pyproject.toml`, `requirements*.txt`, and other dependency manifests
2. Checks for available updates using PyPI and other registries
3. Evaluates changelog/release notes for breaking changes
4. Groups updates by severity (patch, minor, major)
5. Runs the test suite against proposed updates
6. Generates a structured PR with update details

## Usage

This skill is triggered automatically on a schedule or manually via workflow dispatch.

### Inputs

| Parameter | Description | Default |
|-----------|-------------|----------|
| `update_type` | Type of updates to apply: `patch`, `minor`, `major`, `all` | `minor` |
| `dry_run` | If true, only report updates without applying them | `false` |
| `group_updates` | Group all updates into a single PR | `true` |
| `exclude_packages` | Comma-separated list of packages to skip | `""` |

### Outputs

- A summary report of available updates
- One or more pull requests with dependency bumps
- Test results for each update batch

## Configuration

Place a `.agents/skills/dependency-update/config.yaml` file in your repo to customize behavior:

```yaml
update_type: minor
dry_run: false
group_updates: true
exclude_packages:
  - some-pinned-package
auto_merge:
  patch: true
  minor: false
  major: false
```

## How It Works

### Step 1: Discovery
The skill scans the repository for all dependency files and builds a unified dependency graph.

### Step 2: Version Resolution
For each dependency, the skill queries PyPI (or the configured registry) to find the latest compatible version respecting existing constraints.

### Step 3: Safety Analysis
The skill fetches changelogs and release notes, using an LLM to summarize breaking changes and migration steps.

### Step 4: Testing
Proposed updates are applied in a temporary environment and the test suite is executed. Only passing updates proceed.

### Step 5: PR Generation
A pull request is created with:
- A structured table of all updates
- Links to changelogs
- Test results
- Migration notes for any breaking changes

## Notes

- Major version updates always require manual review and will never be auto-merged.
- The skill respects version pins (e.g., `==`, `~=`) and will not override them without explicit configuration.
- If tests fail for a batch, the skill attempts to bisect and identify the offending package.
