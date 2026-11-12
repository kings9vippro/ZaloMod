#!/usr/bin/env python3
"""Version-pinned, read-only ARM64 Mach-O metadata and offset inventory.

Accepts a user-supplied decrypted IPA (or .app ZIP). Extracts static symbol
offsets and Objective-C metadata strings. The latter are NOT function offsets.
No private chat/session data, offsets guessing or binary patching.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import struct
import uuid
import zipfile
from pathlib import Path

MH_MAGIC_64=0xFEEDFACF
ARM64=0x0100000C
MH_EXECUTE=2
LC_SEGMENT_64=0x19
LC_UUID=0x1B
LC_SYMTAB=0x02
LC_ENCRYPTION_INFO_64=0x2C
LC_LOAD_DYLIB=0xC
DYLIB_TYPES={0xC,0x18,0x1F,0x23,0x20}
KEYWORDS=(
    "KBChatInputComponentView","ZAInputView","ZACustomInputView",
    "ZinstantInputView","ZaloMod","ZaloFloatingButton",
    "ZaloModVIP","Sticker","zSticker","Chat","Input",
    "TabBar","Message","MessageView","Emoji","Font","Color",
)


def bounded(data:bytes,start:int,length:int)->bytes:
    if start<0 or length<0 or start>len(data) or length>len(data)-start:
        raise ValueError("Mach-O has invalid offset/length")
    return data[start:start+length]


def commands(data:bytes):
    if len(data)<32:
        raise ValueError("Truncated ARM64 Mach-O header")
    magic,cputype,_,kind,count,size,_,_=struct.unpack_from("<IiiIIIII",data)
    if magic!=MH_MAGIC_64 or cputype!=ARM64 or kind!=MH_EXECUTE:
        raise ValueError("Expecting thin ARM64 executable (not encrypted App Store installer)")
    if count>4096 or size>len(data)-32:
        raise ValueError("Invalid Mach-O command list")
    pos=32
    end=32+size
    for _ in range(count):
        if pos+8>end:raise ValueError("Malformed load-command header")
        command,length=struct.unpack_from("<II",data,pos)
        if length<8 or length%8 or pos+length>end:
            raise ValueError("Malformed Mach-O load-command size")
        yield command,bounded(data,pos,length)
        pos+=length
    if pos!=end:raise ValueError("Number of load commands does not match sizeofcmds")


def parse(data:bytes)->dict:
    sections=[]
    segments=[]
    uuid_str=None
    dylibs=[]
    symtable=None
    cryptid=0
    for command,blob in commands(data):
        raw=command&0x7FFFFFFF
        if raw==LC_SEGMENT_64:
            if len(blob)<72:raise ValueError("Short segment command")
            segname,vmaddr,vmsize,fileoff,filesize,maxprot,initprot,nsects,flags=struct.unpack_from(
                "<16sQQQQiiII",blob,8
            )
            if nsects>128 or 72+80*nsects>len(blob):
                raise ValueError("Malformed Mach-O section list")
            segname=segname.split(b"\0",1)[0].decode("ascii","replace")
            segments.append((vmaddr,vmsize,fileoff,filesize,segname))
            for i in range(nsects):
                off=72+i*80
                sn,sec_segment,addr,sz,offset,align,reloff,nreloc,secflags,r1,r2,r3=struct.unpack_from(
                    "<16s16sQQIIIIIIII",blob,off
                )
                name=sn.split(b"\0",1)[0].decode("ascii","replace")
                section_type=secflags&0xFF
                if section_type in (1,12,18):continue # zerofill sections
                if sz and offset:
                    bounded(data,offset,sz)
                    sections.append({"name":name,"segment":segname,"file_offset":offset,"size":sz,
                                     "vmaddr":addr})
        elif raw==LC_UUID:
            if len(blob)<24:raise ValueError("Short LC_UUID")
            uuid_str=str(uuid.UUID(bytes=blob[8:24]))
        elif raw==LC_SYMTAB:
            if len(blob)<24:raise ValueError("Short LC_SYMTAB")
            symtable=struct.unpack_from("<IIII",blob,8)
        elif raw==LC_ENCRYPTION_INFO_64:
            if len(blob)<24:raise ValueError("Short encryption info")
            cryptid=struct.unpack_from("<I",blob,16)[0]
        elif raw in DYLIB_TYPES:
            if len(blob)<24:raise ValueError("Malformed dylib load command")
            pointer=struct.unpack_from("<I",blob,8)[0]
            if not 24<=pointer<len(blob):raise ValueError("Malformed dylib load path")
            name=blob[pointer:].split(b"\0",1)[0].decode("utf-8","replace")
            dylibs.append({"name":name,"weak":raw==0x18})

    text=next((x for x in segments if x[4]=="__TEXT"),None)
    text_base=text[0] if text else None
    interested=[]
    for sec in sections:
        if sec["name"] not in ("__objc_classname","__objc_methname"):
            continue
        raw=bounded(data,sec["file_offset"],sec["size"])
        i=0
        for item in raw.split(b"\0"):
            if item:
                try:value=item.decode("utf-8")
                except UnicodeDecodeError:value=""
                if value and len(value)<180 and any(key.lower() in value.lower() for key in KEYWORDS):
                    interested.append({
                        "section":sec["name"],"value":value,
                        "string_file_offset":sec["file_offset"]+i,
                        "note":"Metadata STRING offset; not a callable function offset.",
                    })
            i+=len(item)+1
    symbols=[]
    if symtable is not None:
        symoff,nsyms,stroff,strsize=symtable
        if nsyms>1_000_000:raise ValueError("Too many symbol table entries")
        table=bounded(data,symoff,nsyms*16)
        strings=bounded(data,stroff,strsize)
        for i in range(nsyms):
            stridx,typ,sect,desc,value=struct.unpack_from("<IBBHQ",table,i*16)
            if not value or stridx>=len(strings) or not (typ&0x0E):continue
            raw=strings[stridx:].split(b"\0",1)[0]
            if len(raw)>240:continue
            name=raw.decode("utf-8","replace")
            if not any(k.lower() in name.lower() for k in KEYWORDS):
                continue
            symbols.append({
                "name":name,
                "unslid_vmaddr":hex(value),
                "rva_from_TEXT":hex(value-text_base) if text_base is not None and value>=text_base else None,
                "note":"Static, unslid symbol. Check runtime ASLR, ABI and version before invoking."
            })

    return {
        "macho_sha256":hashlib.sha256(data).hexdigest(),
        "macho_bytes":len(data),
        "arch":"arm64",
        "uuid":uuid_str,
        "is_encrypted":bool(cryptid),
        "loaded_dylibs":dylibs,
        "sections":sections,
        "matching_objc_strings":interested[:350],
        "matching_static_symbols":symbols[:350],
        "static_symbol_count_matching":len(symbols),
        "static_objc_string_count_matching":len(interested),
        "can_execute_features_from_offsets_alone":False,
        "note":"Symbol and metadata evidence only. No injection/patching or runtime testing.",
    }


def inspect_ipa(path:Path)->dict:
    with zipfile.ZipFile(path) as z:
        paths=set(z.namelist())
        candidates=[]
        for n in paths:
            if n!="Info.plist" and not n.endswith(".app/Info.plist"):continue
            try:info=plistlib.loads(z.read(n))
            except (ValueError,TypeError):continue
            exe=info.get("CFBundleExecutable")
            root=n[:-len("Info.plist")]
            if isinstance(exe,str) and root+exe in paths:
                candidates.append((root,exe,info))
        if len(candidates)!=1:
            raise ValueError(f"Expected exactly one executable; found {len(candidates)}")
        root,exe,info=candidates[0]
        result=parse(z.read(root+exe))
        result["source_ipa_name"]=path.name
        result["app_executable"]=root+exe
        result["bundle_identifier"]=info.get("CFBundleIdentifier")
        result["bundle_version"]=info.get("CFBundleVersion")
        result["bundle_short_version"]=info.get("CFBundleShortVersionString")
        return result


def main()->int:
    args=argparse.ArgumentParser(description=__doc__)
    args.add_argument("ipa",type=Path)
    args.add_argument("--output",type=Path,help="Save JSON diagnostic report")
    opt=args.parse_args()
    try:result=inspect_ipa(opt.ipa)
    except (OSError,ValueError,zipfile.BadZipFile) as e:
        print(json.dumps({"error":str(e)},ensure_ascii=False));return 2
    dump=json.dumps(result,ensure_ascii=False,indent=2)
    if opt.output:
        opt.output.parent.mkdir(parents=True,exist_ok=True)
        opt.output.write_text(dump+"\n",encoding="utf-8")
    else:print(dump)
    return 0


if __name__=="__main__":
    raise SystemExit(main())
