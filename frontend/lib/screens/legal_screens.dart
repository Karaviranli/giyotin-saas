import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
//  Shared legal page scaffold
// ─────────────────────────────────────────────────────────────────

class _LegalPage extends StatelessWidget {
  final String title;
  final String content;
  const _LegalPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Navigator.canPop(context)
            ? const BackButton()
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'kavira.online | kavirasoftware@gmail.com',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 32),
                Text(
                  content,
                  style: const TextStyle(fontSize: 15, height: 1.8),
                ),
                const SizedBox(height: 64),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/terms'),
                      child: const Text('Kullanıcı Sözleşmesi'),
                    ),
                    const Text('·'),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/privacy'),
                      child: const Text('Gizlilik Politikası'),
                    ),
                    const Text('·'),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/refund'),
                      child: const Text('İade Politikası'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Terms of Service
// ─────────────────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(title: 'Kullanıcı Sözleşmesi', content: _kTerms);
  }
}

// ─────────────────────────────────────────────────────────────────
//  Privacy Policy
// ─────────────────────────────────────────────────────────────────

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(title: 'Gizlilik Politikası', content: _kPrivacy);
  }
}

// ─────────────────────────────────────────────────────────────────
//  Refund Policy
// ─────────────────────────────────────────────────────────────────

class RefundScreen extends StatelessWidget {
  const RefundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(title: 'İade Politikası', content: _kRefund);
  }
}

// ─────────────────────────────────────────────────────────────────
//  Legal content
// ─────────────────────────────────────────────────────────────────

const _kTerms = '''
Son güncelleme: Mayıs 2026

1. TARAFLAR

Bu Kullanıcı Sözleşmesi ("Sözleşme"), Kavira Software ("Şirket", "biz") ile Kavira SaaS platformuna ("Platform") kayıt olan bireysel kullanıcı veya kuruluş ("Kullanıcı") arasında akdedilmiştir. Platforma kayıt olarak veya kullanmaya başlayarak bu Sözleşmeyi kabul etmiş sayılırsınız.

2. HİZMET TANIMI

Kavira SaaS, giyotin cam sistemi üretim hesaplamaları, maliyet analizi, kesim planı oluşturma ve proje yönetimi hizmetleri sunan bir yazılım abonelik platformudur. Şirket, önceden bildirmeksizin hizmetlerde değişiklik yapma hakkını saklı tutar.

3. HESAP OLUŞTURMA VE GÜVENLİK

Platforma erişim için geçerli bir e-posta adresi ve şifre ile hesap oluşturmanız gerekmektedir. Kullanıcı, hesap bilgilerinin gizliliğinden ve hesap üzerinden gerçekleştirilen tüm işlemlerden sorumludur. Yetkisiz erişim şüphesi durumunda derhal kavirasoftware@gmail.com adresine bildirimde bulunulmalıdır.

4. ABONELİK VE ÖDEME

4.1 Abonelik planları aylık faturalandırma döngüsüyle sunulmaktadır.
4.2 Ödemeler, Paddle Inc. ödeme altyapısı üzerinden güvenli biçimde tahsil edilir.
4.3 Deneme süresi sona erdikten sonra seçilen plan ücreti otomatik olarak tahsil edilir.
4.4 Abonelik yenileme, mevcut dönem sona ermeden önce gerçekleştirilir.
4.5 Ödeme başarısız olması halinde hesap erişimi askıya alınabilir.

5. İPTAL

Kullanıcı istediği zaman aboneliğini iptal edebilir. İptal, bir sonraki faturalama döneminden itibaren geçerli olur. Mevcut dönem sona erene kadar platforma erişim devam eder. İade koşulları için İade Politikamıza bakınız.

6. KULLANIM KURALLARI

Kullanıcı, Platformu yalnızca yasal ve meşru amaçlarla kullanmayı kabul eder. Aşağıdaki eylemler kesinlikle yasaktır:
• Platformun güvenliğini tehdit eden faaliyetler
• Başkalarının hesaplarına yetkisiz erişim girişimleri
• Platformun tersine mühendislik, kaynak kod çıkarma veya kopyalama
• Üçüncü tarafların haklarını ihlal eden içerik paylaşımı

7. FİKRİ MÜLKİYET

Platform, yazılım, algoritmalar, arayüz tasarımı ve tüm içerikler Kavira Software'e aittir ve Türk Fikir ve Sanat Eserleri Kanunu kapsamında korunmaktadır. Kullanıcıya yalnızca kişisel, devredilemez ve münhasır olmayan bir kullanım lisansı verilmektedir.

8. VERİ GİZLİLİĞİ

Kişisel verileriniz, Gizlilik Politikamız ve 6698 Sayılı Kişisel Verilerin Korunması Kanunu (KVKK) kapsamında işlenmektedir.

9. GARANTİ REDDİ

Platform "olduğu gibi" sunulmaktadır. Şirket, belirli bir amaca uygunluk, kesintisiz hizmet veya hata bulunmaması konusunda açık veya zımni hiçbir garanti vermemektedir.

10. SORUMLULUĞUN SINIRLANDIRILMASI

Şirketin sorumluluğu, olayın gerçekleştiği ayda ödenen abonelik ücretiyle sınırlıdır. Dolaylı, arızi, özel veya cezai zararlardan Şirket sorumlu tutulamaz.

11. SÖZLEŞMENİN DEĞİŞTİRİLMESİ

Şirket, bu Sözleşmeyi herhangi bir zamanda güncelleyebilir. Önemli değişiklikler kayıtlı e-posta adresine bildirilir. Platformu kullanmaya devam etmek, güncellenmiş Sözleşmeyi kabul anlamına gelir.

12. UYGULANACAK HUKUK VE YETKİLİ MAHKEME

Bu Sözleşme Türk Hukuku'na tabidir. Uyuşmazlıklarda İstanbul Mahkemeleri ve İcra Daireleri yetkilidir.

13. İLETİŞİM

Sorularınız için: kavirasoftware@gmail.com
''';

const _kPrivacy = '''
Son güncelleme: Mayıs 2026

Bu Gizlilik Politikası, Kavira Software olarak kaviragiyotin.online adresinde sunduğumuz Kavira SaaS platformunda toplanan, kullanılan ve paylaşılan kişisel verilerinizi açıklamaktadır.

1. VERİ SORUMLUSU

Kavira Software
E-posta: kavirasoftware@gmail.com
Web: https://kaviragiyotin.online

2. TOPLANAN KİŞİSEL VERİLER

a) Hesap ve Kimlik Bilgileri
• Ad, soyad
• Şirket/firma adı
• E-posta adresi
• Şifrelenmiş parola (düz metin olarak saklanmaz)

b) Ödeme Bilgileri
• Ödeme işlemleri Paddle Inc. aracılığıyla gerçekleştirilir. Kredi kartı bilgileri doğrudan sistemimizde saklanmaz.
• Fatura adresi ve vergi kimlik numarası (gerektiğinde)

c) Kullanım Verileri
• Hesaplama geçmişi ve proje verileri
• Platforma erişim tarihleri ve süreleri
• IP adresi ve tarayıcı bilgileri (güvenlik amaçlı)

3. VERİLERİN İŞLENME AMAÇLARI

• Hizmetin sunulması ve sürekliliğinin sağlanması
• Hesap yönetimi ve kullanıcı desteği
• Abonelik ve fatura yönetimi
• Güvenlik, dolandırıcılık önleme ve sistem koruması
• Yasal yükümlülüklerin yerine getirilmesi
• Platform performansının iyileştirilmesi

4. HUKUKİ DAYANAK (KVKK m. 5)

• Sözleşmenin kurulması ve ifası (md. 5/2-c)
• Meşru menfaat (md. 5/2-f)
• Hukuki yükümlülük (md. 5/2-ç)
• Açık rıza (gerektiğinde)

5. VERİLERİN PAYLAŞIMI

Kişisel verileriniz aşağıdaki taraflarla paylaşılabilir:
• Paddle Inc. – ödeme altyapısı sağlayıcısı
• Barındırma hizmet sağlayıcıları (sunucu altyapısı)
• Yetkili kamu kurum ve kuruluşları (yasal zorunluluk halinde)

Verileriniz, yukarıda belirtilen durumlar dışında üçüncü taraflarla satılmaz, kiralanmaz veya paylaşılmaz.

6. YURT DIŞINA VERİ AKTARIMI

Ödeme işlemleri için verileriniz Paddle Inc. (ABD) ile paylaşılmaktadır. Bu aktarım, KVKK kapsamındaki güvenceler çerçevesinde gerçekleştirilmektedir.

7. VERİ SAKLAMA SÜRELERİ

• Hesap verileri: Hesap silme talebinden itibaren 30 gün
• Fatura ve ödeme kayıtları: Yasal yükümlülük gereği 10 yıl
• Güvenlik logları: 1 yıl

8. ÇEREZLER (COOKIES)

Platform, temel işlevsellik için zorunlu çerezler kullanabilir. Üçüncü taraf analitik veya reklam çerezi kullanılmamaktadır.

9. HAKLARINIZ (KVKK m. 11)

Aşağıdaki haklara sahipsiniz:
• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşlenen kişisel verilerinize erişim talep etme
• Eksik veya yanlış verilerin düzeltilmesini isteme
• Kişisel verilerinizin silinmesini talep etme
• Verilerinizin aktarıldığı kişilere bildirim yapılmasını isteme
• Otomatik sistemler aracılığıyla aleyhinize karar oluşmasına itiraz etme
• Hukuka aykırı işleme nedeniyle zararın giderilmesini talep etme

Haklarınızı kullanmak için: kavirasoftware@gmail.com

10. GÜVENLİK

Kişisel verileriniz, endüstri standardı güvenlik önlemleriyle (HTTPS/TLS, şifreli depolama) korunmaktadır. Güvenlik ihlali durumunda yasal süre içinde bilgilendirme yapılır.

11. DEĞİŞİKLİKLER

Bu politika güncellenebilir. Önemli değişiklikler e-posta ile bildirilecektir. Güncel politikaya her zaman kaviragiyotin.online/privacy adresinden ulaşabilirsiniz.

12. İLETİŞİM

kavirasoftware@gmail.com
''';

const _kRefund = '''
Son güncelleme: Mayıs 2026

Bu İade Politikası, Kavira SaaS platformuna yapılan abonelik ödemelerine ilişkin iade ve iptal koşullarını düzenlemektedir.

1. GENEL İLKE

Kavira SaaS, dijital bir yazılım hizmeti sunmaktadır. Hizmetin dijital niteliği nedeniyle, genel kural olarak tamamlanmış ödemeler iade edilmez. Ancak aşağıda belirtilen özel durumlarda iade değerlendirmeye alınır.

2. ÜCRETSİZ DENEME SÜRESİ

Yeni kullanıcılara sunulan ücretsiz deneme süresi boyunca herhangi bir ücret tahsil edilmez. Deneme süresi içinde aboneliği iptal etmeniz halinde ücretlendirilmezsiniz.

3. İPTAL KOŞULLARI

• Aboneliğinizi istediğiniz zaman platform üzerinden iptal edebilirsiniz.
• İptal işlemi, mevcut faturalama döneminin sonunda geçerli olur.
• İptal tarihinden sonraki dönemler için ücret tahsil edilmez.
• Mevcut dönem sona erene kadar platforma erişim devam eder.
• Kısmi dönem iadesi yapılmamaktadır.

4. İADE HAKKI DOĞURAN DURUMLAR

Aşağıdaki özel durumlarda, ödeme tarihinden itibaren 7 (yedi) gün içinde başvuru yapılması koşuluyla iade değerlendirilebilir:

a) Teknik arızadan kaynaklanan erişim sorunu: Platform tarafında yaşanan ve 48 saati aşan kesintiler.
b) Çift ödeme: Sistemsel hata nedeniyle aynı dönem için birden fazla ödeme tahsil edilmesi.
c) Yetkisiz işlem: Hesabınızın yetkisiz kullanımı sonucu oluşan ödeme (derhal bildirim şartıyla).

5. İADE BAŞVURUSU

İade talebinizi aşağıdaki bilgilerle kavirasoftware@gmail.com adresine iletiniz:
• Ad, soyad ve kayıtlı e-posta adresiniz
• Ödeme tarihi ve tutarı
• İade talebinin gerekçesi
• Varsa ekran görüntüsü veya ödeme dekontu

Talepler en geç 5 (beş) iş günü içinde değerlendirilerek yanıtlanacaktır.

6. İADE SÜRECİ

Onaylanan iadeler, Paddle Inc. ödeme altyapısı üzerinden orijinal ödeme yöntemine aktarılır. Banka işlem süresine bağlı olarak iade tutarının hesabınıza yansıması 5-10 iş günü sürebilir.

7. YASAL HAKLAR

Bu politika, Türk Hukuku kapsamındaki tüketici haklarınızı sınırlandırmamaktadır. 6502 Sayılı Tüketicinin Korunması Hakkında Kanun kapsamındaki haklarınız saklıdır.

8. İLETİŞİM

Her türlü soru ve talebiniz için:
E-posta: kavirasoftware@gmail.com
Web: https://kaviragiyotin.online
''';
