#!/usr/bin/env python3
"""hash_evidence.py - compute SHA-256 hashes for evidence files (defensive documentation)."""
from __future__ import annotations
import argparse, csv, hashlib
from pathlib import Path

def sha256_file(p: Path) -> str:
    h = hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--folder', required=True, help='Folder containing evidence files')
    ap.add_argument('--out', default='hashes.csv', help='Output CSV')
    ap.add_argument('--update', help='Evidence log CSV to update (writes *.updated.csv)')
    ap.add_argument('--match-column', default='screenshot_file')
    ap.add_argument('--hash-column', default='sha256')
    args = ap.parse_args()

    folder = Path(args.folder)
    files = [p for p in folder.rglob('*') if p.is_file()]
    mapping = {p.name: sha256_file(p) for p in files}

    with open(args.out, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f); w.writerow(['filename','sha256'])
        for name, h in sorted(mapping.items()):
            w.writerow([name, h])

    if args.update:
        in_path = Path(args.update)
        out_path = in_path.with_suffix(in_path.suffix + '.updated.csv')
        with in_path.open('r', newline='', encoding='utf-8') as f:
            r = csv.DictReader(f)
            fieldnames = list(r.fieldnames or [])
            if args.hash_column not in fieldnames:
                fieldnames.append(args.hash_column)
            rows = list(r)
        for row in rows:
            fn = (row.get(args.match_column) or '').strip()
            if fn in mapping:
                row[args.hash_column] = mapping[fn]
        with out_path.open('w', newline='', encoding='utf-8') as f:
            w = csv.DictWriter(f, fieldnames=fieldnames)
            w.writeheader(); w.writerows(rows)
        print(f'Updated evidence log written to: {out_path}')

if __name__ == '__main__':
    main()
