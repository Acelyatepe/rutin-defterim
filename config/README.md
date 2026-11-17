# Dayli reklam ayarları

Kimliklerin tek kaynağı `config/admob.json` dosyasıdır. `use_test_ads: true` iken Google’ın resmi Android/iOS test App ID ve geçiş reklamı (interstitial) kimlikleri kullanılır. Gerçek reklam geliri oluşmaz.

Yayın için JSON içindeki `android_app_id`, `android_interstitial_id`, `ios_app_id`, `ios_interstitial_id` alanlarını doldurup `use_test_ads` değerini `false` yapın. Ardından proje kökünde:

```sh
python3 tool/configure_ads.py
```

Komut Android manifestini, iOS Info.plist dosyasını ve `lib/core/admob_config.dart` dosyasını birlikte günceller. Bu üretilen kimlikleri ayrı ayrı değiştirmeyin. Native App ID değişince uygulama yeniden derlenmelidir; hot reload yeterli değildir. Geliştirmeye dönerken `use_test_ads: true` yapıp komutu yeniden çalıştırın.

SDK yalnızca kullanıcı destek reklamını istediğinde, UMP kontrolü ve `canRequestAds()` sonucundan sonra başlatılır. Her reklam isteğinden önce güncel izin bilgisi istenir; kullanıcı gerekli formu tamamlayabilir. Otomatik reklam, ön yükleme, banner ve ödül yoktur. Hata/bağlantı yokluğu reklamı engeller; planlama özellikleri çalışmayı sürdürür. Ayarlar’daki reklam gizlilik bağlantısı tercihlerin yeniden açılmasını sağlar. Kişiselleştirilmemiş reklam istenir; bu da veri işlemenin veya izin gereksiniminin tamamen ortadan kalktığı anlamına gelmez. iOS’ta ATT/IDFA izni istenmez.

Yayın öncesi AdMob hesabında Android ve iOS uygulamalarını ve interstitial birimlerini oluşturun. **Privacy & messaging** bölümünde hedef bölgeler için gerekli mesajları yapılandırıp yayınlayın; gizlilik politikası URL’nizi tanımlayın. Test App ID’leriyle izin mesajı kullanılamıyorsa izin kontrolü atlanmaz; kendi AdMob uygulama mesajı ve UMP test cihazıyla doğrulayın. Google Play Data Safety ve App Store gizlilik beyanlarını reklam SDK’sının veri işlemesine göre güncelleyin. Uygulama içi kişisel planlama kayıtları reklam isteklerine eklenmez. Gerçek cihazda izin kabul/ret/geri çekme ve reklam kapatma akışlarını yayın öncesi doğrulayın.

Kaynaklar: [Google Flutter kurulumu](https://developers.google.com/admob/flutter/quick-start), [UMP izin yönetimi](https://developers.google.com/admob/flutter/privacy), [iOS yapılandırması](https://developers.google.com/admob/ios/quick-start).
