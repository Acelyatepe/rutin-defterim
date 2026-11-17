import 'package:flutter/material.dart';
import '../../core/widgets/page_layout.dart';
 
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
 
  static const _sections = [
    (
      title: 'Cihazında tutulan kayıtlar',
      text:
          'Rutin Defterim; görev, alışkanlık, su tüketimi ve egzersiz kayıtlarını cihazında yerel olarak saklar. Kullanıcı hesabı veya giriş sistemi bulunmaz. Bu kayıtlar Rutin Defterim tarafından bir kullanıcı hesabına ya da Rutin Defterim sunucusuna aktarılmaz. Günlük planlama özelliklerini internet bağlantısı olmadan kullanabilirsin.',
    ),
    (
      title: 'Yerel bildirimler',
      text:
          'Rutin Defterim, hatırlatmalar için cihazında çalışan yerel bildirimler kullanır. Bildirim iznini cihazının ayarlarından yönetebilirsin. Hatırlatma tercihlerini Rutin Defterim’in Ayarlar bölümünden de değiştirebilirsin.',
    ),
    (
      title: 'İsteğe bağlı reklamlar',
      text:
          'Ayarlar içindeki “Rutin Defterim’i Destekle” bölümünde Google AdMob aracılığıyla isteğe bağlı reklam sunulur. Reklamı açıp açmamak senin seçimindir. Reklam hizmeti internet bağlantısı gerektirir.\n\nReklam gösterimi sırasında Google/AdMob, kendi hizmetleri kapsamında cihaz ve reklam tanımlayıcıları, IP adresi, reklam etkileşimleri ve benzeri teknik verileri işleyebilir. Reklam ve izin hizmetleri bu verileri kendi sunucularına aktarabilir.\n\nRutin Defterim’de tutulan görev, alışkanlık, su tüketimi ve egzersiz kayıtları reklam amacıyla AdMob’a gönderilmez.',
    ),
    (
      title: 'Reklam gizlilik tercihleri',
      text:
          'Google tarafından senin için kullanılabilir bir reklam gizlilik tercihi sunulduğunda, bu tercihlere Ayarlar → Rutin Defterim’i Destekle bölümündeki “Reklam gizlilik tercihleri” alanından erişebilirsin. Sunulan seçenekler bölgeye ve Google’ın hizmetlerine göre değişebilir.',
    ),
    (
      title: 'Kullanım analizi',
      text:
          'Rutin Defterim’in kendi analiz veya takip sistemi yoktur. Reklam gösterilirken Google AdMob, kendi hizmetleri kapsamında teknik veri işleyebilir.',
    ),
    (
      title: 'Uygulamayı kaldırma',
      text:
          'Uygulamayı kaldırdığında Rutin Defterim’in cihazında tuttuğu yerel kayıtlar silinebilir. Bu kayıtlar bir Rutin Defterim hesabında veya Rutin Defterim sunucusunda saklanmadığından, böyle bir hesap ya da sunucu üzerinden geri yüklenmez. Uygulamayı kaldırmak, Google/AdMob’un kendi hizmetleri kapsamında işlediği verilerin silindiği anlamına gelmez.',
    ),
    (
      title: 'İletişim',
      // DİKKAT: Aşağıdaki e-posta adresini kendi adresinle değiştir.
      text:
          'Gizlilik politikasıyla ilgili sorularını şu adrese yazabilirsin: aclysde@gmail.com',
    ),
  ];
 
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Gizlilik Politikası')),
    body: SafeArea(
      child: SelectionArea(
        child: PageLayout(
          children: [
            const Text(
              'Rutin Defterim’de kayıtlarının nasıl saklandığını ve reklam hizmetlerinin hangi verileri işleyebileceğini burada bulabilirsin.',
            ),
            const SizedBox(height: 20),
            for (final section in _sections) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(section.text),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text('Son güncelleme: Ekim 2026'),
          ],
        ),
      ),
    ),
  );
}
 