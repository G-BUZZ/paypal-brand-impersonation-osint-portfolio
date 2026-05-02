# Redaction & De-weaponization Guidelines

## Never publish
- Clickable URLs to suspected phishing/scam pages
- Full email headers that contain personal addresses or routing details
- Phone numbers, wallet addresses, unique tracking IDs, or victim identifiers

## De-weaponize links
- Replace '.' with '[.]' (example: paypal[.]com)
- Replace 'http' with 'hxxp' (example: hxxps://)
- Remove everything after the domain unless strictly needed for analysis
- If you must show a path, truncate and remove query strings (e.g., /login/...)

## Remove personal data (PII)
- Emails: show only partial (e.g., j***@domain[.]tld)
- Usernames: mask middle characters
- Images: blur faces, names, numbers, QR codes, barcodes

## Keep what matters
- The pattern (typo, impersonation wording, brand misuse)
- The date/time observed
- The source type (feed/advisory/archived capture)
- Your reasoning for the rating
