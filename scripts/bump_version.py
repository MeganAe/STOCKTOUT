#!/usr/bin/env python3
"""Bump version dans pubspec.yaml. Usage: python3 scripts/bump_version.py 1.1.0"""
import re, sys

v = sys.argv[1] if len(sys.argv) > 1 else None
if not v or not re.match(r"^\d+\.\d+\.\d+$", v):
    print("Usage: bump_version.py X.Y.Z")
    sys.exit(1)

p = "pubspec.yaml"
s = open(p, encoding="utf-8").read()
m = re.search(r"^version:\s*(\S+)", s, re.M)
old = m.group(1)
build = 1
if "+" in old:
    try:
        build = int(old.split("+")[1]) + 1
    except ValueError:
        build = 1
new = f"{v}+{build}"
s = re.sub(r"^version:\s*\S+", f"version: {new}", s, count=1, flags=re.M)
open(p, "w", encoding="utf-8").write(s)
print(f"{old} -> {new}")
