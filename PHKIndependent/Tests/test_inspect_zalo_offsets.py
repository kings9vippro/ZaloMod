import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path

tool=Path(__file__).resolve().parents[1]/"Tools"/"inspect_zalo_offsets.py"
spec=importlib.util.spec_from_file_location("inspect_zalo_offsets",tool)
scan=importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan)

def make_macho():
    base=0x100000000
    classes=b"KBChatInputComponentView\0Unrelated\0"
    methods=b"setTextColor:\0setFont:\0unknown\0"
    seg=struct.pack("<II16sQQQQiiII",
        0x19,72+160,b"__TEXT",base,4096,0,1024,7,5,2,0)
    sec1=struct.pack("<16s16sQQIIIIIIII",b"__objc_classname",b"__TEXT",
                     base+512,len(classes),512,2,0,0,0,0,0,0)
    sec2=struct.pack("<16s16sQQIIIIIIII",b"__objc_methname",b"__TEXT",
                     base+560,len(methods),560,2,0,0,0,0,0,0)
    uuid=struct.pack("<II",0x1B,24)+bytes(range(16))
    strings=b"\0_OBJC_CLASS_$_KBChatInputComponentView\0"
    symoff=616
    stroff=640
    symcmd=struct.pack("<6I",2,24,symoff,1,stroff,len(strings))
    cmds=seg+sec1+sec2+uuid+symcmd
    header=struct.pack("<IiiIIIII",0xFEEDFACF,0x0100000C,0,2,3,len(cmds),0,0)
    data=bytearray((header+cmds).ljust(1024,b"\0"))
    data[512:512+len(classes)]=classes
    data[560:560+len(methods)]=methods
    struct.pack_into("<IBBHQ",data,symoff,1,0x0F,1,0,base+512)
    data[stroff:stroff+len(strings)]=strings
    return bytes(data)

class OffsetScannerTest(unittest.TestCase):
    def test_identifies_version_pin_and_strings(self):
        report=scan.parse(make_macho())
        self.assertEqual(report["arch"],"arm64")
        self.assertFalse(report["is_encrypted"])
        self.assertEqual(len(report["matching_static_symbols"]),1)
        self.assertEqual(report["matching_static_symbols"][0]["rva_from_TEXT"],"0x200")
        names={x["value"] for x in report["matching_objc_strings"]}
        self.assertIn("KBChatInputComponentView",names)
        self.assertIn("setTextColor:",names)
        self.assertFalse(report["can_execute_features_from_offsets_alone"])
    def test_rejects_truncation(self):
        with self.assertRaises(ValueError):scan.parse(b"\x00")
    def test_rejects_invalid_section_offsets(self):
        data=bytearray(make_macho())
        # First class section file offset, 48 bytes into section record.
        struct.pack_into("<I",data,32+72+48,0xFFFFFF00)
        with self.assertRaises(ValueError):scan.parse(bytes(data))

if __name__=="__main__":
    unittest.main()
