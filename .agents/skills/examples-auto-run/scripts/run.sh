#!/usr/bin/env bash
# examples-auto-run/scripts/run.sh
# Automatically discovers and runs all examples in the repository,
# capturing output and reporting pass/fail status.

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
EXAMPLES_DIR="${REPO_ROOT}/examples"
LOG_DIR="${REPO_ROOT}/.agents/skills/examples-auto-run/logs"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-60}"
PYTHON_BIN="${PYTHON_BIN:-python}"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILED_EXAMPLES=()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[examples-auto-run] $*"; }
warn() { echo "[examples-auto-run] WARNING: $*" >&2; }
err()  { echo "[examples-auto-run] ERROR: $*" >&2; }

mkdir -p "${LOG_DIR}"

# Check that the examples directory exists
if [[ ! -d "${EXAMPLES_DIR}" ]]; then
  err "Examples directory not found: ${EXAMPLES_DIR}"
  exit 1
fi

# ---------------------------------------------------------------------------
# Discover example files
# ---------------------------------------------------------------------------
# Collect all *.py files under examples/, sorted for deterministic ordering.
mapfile -t EXAMPLE_FILES < <(find "${EXAMPLES_DIR}" -name '*.py' | sort)

if [[ ${#EXAMPLE_FILES[@]} -eq 0 ]]; then
  warn "No Python example files found under ${EXAMPLES_DIR}"
  exit 0
fi

log "Found ${#EXAMPLE_FILES[@]} example file(s) to run."
log "Timeout per example: ${TIMEOUT_SECONDS}s"
log "Log directory: ${LOG_DIR}"
echo ""

# ---------------------------------------------------------------------------
# Run each example
# ---------------------------------------------------------------------------
for example_path in "${EXAMPLE_FILES[@]}"; do
  relative_path="${example_path#"${REPO_ROOT}/"}"
  example_name="$(basename "${example_path}" .py)"
  log_file="${LOG_DIR}/${example_name}.log"

  # Skip files that contain a marker indicating they require manual setup
  if grep -q '# auto-run: skip' "${example_path}" 2>/dev/null; then
    log "SKIP  ${relative_path}  (marked as skip)"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  log "RUN   ${relative_path}"

  # Run the example with a timeout, capturing stdout+stderr
  set +e
  timeout "${TIMEOUT_SECONDS}" \
    "${PYTHON_BIN}" "${example_path}" \
    > "${log_file}" 2>&1
  exit_code=$?
  set -e

  if [[ ${exit_code} -eq 0 ]]; then
    log "PASS  ${relative_path}"
    PASS_COUNT=$((PASS_COUNT + 1))
  elif [[ ${exit_code} -eq 124 ]]; then
    err "TIMEOUT ${relative_path} (exceeded ${TIMEOUT_SECONDS}s)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_EXAMPLES+=("${relative_path} [TIMEOUT]")
  else
    err "FAIL  ${relative_path} (exit code ${exit_code})"
    err "      See log: ${log_file}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_EXAMPLES+=("${relative_path} [exit ${exit_code}]")
  fi
done

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
log "======================================"
log "Results: ${PASS_COUNT} passed, ${FAIL_COUNT} failed, ${SKIP_COUNT} skipped"
log "======================================"

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  err "Failed examples:"
  for item in "${FAILED_EXAMPLES[@]}"; do
    err "  - ${item}"
  done
  exit 1
fi

log "All examples passed."
exit 0
