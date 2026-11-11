#!/usr/bin/env python3
import json, pathlib, re
root=pathlib.Path(__file__).resolve().parents[1]
data=json.loads((root/"Research"/"OriginalDylibOffsets.json").read_text())
known={x["selector"] for x in data["controllerMethods"]}
source=(root/"Sources"/"PHKLegacyAdapter.mm").read_text()
required={s for s in re.findall(r'@"([A-Za-z]\w*:?)"',source)
          if s.startswith(("toggle","action","bot","is")) or s in
          {"sharedInstance","ttlSegment","ttlUnitChanged:","fontButtons",
           "colorButtons","fontButtonTapped:","colorButtonClicked:",
           "showMenuFromViewController:"}}
missing=sorted(required-known)
assert data["methodCount"]==191 and data["hookCount"]==63
assert not missing, "Missing in original Mach-O method table: "+repr(missing)
assert "PHKMainThread()" in source
assert "PHKHasMethod(object_getClass(vc),s,2,'v',NO)" in source
print(f"PASS: {len(required)} selector names cross-checked with original Mach-O; 63 hook offsets indexed")
