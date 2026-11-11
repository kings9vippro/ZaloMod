#!/usr/bin/env python3
"""Inspect why a repackaged iOS IPA fails when a linked dylib is removed.

Read-only. Accepts an app-root ZIP or a standard Payload/*.app IPA.
"""
import argparse,json,plistlib,struct,zipfile
from pathlib import Path

STRONG={0xC,0x1F,0x23,0x20}
WEAK={0x18}

def linked(data):
    if len(data)<32:raise ValueError("Mach-O truncated")
    magic,cpu,_,_,n,cmdlen,_,_=struct.unpack_from("<IiiIIIII",data)
    if magic!=0xFEEDFACF or cpu!=0x0100000C:
        raise ValueError("Expected arm64 Mach-O executable")
    if 32+cmdlen>len(data):raise ValueError("Load commands truncated")
    pos=32
    items=[]
    for _ in range(n):
        if pos+8>32+cmdlen:raise ValueError("Invalid load command header")
        cmd,size=struct.unpack_from("<II",data,pos)
        if size<8 or pos+size>32+cmdlen:raise ValueError("Invalid load command")
        if cmd&0x7fffffff in STRONG|WEAK:
            if size<24:raise ValueError("Invalid dylib command")
            nameoff=struct.unpack_from("<I",data,pos+8)[0]
            if nameoff<24 or nameoff>=size:raise ValueError("Invalid load-name offset")
            name=data[pos+nameoff:pos+size].split(b"\0",1)[0].decode("utf-8","replace")
            items.append((name,(cmd&0x7fffffff) in WEAK))
        pos+=size
    return items

def inspect(path,crc=False):
    with zipfile.ZipFile(path) as archive:
        names=set(archive.namelist())
        executable=None
        for item in sorted(names):
            if item!="Info.plist" and not item.endswith(".app/Info.plist"):continue
            root=item[:-len("Info.plist")]
            try:info=plistlib.loads(archive.read(item))
            except (ValueError,TypeError):continue
            name=info.get("CFBundleExecutable")
            if isinstance(name,str) and root+name in names:
                executable=root,name
                break
        if not executable:raise ValueError("Cannot locate .app executable and Info.plist")
        root,name=executable
        results=[]
        missing=[]
        for lib,weak in linked(archive.read(root+name)):
            if lib.startswith(("/usr/lib/","/System/Library/")):continue
            if lib.startswith("@executable_path/"):
                member=root+lib.split("@executable_path/",1)[1]
            elif lib.startswith("@loader_path/"):
                member=root+lib.split("@loader_path/",1)[1]
            elif lib.startswith("@rpath/"):
                member=root+"Frameworks/"+lib.split("@rpath/",1)[1]
            else:continue
            result={"name":lib,"expected_archive_member":member,"present":member in names,"weak":weak}
            results.append(result)
            if member not in names and not weak:missing.append(result)
        corrupt=archive.testzip() if crc else None
        return {"source":path.name,"executable":root+name,"dependencies":results,
                "missing_strong_dependencies":missing,
                "strongly_links_old_zalomod":any(
                    d["name"].endswith("/ZaloModVIP.dylib") and not d["weak"] for d in results),
                "zip_crc":("ok" if corrupt is None else corrupt) if crc else "not_checked",
                "structurally_complete":not missing and corrupt is None,
                "note":"Static ZIP/Mach-O check only. Signing and runtime hooks unverified."}
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument("ipa",type=Path)
    p.add_argument("--crc",action="store_true")
    arg=p.parse_args()
    try:report=inspect(arg.ipa,arg.crc)
    except (OSError,ValueError,zipfile.BadZipFile) as e:
        print(json.dumps({"error":str(e)},ensure_ascii=False));return 2
    print(json.dumps(report,ensure_ascii=False,indent=2))
    return 0 if report["structurally_complete"] else 1
if __name__=="__main__":raise SystemExit(main())
