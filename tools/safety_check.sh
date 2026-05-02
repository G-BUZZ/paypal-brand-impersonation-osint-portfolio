#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] check: raw/ non deve essere tracciato"
if git ls-files | grep -qE '^raw/'; then
  echo "ERRORE: raw/ è tracciato"; exit 1
fi

echo "[2/4] check: candidates_* non devono essere tracciati"
if git ls-files | grep -qE 'candidates_'; then
  echo "ERRORE: candidates_* è tracciato"; exit 1
fi

echo "[3/4] check: evidence/files/ non deve essere tracciato"
if git ls-files | grep -qE '^evidence/files/'; then
  echo "ERRORE: evidence/files/ è tracciato"; exit 1
fi

echo "[4/4] OK: repo portfolio-safe"
