# Methodology (Portfolio Version)

## Scope
This case study monitors brand impersonation and scam indicators related to PayPal, using only open and lawful sources.
The goal is to demonstrate a professional workflow: collection -> triage -> evidence handling -> reporting.

## Allowed data
- Public phishing/scam feeds or public advisories
- Public social posts and pages (no private groups, no login-bypass)
- Public domain and certificate metadata (non-invasive)
- Publicly available archives (where permitted)

## Disallowed actions
- Logging into accounts you do not own or have written permission to test
- Bypassing access controls, captchas, paywalls, or authentication
- Aggressive scraping that violates site terms or harms availability
- Publishing live phishing URLs or personal data

## Daily workflow (15-45 minutes)
1. Ingest: collect candidate indicators from allowed sources
2. Normalize: put indicators into a standard format (see data schema)
3. Dedupe: remove repeats, keep first-seen/last-seen
4. Triage: assign confidence + risk rating
5. Evidence: capture proof (screenshots) without interacting
6. Redact: remove PII and de-weaponize links (no clickable URLs)
7. Log: update Evidence Log + compute file hashes
8. Metrics: update daily counts (trend line)
9. (Optional) Report: send to official channels if active/harmful

## Risk rating (simple and explainable)
- Likelihood: Low / Medium / High (is it active? how consistent are signals?)
- Impact: Low / Medium / High (credential theft? payment diversion? scale?)
- Confidence: Low / Medium / High (quality of evidence, corroboration)
