#!/usr/bin/env python3
"""Repackage a user-supplied *decrypted* iOS .app ZIP / IPA with PHKIndependent.

This modifies only the supplied archive copy. No App Store download, DRM
circumvention, signing, original Zalo API emulation or legacy-hook recreation.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import plistlib
import re
import struct
import sys
import zipfile
from pathlib import Path

MH_MAGIC_64 = 0xFEEDFACF
CPU_TYPE_ARM64 = 0x0100000C
MH_EXECUTE = 2
MH_DYLIB = 6
LC_LOAD_DYLIB = 0xC
LC_LOAD_WEAK_DYLIB = 0x18
LC_SEGMENT_64 = 0x19
LC_ENCRYPTION_INFO_64 = 0x2C
LOAD_COMMANDS = {0xC, 0x18, 0x1F, 0x23, 0x20}
PHK_LIBRARY = "@executable_path/Frameworks/PHKIndependent.dylib"


def _header(data: bytes, kind: int) -> tuple[int, int]:
    if len(data) < 32:
        raise ValueError("Mach-O file is truncated.")
    magic, cpu, _subtype, filetype, ncmds, sizeofcmds, _flags, _reserved = (
        struct.unpack_from("<IiiIIIII", data)
    )
    if magic != MH_MAGIC_64 or cpu != CPU_TYPE_ARM64 or filetype != kind:
        raise ValueError("Input must be a thin, decrypted ARM64 Mach-O of the expected type.")
    if ncmds > 4096 or sizeofcmds > len(data) - 32:
        raise ValueError("Mach-O load-command table is invalid.")
    return ncmds, sizeofcmds


def _commands(data: bytes, kind: int):
    ncmds, sizeofcmds = _header(data, kind)
    end = 32 + sizeofcmds
    pos = 32
    for _ in range(ncmds):
        if pos + 8 > end:
            raise ValueError("Truncated Mach-O load command.")
        cmd, cmdsize = struct.unpack_from("<II", data, pos)
        if cmdsize < 8 or cmdsize % 8 or pos + cmdsize > end:
            raise ValueError("Invalid Mach-O load-command size.")
        yield cmd, pos, cmdsize
        pos += cmdsize
    if pos != end:
        raise ValueError("Mach-O command count/size mismatch.")


def loaded_libraries(data: bytes) -> list[tuple[str, bool]]:
    result = []
    for cmd, pos, cmdsize in _commands(data, MH_EXECUTE):
        raw = cmd & 0x7FFFFFFF
        if raw not in LOAD_COMMANDS:
            continue
        if cmdsize < 24:
            raise ValueError("Truncated dylib load command.")
        name_offset = struct.unpack_from("<I", data, pos + 8)[0]
        if not 24 <= name_offset < cmdsize:
            raise ValueError("Invalid Mach-O dylib name.")
        name = data[pos + name_offset:pos + cmdsize].split(b"\0", 1)[0]
        result.append((name.decode("utf-8", "strict"), raw == LC_LOAD_WEAK_DYLIB))
    return result


def inject_load_command(executable: bytes) -> tuple[bytes, bool]:
    """Insert LC_LOAD_DYLIB only into confirmed zero load-command slack.

    Never blindly overwrite a section or guess function offsets.
    """
    ncmds, sizeofcmds = _header(executable, MH_EXECUTE)
    already = [name for name, _weak in loaded_libraries(executable)]
    if any(name.endswith("/PHKIndependent.dylib") for name in already):
        return executable, False

    first_section = len(executable)
    for cmd, pos, cmdsize in _commands(executable, MH_EXECUTE):
        raw = cmd & 0x7FFFFFFF
        if raw == LC_ENCRYPTION_INFO_64:
            if cmdsize < 24:
                raise ValueError("Malformed encryption-info load command.")
            cryptid = struct.unpack_from("<I", executable, pos + 16)[0]
            if cryptid:
                raise ValueError("Encrypted App Store IPA cannot be repacked; use a permitted decrypted archive.")
        if raw == LC_SEGMENT_64:
            if cmdsize < 72:
                raise ValueError("Malformed LC_SEGMENT_64.")
            nsects = struct.unpack_from("<I", executable, pos + 64)[0]
            if 72 + 80 * nsects > cmdsize:
                raise ValueError("Invalid Mach-O section table.")
            for i in range(nsects):
                section = pos + 72 + 80 * i
                size = struct.unpack_from("<Q", executable, section + 40)[0]
                offset = struct.unpack_from("<I", executable, section + 48)[0]
                if size and offset:
                    first_section = min(first_section, offset)

    text = PHK_LIBRARY.encode("utf-8") + b"\0"
    cmdsize = (24 + len(text) + 7) & ~7
    end = 32 + sizeofcmds
    if end + cmdsize > first_section or end + cmdsize > len(executable):
        raise ValueError("No safe load-command padding. Do not overwrite executable sections.")
    if any(executable[end:end + cmdsize]):
        raise ValueError("Mach-O load-command padding is not zero; refusing unsafe patch.")
    command = (
        struct.pack("<6I", LC_LOAD_DYLIB, cmdsize, 24, 2, 0x10000, 0x10000)
        + text.ljust(cmdsize - 24, b"\0")
    )
    modified = bytearray(executable)
    modified[end:end + cmdsize] = command
    struct.pack_into("<II", modified, 16, ncmds + 1, sizeofcmds + cmdsize)
    verified = loaded_libraries(modified)
    if (PHK_LIBRARY, False) not in verified:
        raise ValueError("Inserted PHKIndependent LC_LOAD_DYLIB could not be verified.")
    return bytes(modified), True


def _find_app(archive: zipfile.ZipFile) -> tuple[str, str, dict]:
    files = set(archive.namelist())
    matches = []
    for filename in sorted(files):
        if filename == "Info.plist" or filename.endswith(".app/Info.plist"):
            root = filename[:-len("Info.plist")]
            try:
                info = plistlib.loads(archive.read(filename))
            except (ValueError, TypeError, plistlib.InvalidFileException):
                continue
            exe = info.get("CFBundleExecutable")
            if isinstance(exe, str) and root + exe in files:
                matches.append((root, exe, info))
    if len(matches) != 1:
        raise ValueError("Expected exactly one app executable and Info.plist; found %d" % len(matches))
    return matches[0]


def _safe_name(name: str) -> str:
    if not name or not re.fullmatch(r"[A-Za-z0-9._ -]+", name):
        raise ValueError("Unsafe ZIP app filename: %r" % name)
    return name


def package(
    source: Path,
    dylib: Path,
    output: Path,
    *,
    display_name: str | None = "Zalo PHK",
    wallpaper: Path | None = None,
    admin_photo: Path | None = None,
    require_independent: bool = False,
    check_crc: bool = True,
) -> dict:
    if source.resolve() == output.resolve():
        raise ValueError("Never overwrite the source IPA.")
    lib = dylib.read_bytes()
    _header(lib, MH_DYLIB)
    if not lib.startswith(b"\xCF\xFA\xED\xFE"):
        raise ValueError("PHKIndependent.dylib must be a real ARM64 Mach-O dylib.")

    with zipfile.ZipFile(source, "r", allowZip64=True) as input_zip:
        root, executable, info = _find_app(input_zip)
        raw_main = input_zip.read(root + executable)
        old_dependencies = loaded_libraries(raw_main)
        independent = not any(
            name.endswith("/ZaloModVIP.dylib") and not weak
            for name, weak in old_dependencies
        )
        if require_independent and not independent:
            raise ValueError(
                "This source still strongly loads ZaloModVIP.dylib. Removing it "
                "would crash before PHK loads; use an independent host IPA."
            )
        original_files = set(input_zip.namelist())
        for name, weak in old_dependencies:
            if not weak and name.startswith("@executable_path/Frameworks/"):
                member = root + name.removeprefix("@executable_path/")
                if name.endswith("/PHKIndependent.dylib"):
                    continue  # replaced below
                if member not in original_files:
                    raise ValueError("Existing IPA has a missing strong dylib: " + name)

        patched, new_command = inject_load_command(raw_main)
        app_name = root.split("/")[-2] if root.endswith(".app/") else "Zalo.app"
        app_name = _safe_name(app_name)
        target_root = "Payload/" + app_name + "/"
        target_exe = target_root + executable
        info["CFBundleDisplayName"] = display_name or info.get("CFBundleDisplayName", "Zalo")
        plist_data = plistlib.dumps(info, fmt=plistlib.FMT_BINARY)

        overwritten = {
            target_root + "Frameworks/PHKIndependent.dylib": lib,
            target_root + "Info.plist": plist_data,
            target_exe: patched,
        }
        if wallpaper is not None:
            photo = wallpaper.read_bytes()
            if len(photo) > 8 * 1024 * 1024:
                raise ValueError("Wallpaper exceeds 8 MiB.")
            overwritten[target_root + "PHKBrandPhoto.jpg"] = photo
        if admin_photo is not None:
            photo = admin_photo.read_bytes()
            if len(photo) > 8 * 1024 * 1024:
                raise ValueError("Admin photo exceeds 8 MiB.")
            overwritten[target_root + "PHKAdminCar.jpg"] = photo

        seen = set()
        output.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as out:
            for item in input_zip.infolist():
                if item.filename.startswith(("/", "\\")):
                    raise ValueError("Unsafe absolute ZIP path.")
                if ".." in item.filename.replace("\\", "/").split("/"):
                    raise ValueError("Archive contains path traversal.")
                name = target_root + item.filename[len(root):] if root and item.filename.startswith(root) else (
                    target_root + item.filename if not root else item.filename
                )
                if name in seen:
                    raise ValueError("Duplicate ZIP member after normalization: " + name)
                seen.add(name)
                if name in overwritten:
                    data = overwritten.pop(name)
                else:
                    data = input_zip.read(item)
                copy_info = copy.copy(item)
                copy_info.filename = name
                out.writestr(copy_info, data)
            for name, data in overwritten.items():
                if name in seen:
                    raise ValueError("Unexpected duplicate generated ZIP member: " + name)
                out.writestr(name, data)

    with zipfile.ZipFile(output) as verified_zip:
        corruption = verified_zip.testzip() if check_crc else None
        if corruption:
            raise ValueError("ZIP CRC failed: " + corruption)
        entries = set(verified_zip.namelist())
        if target_exe not in entries:
            raise ValueError("Output executable missing.")
        if target_root + "Frameworks/PHKIndependent.dylib" not in entries:
            raise ValueError("Output PHK library missing.")
        main = verified_zip.read(target_exe)
        if PHK_LIBRARY not in [x[0] for x in loaded_libraries(main)]:
            raise ValueError("Final executable has no PHK load command.")

    return {
        "source": str(source),
        "output": str(output),
        "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "bytes": output.stat().st_size,
        "app_bundle": target_root,
        "load_command_inserted": new_command,
        "legacy_strong_dependency": not independent,
        "phk_dylib_embedded": True,
        "crc_checked": check_crc,
        "signed": False,
        "device_tested": False,
        "note": "Unsigned IPA built from supplied app archive; re-sign before installation. UI and Zalo features are not runtime verified.",
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--source", required=True, type=Path, help="Existing permitted decrypted IPA or .app ZIP")
    p.add_argument("--dylib", required=True, type=Path, help="Built PHKIndependent.dylib")
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--display-name", default="Zalo PHK")
    p.add_argument("--wallpaper", type=Path)
    p.add_argument("--admin-photo", type=Path)
    p.add_argument("--require-independent", action="store_true")
    p.add_argument("--skip-crc", action="store_true", help="Only for development; final builds should verify CRC.")
    args = p.parse_args()
    try:
        report = package(
            args.source, args.dylib, args.output,
            display_name=args.display_name,
            wallpaper=args.wallpaper,
            admin_photo=args.admin_photo,
            require_independent=args.require_independent,
            check_crc=not args.skip_crc,
        )
    except (OSError, ValueError, zipfile.BadZipFile) as e:
        print(json.dumps({"error": str(e)}, ensure_ascii=False), file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
