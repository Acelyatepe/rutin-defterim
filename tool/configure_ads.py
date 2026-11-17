"""Dayli reklam kimliklerini tek yapılandırmadan platformlara aktarır."""
import json
import plistlib
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
config = json.loads((root / 'config/admob.json').read_text())
test = config['use_test_ads']
assert isinstance(test, bool), 'use_test_ads true veya false olmalı.'
ids = {
    'android_app_id': 'ca-app-pub-3940256099942544~3347511713',
    'android_interstitial_id': 'ca-app-pub-3940256099942544/1033173712',
    'ios_app_id': 'ca-app-pub-3940256099942544~1458002511',
    'ios_interstitial_id': 'ca-app-pub-3940256099942544/4411468910',
} if test else config
for key in ['android_app_id', 'android_interstitial_id', 'ios_app_id', 'ios_interstitial_id']:
    separator = '~' if key.endswith('app_id') else '/'
    assert re.fullmatch(r'ca-app-pub-\d{16}' + separator + r'\d{10}', ids[key]), f'{key} geçersiz.'
    assert test or '3940256099942544' not in ids[key], 'Canlı modda test kimliği kullanılamaz.'

manifest = root / 'android/app/src/main/AndroidManifest.xml'
s = manifest.read_text()
entry = f'<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="{ids["android_app_id"]}" />'
pattern = r'<meta-data\s+android:name="com.google.android.gms.ads.APPLICATION_ID"\s+android:value="[^"]*"\s*/>'
s = re.sub(pattern, lambda _: entry, s) if re.search(pattern, s) else s.replace('        <activity', '        ' + entry + '\n        <activity', 1)
manifest.write_text(s)
plist = root / 'ios/Runner/Info.plist'
p = plistlib.loads(plist.read_bytes())
p['GADApplicationIdentifier'] = ids['ios_app_id']
plist.write_bytes(plistlib.dumps(p, sort_keys=False))
(root / 'lib/core/admob_config.dart').write_text(
    '// config/admob.json üzerinden tool/configure_ads.py ile oluşturulur.\n'
    'abstract final class AdmobConfig {\n'
    f'  static const useTestAds = {str(test).lower()};\n'
    f"  static const androidInterstitial = '{ids['android_interstitial_id']}';\n"
    f"  static const iosInterstitial = '{ids['ios_interstitial_id']}';\n"
    '}\n'
)
print('Dayli reklam yapılandırması güncellendi: ' + ('test' if test else 'canlı'))
