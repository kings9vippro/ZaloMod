import importlib.util,plistlib,struct,tempfile,unittest
from pathlib import Path
from zipfile import ZipFile
tool=Path(__file__).resolve().parents[1]/"Tools"/"diagnose_ipa.py"
spec=importlib.util.spec_from_file_location("diagnose_ipa",tool)
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
def macho():
    text=b"@executable_path/Frameworks/ZaloModVIP.dylib\0"
    size=(24+len(text)+7)&~7
    cmd=struct.pack("<6I",0xC,size,24,0,0,0)+text+b"\0"*(size-24-len(text))
    return struct.pack("<IiiIIIII",0xFEEDFACF,0x0100000C,0,2,1,len(cmd),0,0)+cmd
class DiagnoserTests(unittest.TestCase):
    def fixture(self,p,with_original):
        with ZipFile(p,"w") as z:
            z.writestr("Payload/Zalo.app/Info.plist",plistlib.dumps({"CFBundleExecutable":"Zalo"}))
            z.writestr("Payload/Zalo.app/Zalo",macho())
            if with_original:z.writestr("Payload/Zalo.app/Frameworks/ZaloModVIP.dylib",b"binary")
    def test_missing_dependency(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"missing.ipa";self.fixture(p,False)
            result=module.inspect(p,True)
            self.assertTrue(result["strongly_links_old_zalomod"])
            self.assertEqual(len(result["missing_strong_dependencies"]),1)
            self.assertFalse(result["structurally_complete"])
    def test_present_dependency(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/"ok.ipa";self.fixture(p,True)
            result=module.inspect(p,True)
            self.assertEqual(result["zip_crc"],"ok")
            self.assertTrue(result["structurally_complete"])
    def test_bad(self):
        with self.assertRaises(ValueError):module.linked(b"bad")
if __name__=="__main__":unittest.main()
