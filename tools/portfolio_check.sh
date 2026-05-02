#!/usr/bin/env bash
set -euo pipefail

echo "[1] Check: no raw/ tracked"
if git ls-files | grep -q '^raw/'; then
  echo "FAIL: raw/ is tracked"; exit 1
fi

echo "[2] Check: no candidates_* tracked"
if git ls-files | grep -qi 'candidates_'; then
  echo "FAIL: candidates_* is tracked"; exit 1
fi

echo "[3] Check: no evidence/files tracked"
if git ls-files | grep -q '^evidence/files/'; then
  echo "FAIL: evidence/files/ is tracked"; exit 1
fi

echo "[4] Check: no live URLs tracked (http/https)"
if git grep -nE 'https?://' -- . ':!report/*.pdf' ':!report/*.docx' >/dev/null 2>&1; then
  echo "FAIL: found http(s):// in tracked text files"; exit 1
fi

echo "OK: portfolio safety checks passed."
