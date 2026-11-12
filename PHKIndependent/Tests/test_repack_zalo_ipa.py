"""Synthetic Mach-O and IPA tests. Never downloads or stores a third-party app."""
from __future__ import annotations

import importlib.util
import plistlib
import struct
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

SCRIPT = Path(__file__).resolve().parents[1] / "Tools" / "repack_zalo_ipa.py"
SPEC = importlib.util.spec_from_file_location("repack_zalo_ipa", SCRIPT)
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


def dylib_command(name: str) -> bytes:
    encoded = name.encode() + b"\0"
    cmdsize = (24 + len(encoded) + 7) & ~7
    return struct.pack("<6I", 0xC, cmdsize, 24, 2, 0x10000, 0x10000) + encoded.ljust(cmdsize - 24, b"\0")


def executable(with_legacy: bool = False, first_section: int = 512) -> bytes:
    segment = struct.pack("<II16sQQQQiiII", 0x19, 152, b"__TEXT", 0, 0x1000, 0, 0x1000, 7, 5, 1, 0)
    section = struct.pack("<16s16sQQIIIIIIII", b"__text", b"__TEXT", 0x100, 0x20,
                          first_section, 2, 0, 0, 0, 0, 0, 0)
    commands = segment + section
    if with_legacy:
        commands += dylib_command("@executable_path/Frameworks/ZaloModVIP.dylib")
    header = struct.pack("<IiiIIIII", 0xFEEDFACF, 0x0100000C, 0, 2,
                         2 if with_legacy else 1, len(commands), 0, 0)
    body = header + commands
    assert len(body) < first_section
    return body.ljust(first_section, b"\0") + b"\x90" * 64


def dylib() -> bytes:
    return struct.pack("<IiiIIIII", 0xFEEDFACF, 0x0100000C, 0, 6, 0, 0, 0, 0)


def make_source(path: Path, *, raw: bool = True, with_legacy: bool = False) -> None:
    root = "" if raw else "Payload/Zalo.app/"
    info = {
        "CFBundleExecutable": "Zalo",
        "CFBundleIdentifier": "vn.example.zalo.test",
        "CFBundleDisplayName": "Zalo",
    }
    with ZipFile(path, "w") as archive:
        archive.writestr(root + "Info.plist", plistlib.dumps(info))
        archive.writestr(root + "Zalo", executable(with_legacy))
        archive.writestr(root + "Assets.car", b"kept-unaltered")
        if with_legacy:
            archive.writestr(root + "Frameworks/ZaloModVIP.dylib", b"fake legacy")


class RepackageTests(unittest.TestCase):
    def test_patch_load_command_preserves_code_section(self):
        source = executable()
        rebuilt, inserted = mod.inject_load_command(source)
        self.assertTrue(inserted)
        self.assertEqual(rebuilt[512:], source[512:])
        self.assertIn((mod.PHK_LIBRARY, False), mod.loaded_libraries(rebuilt))
        repeated, new = mod.inject_load_command(rebuilt)
        self.assertFalse(new)
        self.assertEqual(repeated, rebuilt)

    def test_patch_fails_when_slack_is_too_short(self):
        original = executable(first_section=225)
        with self.assertRaisesRegex(ValueError, "padding"):
            mod.inject_load_command(original)

    def test_build_real_app_shape_from_raw_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "original.zip"
            target = root / "patched.ipa"
            library = root / "PHKIndependent.dylib"
            wallpaper = root / "wallpaper.jpg"
            make_source(source, raw=True)
            library.write_bytes(dylib())
            wallpaper.write_bytes(b"\xFF\xD8\xFFfakejpeg")
            report = mod.package(source, library, target, wallpaper=wallpaper)
            self.assertTrue(report["load_command_inserted"])
            self.assertFalse(report["legacy_strong_dependency"])
            with ZipFile(target) as z:
                self.assertIsNone(z.testzip())
                self.assertEqual(z.read("Payload/Zalo.app/Assets.car"), b"kept-unaltered")
                self.assertEqual(z.read("Payload/Zalo.app/PHKBrandPhoto.jpg"), wallpaper.read_bytes())
                info = plistlib.loads(z.read("Payload/Zalo.app/Info.plist"))
                self.assertEqual(info["CFBundleIdentifier"], "vn.example.zalo.test")
                self.assertEqual(info["CFBundleDisplayName"], "Zalo PHK")
                self.assertIn((mod.PHK_LIBRARY, False),
                              mod.loaded_libraries(z.read("Payload/Zalo.app/Zalo")))

    def test_standard_ipa_retains_legacy_dependency_when_present(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, out, lib = root / "existing.ipa", root / "new.ipa", root / "lib.dylib"
            make_source(source, raw=False, with_legacy=True)
            lib.write_bytes(dylib())
            report = mod.package(source, lib, out)
            self.assertTrue(report["legacy_strong_dependency"])
            with ZipFile(out) as z:
                self.assertIn("Payload/Zalo.app/Frameworks/ZaloModVIP.dylib", z.namelist())

    def test_independent_mode_rejects_legacy_binary(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, out, lib = root / "input.zip", root / "output.ipa", root / "lib.dylib"
            make_source(source, with_legacy=True)
            lib.write_bytes(dylib())
            with self.assertRaisesRegex(ValueError, "strongly loads"):
                mod.package(source, lib, out, require_independent=True)
            self.assertFalse(out.exists())

    def test_rejects_absent_legacy_dylib(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source, out, lib = root / "bad.zip", root / "output.ipa", root / "lib.dylib"
            make_source(source, with_legacy=True)
            lib.write_bytes(dylib())
            # Rewrite the ZIP without Frameworks/ZaloModVIP.dylib.
            with ZipFile(source) as z:
                records = [(name, z.read(name)) for name in z.namelist()
                           if "ZaloModVIP" not in name]
            with ZipFile(source, "w") as z:
                for name, content in records:
                    z.writestr(name, content)
            with self.assertRaisesRegex(ValueError, "missing strong dylib"):
                mod.package(source, lib, out)


if __name__ == "__main__":
    unittest.main()
