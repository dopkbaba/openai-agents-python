#!/usr/bin/env bash
# Dependency Update Skill Script
# Checks for outdated dependencies and creates a PR with updates

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
BRANCH_PREFIX="deps/auto-update"
DATE_STAMP="$(date +%Y%m%d)"
UPDATE_BRANCH="${BRANCH_PREFIX}-${DATE_STAMP}"

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Prerequisites check
# ---------------------------------------------------------------------------
check_prerequisites() {
    local missing=0
    for cmd in git python3 pip gh; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            missing=1
        fi
    done
    [[ $missing -eq 0 ]] || { log_error "Install missing prerequisites and retry."; exit 1; }
    log_ok "All prerequisites satisfied."
}

# ---------------------------------------------------------------------------
# Fetch outdated packages via pip
# ---------------------------------------------------------------------------
get_outdated_packages() {
    log_info "Checking for outdated packages..."
    # Returns JSON: [{"name": ..., "version": ..., "latest_version": ...}, ...]
    python3 -m pip list --outdated --format=json 2>/dev/null
}

# ---------------------------------------------------------------------------
# Update pyproject.toml / requirements files
# ---------------------------------------------------------------------------
apply_updates() {
    local outdated_json="$1"

    if [[ "$outdated_json" == "[]" ]]; then
        log_ok "All dependencies are up to date. Nothing to do."
        exit 0
    fi

    log_info "Applying dependency updates..."

    # Use pip-tools or direct pip install to upgrade each package
    echo "$outdated_json" | python3 - <<'PYEOF'
import json, subprocess, sys

data = json.load(sys.stdin)
for pkg in data:
    name = pkg["name"]
    latest = pkg["latest_version"]
    print(f"  Upgrading {name} -> {latest}")
    subprocess.run(
        ["pip", "install", "--quiet", "--upgrade", f"{name}=={latest}"],
        check=True,
    )
PYEOF

    # Regenerate lock / requirements files if they exist
    if [[ -f "${REPO_ROOT}/requirements.txt" ]]; then
        log_info "Regenerating requirements.txt..."
        pip freeze > "${REPO_ROOT}/requirements.txt"
    fi

    if command -v pip-compile &>/dev/null && [[ -f "${REPO_ROOT}/requirements.in" ]]; then
        log_info "Recompiling requirements via pip-compile..."
        pip-compile --quiet "${REPO_ROOT}/requirements.in" -o "${REPO_ROOT}/requirements.txt"
    fi

    log_ok "Updates applied."
}

# ---------------------------------------------------------------------------
# Build a human-readable summary for the PR body
# ---------------------------------------------------------------------------
build_pr_body() {
    local outdated_json="$1"
    echo "## Automated Dependency Update"
    echo ""
    echo "This PR was generated automatically by the **dependency-update** skill."
    echo ""
    echo "### Updated packages"
    echo ""
    echo "| Package | Old Version | New Version |"
    echo "|---------|-------------|-------------|"
    echo "$outdated_json" | python3 -c "
import json, sys
for p in json.load(sys.stdin):
    print(f'| {p[\"name\"]} | {p[\"version\"]} | {p[\"latest_version\"]} |')
"
    echo ""
    echo "### Checklist"
    echo "- [ ] CI passes"
    echo "- [ ] Changelog updated (if required)"
    echo "- [ ] Breaking changes reviewed"
}

# ---------------------------------------------------------------------------
# Create branch, commit, and open PR
# ---------------------------------------------------------------------------
create_pr() {
    local outdated_json="$1"

    cd "${REPO_ROOT}"

    # Ensure we start from a clean main/master
    local base_branch
    base_branch="$(git symbolic-ref --short HEAD)"

    log_info "Creating update branch: ${UPDATE_BRANCH}"
    git checkout -b "${UPDATE_BRANCH}"

    git add -A
    if git diff --cached --quiet; then
        log_warn "No file changes detected after update — skipping PR creation."
        git checkout "${base_branch}"
        git branch -D "${UPDATE_BRANCH}"
        exit 0
    fi

    git commit -m "chore(deps): automated dependency update ${DATE_STAMP}"
    git push origin "${UPDATE_BRANCH}"

    local pr_body
    pr_body="$(build_pr_body "$outdated_json")"

    gh pr create \
        --title "chore(deps): automated dependency update ${DATE_STAMP}" \
        --body "${pr_body}" \
        --base "${base_branch}" \
        --head "${UPDATE_BRANCH}" \
        --label "dependencies"

    log_ok "Pull request created successfully."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    log_info "Starting dependency-update skill..."
    check_prerequisites

    local outdated_json
    outdated_json="$(get_outdated_packages)"

    apply_updates "$outdated_json"
    create_pr "$outdated_json"
}

main "$@"
