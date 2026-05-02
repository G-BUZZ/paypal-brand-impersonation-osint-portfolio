#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   tools/run_daily_paypal.sh              -> uses today's LOCAL date
#   tools/run_daily_paypal.sh 2026-02-10   -> uses a specific day

DAY="${1:-$(date +%F)}"

# Safety: never run on the published snapshot branch
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH="$(git rev-parse --abbrev-ref HEAD)"
  if [ "$BRANCH" = "portfolio" ]; then
    echo "Refusing to run on 'portfolio'. Checkout 'main' first." >&2
    exit 1
  fi
fi


mkdir -p "raw/$DAY" "daily/$DAY" "evidence/files"

ensure_metrics_header() {
  if [ ! -f data/Daily-Metrics.csv ]; then
    mkdir -p data
    cat > data/Daily-Metrics.csv <<'H'
date,total_indicators,new_indicators,high,medium,low,channel_web,channel_email,channel_social,notes
H
  fi
}

dedupe_metrics_day() {
  local day="$1"
  [ -f data/Daily-Metrics.csv ] || return 0
  local tmp
  tmp="$(mktemp)"
  head -n 1 data/Daily-Metrics.csv > "$tmp"
  tail -n +2 data/Daily-Metrics.csv | grep -v "^${day}," >> "$tmp" || true
  mv "$tmp" data/Daily-Metrics.csv
}

sort_metrics() {
  [ -f data/Daily-Metrics.csv ] || return 0
  local tmp
  tmp="$(mktemp)"
  head -n 1 data/Daily-Metrics.csv > "$tmp"
  tail -n +2 data/Daily-Metrics.csv | sort -t, -k1,1 >> "$tmp" || true
  mv "$tmp" data/Daily-Metrics.csv
}

maybe_commit() {
  if [ "${NO_COMMIT:-0}" = "1" ]; then
    echo "NO_COMMIT=1: skipping commit: $*"
    return 0
  fi
  git commit "$@" || true
}


# --- Download sources (raw, never publish) ---
curl -fsSL "https://openphish.com/feed.txt" -o "raw/$DAY/openphish.txt" || true
curl -fsSL "https://urlhaus.abuse.ch/downloads/csv_online/" -o "raw/$DAY/urlhaus_csv_online.csv" || true

# Certificate Transparency (crt.sh) for brand-monitoring (not necessarily malicious)
# using %paypa% to include slight variations; output is sanitized (dots replaced with [.] )
CT_HTTP_FILE="raw/$DAY/crtsh_http.txt"
CT_HTTP="$(curl -sS -L -A "Mozilla/5.0" -o "raw/$DAY/crtsh_paypa.json" -w "%{http_code}" "https://crt.sh/?q=%25paypa%25&exclude=expired&deduplicate=Y&output=json" || echo 000)"
printf "%s" "$CT_HTTP" > "$CT_HTTP_FILE"

CT_FETCH_OK=1
if [ "$CT_HTTP" != "200" ]; then
  CT_FETCH_OK=0
  rm -f "raw/$DAY/crtsh_paypa.json" 2>/dev/null || true
fi
# --- Extract candidates (sensitive; removed after sanitization) ---
if [ -s "raw/$DAY/openphish.txt" ]; then
  grep -Eai "paypa" "raw/$DAY/openphish.txt" > "daily/$DAY/candidates_openphish.txt" || true
else
  : > "daily/$DAY/candidates_openphish.txt"
fi

python3 - <<PY
import csv, re
from pathlib import Path

inp = Path("raw/$DAY/urlhaus_csv_online.csv")
out = Path("daily/$DAY/candidates_urlhaus.txt")

urls = []
if inp.exists() and inp.stat().st_size > 0:
    with inp.open("r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if line.startswith("#") or not line.strip():
                continue
            try:
                row = next(csv.reader([line]))
            except Exception:
                continue
            if not row:
                continue
            url = row[0]  # URLhaus: first column is 'url'
            if url.lower() == "url":  # skip header
                continue
            if re.search(r"paypa", url, re.IGNORECASE):
                urls.append(url)

out.write_text("\n".join(urls) + ("\n" if urls else ""), encoding="utf-8")
PY

# --- Merge & sanitize (public-safe) ---
SAN="daily/$DAY/paypal_indicators_sanitized.txt"
: > "$SAN"

TMP="$(mktemp)"
cat "daily/$DAY/candidates_openphish.txt" "daily/$DAY/candidates_urlhaus.txt" 2>/dev/null \
  | sed '/^\s*$/d' > "$TMP" || true

python3 - <<PY
from pathlib import Path
import subprocess

inp=Path("$TMP")
out=Path("$SAN")

seen=set()
lines=[]
if inp.exists():
    for ln in inp.read_text(errors="ignore").splitlines():
        u=ln.strip()
        if not u or u in seen:
            continue
        seen.add(u)
        lines.append(u)

out_lines=[]
for u in lines:
    p = subprocess.run(["python3","tools/redact_indicator.py",u], capture_output=True, text=True)
    s = (p.stdout or "").strip()
    if s:
        out_lines.append(s)

out.write_text("\n".join(out_lines) + ("\n" if out_lines else ""), encoding="utf-8")
print(len(out_lines))
PY

rm -f "$TMP" || true
COUNT="$(wc -l < "$SAN" | tr -d ' ')"

# Remove candidate lists (may contain live malicious URLs)
rm -f "daily/$DAY/candidates_openphish.txt" "daily/$DAY/candidates_urlhaus.txt" || true

# --- Certificate Transparency parsing (safe domains; not necessarily malicious) ---
CT_SAN="daily/$DAY/ct_domains_sanitized.txt"
CT_COUNT="$(python3 - <<PY
import json
from pathlib import Path

inp = Path("raw/$DAY/crtsh_paypa.json")
out = Path("daily/$DAY/ct_domains_sanitized.txt")

domains=set()
if inp.exists() and inp.stat().st_size > 0:
    try:
        data = json.loads(inp.read_text(encoding="utf-8", errors="ignore"))
        for item in data:
            nv = (item.get("name_value") or "")
            for d in nv.splitlines():
                d = d.strip().lower()
                if not d:
                    continue
                if d.startswith("*."):
                    d = d[2:]
                if "paypa" in d:
                    # OPTIONAL: hide obvious legit domains to surface lookalikes
                    if d.endswith("paypal.com") or d.endswith("paypalobjects.com"):
                        continue
                    domains.add(d)
    except Exception:
        pass

lst = sorted(domains)[:200]
safe = [d.replace(".", "[.]") for d in lst]
out.write_text("\n".join(safe) + ("\n" if safe else ""), encoding="utf-8")
print(len(safe))
PY
)"
[ "${CT_COUNT:-0}" = "0" ] && rm -f "$CT_SAN" || true

# --- If no phishing indicators: handle "no results" vs "CT-only signals" ---
if [ "$COUNT" = "0" ] && [ "${CT_COUNT:-0}" = "0" ]; then
  rm -f "$SAN" 2>/dev/null || true

  cat > "daily/$DAY/README.md" <<EOF2
## Daily run summary

- Result: **0 PayPal-related indicators found** (normal for some days/feeds).
- Sources used: (CT fetch: HTTP ${CT_HTTP:-unknown}) OpenPhish + URLhaus + crt.sh (public defensive sources).
- Actions: metrics updated; **no evidence records created** (portfolio-safe policy).
EOF2

  ensure_metrics_header
  dedupe_metrics_day "$DAY"
  echo "$DAY,0,0,0,0,0,0,0,0,No matches (OpenPhish+URLhaus; CT HTTP ${CT_HTTP:-unknown})" >> data/Daily-Metrics.csv
  sort_metrics

  git add "daily/$DAY/README.md" data/Daily-Metrics.csv || true
  maybe_commit -m "Day $DAY: no results (OpenPhish+URLhaus+CT), metrics updated" || true
  exit 0
fi

if [ "$COUNT" = "0" ] && [ "${CT_COUNT:-0}" != "0" ]; then
  rm -f "$SAN" 2>/dev/null || true

  cat > "daily/$DAY/README.md" <<EOF2
## Daily run summary

- Result: **0 phishing indicators found** (OpenPhish+URLhaus).
- Brand-monitoring signals: **$CT_COUNT CT domains** (Certificate Transparency; not necessarily malicious).
- Sources used: OpenPhish + URLhaus + crt.sh (public defensive sources).
- Actions: metrics updated; **no evidence records created** (portfolio-safe policy).
EOF2

  ensure_metrics_header
  dedupe_metrics_day "$DAY"
  echo "$DAY,0,0,0,0,0,0,0,0,CT domains: $CT_COUNT (no phishing indicators)" >> data/Daily-Metrics.csv
  sort_metrics

  git add "daily/$DAY/README.md" data/Daily-Metrics.csv "$CT_SAN" || true
  maybe_commit -m "Day $DAY: CT brand-monitoring signals only, metrics updated" || true
  exit 0
fi

# If COUNT > 0, keep existing behavior (evidence creation etc.)
cat > "daily/$DAY/README.md" <<EOF2
## Daily run summary

- Result: **$COUNT PayPal-related indicators found** (sanitized list).
- Sources used: OpenPhish + URLhaus + crt.sh (CT brand-monitoring).
- Artifacts:
  - paypal_indicators_sanitized.txt (de-weaponized, no PII, no clickable URLs)
  - ct_domains_sanitized.txt (CT signals; not necessarily malicious)
- Note: Evidence creation workflow not triggered here (use your existing evidence branch if needed).
EOF2

ensure_metrics_header
dedupe_metrics_day "$DAY"
echo "$DAY,$COUNT,$COUNT,0,$COUNT,0,$COUNT,0,0,Results from OpenPhish+URLhaus; CT domains: ${CT_COUNT:-0}" >> data/Daily-Metrics.csv
sort_metrics

git add "daily/$DAY/README.md" "$SAN" data/Daily-Metrics.csv || true
[ -f "$CT_SAN" ] && git add "$CT_SAN" || true
maybe_commit -m "Day $DAY: update daily artifacts + metrics (with CT)" || true
