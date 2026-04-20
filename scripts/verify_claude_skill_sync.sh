#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${HOME}/nstack"
CLAUDE_ROOT="${HOME}/.claude/skills"
SKILLS=(
  design
  design-shotgun
  design-review
  design-consultation
  plan-design-review
)

failures=0

echo "nstack Claude skill sync check"
echo "repo:   ${REPO_ROOT}"
echo "claude: ${CLAUDE_ROOT}"
echo

for skill in "${SKILLS[@]}"; do
  repo_dir="${REPO_ROOT}/${skill}"
  claude_dir="${CLAUDE_ROOT}/${skill}"
  repo_file="${repo_dir}/SKILL.md"
  claude_file="${claude_dir}/SKILL.md"

  echo "[${skill}]"

  if [[ ! -e "${claude_dir}" ]]; then
    echo "  status: MISSING_CLAUDE_LINK"
    failures=$((failures + 1))
    echo
    continue
  fi

  target="$(readlink "${claude_dir}" 2>/dev/null || true)"
  if [[ -n "${target}" ]]; then
    echo "  link:   ${target}"
  else
    echo "  link:   not-a-symlink"
  fi

  if [[ ! -f "${repo_file}" ]]; then
    echo "  status: MISSING_REPO_SKILL"
    failures=$((failures + 1))
    echo
    continue
  fi

  if [[ ! -f "${claude_file}" ]]; then
    echo "  status: MISSING_CLAUDE_SKILL"
    failures=$((failures + 1))
    echo
    continue
  fi

  repo_hash="$(shasum "${repo_file}" | awk '{print $1}')"
  claude_hash="$(shasum "${claude_file}" | awk '{print $1}')"

  echo "  repo:   ${repo_hash}"
  echo "  claude: ${claude_hash}"

  if [[ "${repo_hash}" == "${claude_hash}" ]]; then
    echo "  status: OK"
  else
    echo "  status: HASH_MISMATCH"
    failures=$((failures + 1))
  fi

  echo
done

if [[ "${failures}" -eq 0 ]]; then
  echo "RESULT: all checked skills are in sync"
else
  echo "RESULT: ${failures} issue(s) found"
  exit 1
fi
