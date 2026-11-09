#!/usr/bin/env python3
"""Inspect iOS IPA packaging without modifying, executing or signing binaries."""
from __future__ import annotations
import argparse
import json
import plistlib
import struct
import sys
from pathlib import Path
from zipfile import ZipFile, BadZipFile

MACHO64_LE = 0xFEEDFACF
CPU_ARM64 = 0x0100000C
LOAD_DYLIB_COMMANDS = {0xC, 0x18, 0x1F, 0x23}

def dylib_loads(macho: bytes) -> dict:
    if len(macho) < 32:
        raise ValueError('Mach-O header truncated')
    magic, cpu, subtype, filetype, commands, length, flags, reserved = struct.unpack_from('<8I', macho)
    if magic != MACHO64_LE:
        raise ValueError('expected little-endian Mach-O 64 (thin ARM64)')
    if cpu != CPU_ARM64:
        raise ValueError('expected ARM64 executable')
    end = 32 + length
    if end > len(macho):
        raise ValueError('Mach-O load commands truncated')
    names = []
    offset = 32
    for _ in range(commands):
        if offset + 8 > end:
            raise ValueError('Mach-O load command header truncated')
        cmd, size = struct.unpack_from('<II', macho, offset)
        if size < 8 or offset + size > end:
            raise ValueError('invalid Mach-O load command bounds')
        if (cmd & 0x7FFFFFFF) in LOAD_DYLIB_COMMANDS:
            if size < 24:
                raise ValueError('invalid dylib command')
            name_offset, = struct.unpack_from('<I', macho, offset + 8)
            if name_offset < 24 or name_offset >= size:
                raise ValueError('invalid dylib name offset')
            name_start = offset + name_offset
            name_end = macho.find(b'\0', name_start, offset + size)
            if name_end < 0:
                raise ValueError('unterminated dylib name')
            names.append(macho[name_start:name_end].decode('utf-8', 'replace'))
        offset += size
    return {'cpu': 'arm64', 'filetype': filetype, 'dylib_loads': names}

def inspect_ipa(ipa: Path, check_crc: bool = False) -> dict:
    with ZipFile(ipa) as z:
        members = set(z.namelist())
        plists = sorted(x for x in members if x.startswith('Payload/') and x.count('/') == 2 and x.endswith('.app/Info.plist'))
        if len(plists) != 1:
            raise ValueError(f'expected one root .app Info.plist, found {len(plists)}')
        root = plists[0][:-len('Info.plist')]
        info = plistlib.loads(z.read(plists[0]))
        executable = info.get('CFBundleExecutable')
        if not isinstance(executable, str) or not executable:
            raise ValueError('missing CFBundleExecutable in Info.plist')
        exe = root + executable
        if exe not in members:
            raise ValueError(f'IPA does not contain declared executable {exe}')
        loaded = dylib_loads(z.read(exe))['dylib_loads']
        report = {'ipa': ipa.name, 'root': root, 'executable': executable,
                  'files': len(members), 'dylibs': {}}
        for name in ('PHKMenuBridge.dylib', 'ZaloModVIP.dylib'):
            present = root + 'Frameworks/' + name in members
            linked = any(load.rsplit('/', 1)[-1] == name for load in loaded)
            report['dylibs'][name] = {'present': present, 'lc_load_dylib': linked}
        report['resources'] = {x: root + 'Frameworks/PHKMenuResources.bundle/' + x in members
                               for x in ('AdminCar.jpg', 'MenuWallpaper.jpg')}
        report['crc'] = 'not_checked'
        if check_crc:
            bad = z.testzip()
            report['crc'] = 'ok' if bad is None else f'corrupt: {bad}'
        bridge = report['dylibs']['PHKMenuBridge.dylib']
        legacy = report['dylibs']['ZaloModVIP.dylib']
        report['ready_for_runtime_test'] = (bridge['present'] and bridge['lc_load_dylib'] and
                                            legacy['present'] and legacy['lc_load_dylib'] and
                                            all(report['resources'].values()) and
                                            not report['crc'].startswith('corrupt'))
        report['note'] = 'Structural check only; runtime behavior, Apple code signature and server effects are not verified.'
        return report

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ipa', type=Path)
    parser.add_argument('--crc', action='store_true', help='verify every ZIP member')
    args = parser.parse_args()
    try:
        report = inspect_ipa(args.ipa, args.crc)
    except (BadZipFile, OSError, ValueError, KeyError, struct.error) as e:
        print(json.dumps({'error': str(e)}, ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if report['ready_for_runtime_test'] else 1

if __name__ == '__main__':
    sys.exit(main())
