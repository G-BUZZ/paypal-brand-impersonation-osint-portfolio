# Payment Brand Impersonation Monitoring (OSINT) — Portfolio Case Study

This repository is a portfolio-safe OSINT project that documents a defensive workflow for monitoring public indicators of brand impersonation affecting a major payment brand.

The project focuses on process quality rather than publishing sensitive indicators: collection, triage, redaction, metrics, evidence handling, and responsible reporting discipline.

## What this project demonstrates

- Public-source OSINT collection from defensive feeds and public transparency sources.
- Repeatable daily monitoring with documented zero-result days.
- Safe handling of potentially malicious indicators: no live phishing URLs are published.
- Redaction and de-weaponization practices for portfolio/public reporting.
- Basic metrics suitable for an executive summary or analyst report.
- Git hygiene for separating public artifacts from private/raw evidence.

## Current status

This is a clean public snapshot of the workflow. The current monitoring sample starts in May 2026 and deliberately documents daily results transparently, including zero-result days instead of backfilling or overstating findings.

Current public metrics show no confirmed active indicators in the tracked days. That is acceptable for a defensive monitoring project: the value is in the reproducible workflow, safety controls, and transparent reporting discipline.

## Data sources used by the workflow

The scripts are designed around lawful, public, defensive sources, including:

- OpenPhish public feed
- URLhaus online CSV feed
- Certificate Transparency search via crt.sh for brand-monitoring signals

Certificate Transparency results are treated as brand-monitoring signals, not as proof of malicious activity.

## Safety and ethics

This repository intentionally excludes:

- raw feed downloads
- clickable suspicious URLs
- private evidence screenshots
- personal data
- email headers, tracking IDs, credentials, or user identifiers
- anything requiring login bypass or interaction with suspicious infrastructure

The project is independent and is not affiliated with, endorsed by, or sponsored by PayPal or any other brand mentioned in examples.

## Repository structure

```text
data/          public metrics and sanitized example data
 daily/         daily public run summaries
 methodology/   collection, triage, and redaction methodology
 report/        report outline for future PDF export
 tools/         helper scripts for collection, redaction, hashing, and safety checks
```

Private/local-only folders are excluded through `.gitignore`:

```text
raw/
evidence/files/
daily/*/candidates_*.txt
hashes.csv
*.zip
```

## How to run the safety checks

```bash
bash tools/safety_check.sh
bash tools/portfolio_check.sh
```

These checks are meant to fail if raw feeds, candidate lists, private evidence files, or live URLs are accidentally tracked.

## Analyst note

This project should be read as a junior analyst portfolio case study: it demonstrates structured OSINT collection, documentation discipline, and safe public reporting. It is not a complete threat intelligence product, not legal advice, and not an official brand-protection operation.
