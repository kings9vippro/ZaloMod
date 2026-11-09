#!/usr/bin/env python3
"""Validate independent first-party test IPA and Mach-O load command; does not attest code signing."""
import argparse
import json
import plistlib
import struct
from zipfile import ZipFile

def inspect(archive):
    with ZipFile(archive) as z:
        error=z.testzip()
        if error: raise ValueError(f'CRC failed: {error}')
        names=set(z.namelist())
        base='Payload/PHKHost.app/'
        info=plistlib.loads(z.read(base+'Info.plist'))
        assert info['CFBundleExecutable']=='PHKHost'
        assert base+'Frameworks/PHKStandalone.dylib' in names
        main=z.read(base+'PHKHost')
        if len(main)<32: raise ValueError('Mach-O header truncated')
        magic,cpu,subtype,filetype,ncmds,sizecmds,flags,reserved=struct.unpack_from('<8I',main)
        assert magic==0xFEEDFACF and cpu==0x0100000C and filetype==2
        off=32;found=[]
        for _ in range(ncmds):
            cmd,size=struct.unpack_from('<II',main,off)
            if size<8 or off+size>32+sizecmds or 32+sizecmds>len(main):
                raise ValueError('invalid Mach-O load commands')
            if cmd&0x7FFFFFFF in (0xC,0x18,0x1F,0x23):
                index=struct.unpack_from('<I',main,off+8)[0]
                if index>=size: raise ValueError('invalid Mach-O library path')
                found.append(main[off+index:off+size].split(b'\0')[0].decode('utf8'))
            off+=size
        expect='@rpath/PHKStandalone.dylib'
        assert expect in found, f'host missing load command: {found}'
        return dict(archive=str(archive),bundle_id=info['CFBundleIdentifier'],files=len(names),crc='ok',
                    cpu='arm64',dylib=expect,linked=True,signing='unsigned',runtime_test='not performed',
                    note='This is an independent test host, not a Zalo replacement.')
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('ipa')
    arguments=parser.parse_args()
    print(json.dumps(inspect(arguments.ipa),ensure_ascii=False,indent=2))
