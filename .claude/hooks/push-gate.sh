#!/usr/bin/env bash
# PreToolUse hook: blocks "git push" unless push-gate checklist exists and passes.
# Writes bd memory on block events (best-effort).
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // ""')
[[ "$TOOL" != "Bash" ]] && exit 0

# Only gate pushes that originate from within a DRUPAL_ISSUES work tree.
# This replaces the fragile "git push" regex that matched the substring
# inside commit messages, heredocs, and non-issue pushes alike.
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // "."')
NID=$(echo "$PROJECT_DIR" | grep -oP 'DRUPAL_ISSUES/\K[0-9]+' | head -1 || true)
[[ -z "$NID" ]] && exit 0

# We're inside a DRUPAL_ISSUES tree. Now check if this is actually a push.
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
# Use word-boundary-safe check: match "git push" or "git -C ... push" at
# command boundaries, not inside quoted strings or commit messages.
if ! echo "$CMD" | grep -qP '^\s*(?:cd\s+[^;]*;\s*)?(?:GIT_\w+=\S+\s+)*git\s+(?:-C\s+\S+\s+)?push\b'; then
  exit 0
fi

# Direct path lookup instead of find.
CHECKLIST=""
if [[ -n "$NID" && -n "$CLAUDE_PROJECT_DIR" ]]; then
  CANDIDATE="$CLAUDE_PROJECT_DIR/DRUPAL_ISSUES/$NID/workflow/03-push-gate-checklist.json"
  if [[ -f "$CANDIDATE" ]]; then
    AGE_MIN=$(( ($(date +%s) - $(stat -c %Y "$CANDIDATE")) / 60 ))
    if (( AGE_MIN < 60 )); then
      CHECKLIST="$CANDIDATE"
    fi
  fi
fi

if [[ -z "$CHECKLIST" ]]; then
  bd remember "Blocked premature push for $NID: no checklist" \
    --key "phase.push_gate.blocked.$NID" 2>/dev/null || true
  echo "BLOCKED: No push-gate checklist found for issue $NID (workflow/03-push-gate-checklist.json)." >&2
  echo "Run the full Pre-Push Quality Gate before pushing." >&2
  exit 2
fi

# Check verdicts — any FAILED, NEEDS_WORK, false, or non-zero exit code blocks
FAILED=$(jq -r 'to_entries[]
  | select(.key | test("verdict|passed|exit_code"))
  | select(
      (.value == "FAILED") or
      (.value == "NEEDS_WORK") or
      (.value == false) or
      ((.key | test("exit_code")) and (.value != 0))
    )
  | "\(.key)=\(.value)"' "$CHECKLIST" 2>/dev/null)

if [[ -n "$FAILED" ]]; then
  NID=$(jq -r '.issue_id // "unknown"' "$CHECKLIST")
  bd remember "Blocked push for $NID: failed checks: $FAILED" \
    --key "phase.push_gate.blocked.$NID" 2>/dev/null || true
  echo "BLOCKED: Push-gate checklist has failing checks:" >&2
  echo "$FAILED" >&2
  echo "Fix these before pushing." >&2
  exit 2
fi

exit 0
