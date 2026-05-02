#!/usr/bin/env bash
set -euo pipefail

echo "[1] Check: no raw/ tracked"
if git ls-files | grep -q '^raw/'; then
  echo "FAIL: raw/ is tracked"
  exit 1
fi

echo "[2] Check: no candidates_* tracked"
if git ls-files | grep -qi 'candidates_'; then
  echo "FAIL: candidates_* is tracked"
  exit 1
fi

echo "[3] Check: no evidence/files tracked"
if git ls-files | grep -q '^evidence/files/'; then
  echo "FAIL: evidence/files/ is tracked"
  exit 1
fi

echo "[4] Check: no live URLs tracked"
PATTERN='http''s?://'
if git grep -nE "$PATTERN" -- . ':!report/*.pdf' ':!report/*.docx' ':!tools/portfolio_check.sh' >/dev/null 2>&1; then
  echo "FAIL: found live URL pattern in tracked text files"
  git grep -nE "$PATTERN" -- . ':!report/*.pdf' ':!report/*.docx' ':!tools/portfolio_check.sh' || true
  exit 1
fi

echo "OK: portfolio safety checks passed."
