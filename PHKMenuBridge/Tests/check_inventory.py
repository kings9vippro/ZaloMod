import json
from pathlib import Path
p=Path(__file__).resolve().parents[1]
i=json.loads((p/'docs/inventory.json').read_text())
objc=(p/'Sources/PHKLegacyAdapter.mm').read_text()
view=(p/'Sources/PHKOverlayController.mm').read_text()
assert len(i['toggle_mappings'])==13
for mapping in i['toggle_mappings']:
    assert mapping['toggle'] in objc and mapping['toggle'] in view
    assert mapping['reader'] in objc and mapping['reader'] in view
    assert mapping['toggle_address'] and mapping['reader_address']
assert 'actionExportBotConfig' not in objc and 'actionExportBotConfig' not in view
assert 'NSHTTPCookieStorage' not in objc + view
assert 'fourFingerTapped' in (p/'Sources/PHKOverlayBootstrap.mm').read_text()
print('PASS: all 13 old toggle controls mapped, export excluded, four-finger trigger present')
