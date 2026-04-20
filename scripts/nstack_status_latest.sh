#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${HOME}/nstack"

echo "nstack latest status"
echo "repo: ${REPO_ROOT}"
echo

echo "HEAD:"
git -C "${REPO_ROOT}" log -1 --oneline
echo

echo "working tree:"
git -C "${REPO_ROOT}" status --short
echo

"${REPO_ROOT}/scripts/verify_claude_skill_sync.sh"
