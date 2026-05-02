#!/usr/bin/env python3
"""redact_indicator.py - de-weaponize a URL/domain for portfolio-safe reporting."""
from __future__ import annotations
import sys
from urllib.parse import urlparse

def redact(s: str) -> str:
    s = s.strip()
    if not s:
        return s
    if '://' in s:
        u = urlparse(s)
        scheme = 'hxxp' if u.scheme == 'http' else 'hxxps' if u.scheme == 'https' else u.scheme
        host = u.netloc.replace('.', '[.]')
        return f"{scheme}://{host}/..."
    return s.replace('.', '[.]')

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Usage: redact_indicator.py "<url-or-domain>"')
        sys.exit(1)
    print(redact(sys.argv[1]))
