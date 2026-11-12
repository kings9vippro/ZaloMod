#!/usr/bin/env python3
"""Check generated asset-catalog icon roles, pixel dimensions, and alpha safety."""
from __future__ import annotations
import json,struct,sys
from pathlib import Path

def verify(directory:Path)->None:
    manifest=json.loads((directory/"Contents.json").read_text(encoding="utf-8"))
    entries=manifest["images"]
    if len(entries)!=12:raise AssertionError(f"Expected 12 roles (11 device + marketing), got {len(entries)}")
    seen=set()
    for role in entries:
        name=role["filename"]
        if name in seen:raise AssertionError(f"Duplicate filename: {name}")
        seen.add(name)
        data=(directory/name).read_bytes()
        if data[:8]!=b"\x89PNG\r\n\x1a\n":
            raise AssertionError(f"Not PNG: {name}")
        width,height=struct.unpack_from(">II",data,16)
        dimension=int(round(float(role["size"].split("x")[0])*float(role["scale"][0])))
        if (width,height)!=(dimension,dimension):
            raise AssertionError(f"Bad icon dimensions for {name}: {(width,height)} vs {(dimension,dimension)}")
        color_type=data[25]
        if color_type!=2:raise AssertionError(f"Expected opaque RGB PNG for {name}, PNG color type {color_type}")
    required={"PHK-iPhone-60-3x.png","PHK-Marketing-1024.png"}
    if not required.issubset(seen):raise AssertionError("Missing required launch or marketing icon")
    print(f"PASS: {len(entries)} opaque PHK icons, exact dimensions and asset catalog labels")

if __name__=="__main__":
    if len(sys.argv)!=2:sys.exit("Usage: python scripts/validate_phk_icons.py PATH")
    verify(Path(sys.argv[1]))
