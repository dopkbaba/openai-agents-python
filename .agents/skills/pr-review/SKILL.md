# PR Review Skill

This skill enables automated pull request review with intelligent code analysis, style checking, and constructive feedback generation.

## Overview

The PR Review skill analyzes pull requests by:
- Reviewing code changes for correctness and potential bugs
- Checking adherence to project coding standards
- Identifying security vulnerabilities or anti-patterns
- Suggesting improvements and optimizations
- Summarizing the overall impact of the changes

## Usage

This skill is triggered automatically on new pull requests or can be invoked manually.

### Inputs

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `pr_number` | integer | Yes | The pull request number to review |
| `repo` | string | Yes | Repository in `owner/name` format |
| `focus_areas` | array | No | Specific areas to focus on (e.g., `security`, `performance`, `style`) |
| `severity_threshold` | string | No | Minimum severity to report: `info`, `warning`, `error` (default: `warning`) |

### Outputs

- Inline comments on changed lines with specific feedback
- A summary review comment with overall assessment
- A pass/fail recommendation based on findings

## Configuration

Set the following environment variables:

```bash
GITHUB_TOKEN=<your-github-token>         # Required: GitHub API token with PR write access
OPENAI_API_KEY=<your-openai-api-key>     # Required: OpenAI API key for analysis
REVIEW_STYLE=constructive                # Optional: Review tone (constructive, strict, lenient)
MAX_FILES_PER_REVIEW=50                  # Optional: Limit files reviewed per PR
```

## Review Criteria

### Code Quality
- Logic errors and edge cases
- Proper error handling
- Code duplication (DRY principle)
- Function/method complexity

### Security
- Input validation
- Secrets or credentials in code
- Dependency vulnerabilities
- Common vulnerability patterns (OWASP)

### Performance
- Inefficient algorithms or data structures
- Unnecessary database queries or API calls
- Memory leaks or resource management issues

### Style & Conventions
- Naming conventions
- Documentation and comments
- Import organization
- Consistent formatting

## Example Output

```
## PR Review Summary

**Overall Assessment:** ⚠️ Changes Requested

### Findings
- 🔴 2 errors found
- 🟡 3 warnings found  
- 🔵 5 suggestions

### Critical Issues
1. `src/auth.py:42` — Potential SQL injection vulnerability: use parameterized queries
2. `src/utils.py:18` — Unhandled exception may cause silent failures in production

### Recommendations
Address the critical security issue before merging. The overall structure is solid.
```

## Notes

- Reviews are non-blocking by default; configure branch protection rules to enforce them
- Large PRs (>50 files) may be partially reviewed; consider breaking them into smaller PRs
- The skill respects `.gitignore` and will not review generated or vendored files
