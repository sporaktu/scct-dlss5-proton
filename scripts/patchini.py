#!/usr/bin/env python3
"""Set existing keys in an ini file in place, preserving line endings and everything else.

Usage: patchini.py FILE Section.Key=value [Section.Key=value ...]

Section and key names are matched case-insensitively. Only keys that already exist are
changed (it never adds a key); the script prints how many were set and which were missing.
"""
import sys, re
path = sys.argv[1]; want = {}
for a in sys.argv[2:]:
    sk, v = a.split('=', 1); s, k = sk.split('.', 1); want[(s.lower(), k.lower())] = v
out = []; sec = ''; done = set()
for line in open(path, encoding='utf-8', errors='surrogateescape', newline=''):
    m = re.match(r'\s*\[(.+?)\]', line)
    if m: sec = m.group(1).lower()
    m = re.match(r'([ \t]*)([A-Za-z0-9_]+)([ \t]*=[ \t]*)([^\r\n]*)(\r?\n?)$', line)
    if m and (sec, m.group(2).lower()) in want:
        k = (sec, m.group(2).lower())
        line = m.group(1) + m.group(2) + m.group(3) + want[k] + m.group(5); done.add(k)
    out.append(line)
open(path, 'w', encoding='utf-8', errors='surrogateescape', newline='').write(''.join(out))
missing = [k for k in want if k not in done]
print('set', len(done), 'missing', missing)
sys.exit(1 if missing else 0)
