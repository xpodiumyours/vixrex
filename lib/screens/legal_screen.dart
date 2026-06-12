import 'package:flutter/material.dart';
import 'package:vitrinx/config/legal_config.dart';

enum LegalPageType {
  privacy,
  terms,
  dataDeletion;

  String get routePath {
    switch (this) {
      case LegalPageType.privacy:
        return LegalConfig.privacyPath;
      case LegalPageType.terms:
        return LegalConfig.termsPath;
      case LegalPageType.dataDeletion:
        return LegalConfig.dataDeletionPath;
    }
  }

  String get title {
    switch (this) {
      case LegalPageType.privacy:
        return 'Gizlilik ve KVKK Politikası';
      case LegalPageType.terms:
        return 'Kullanım Şartları';
      case LegalPageType.dataDeletion:
        return 'Hesap ve Veri Silme';
    }
  }

  String get subtitle {
    switch (this) {
      case LegalPageType.privacy:
        return 'VitrinX içinde kişisel verilerin KVKK kapsamında nasıl işlendiğini açıklar.';
      case LegalPageType.terms:
        return 'VitrinX kullanırken geçerli olan temel kuralları ve sorumlulukları açıklar.';
      case LegalPageType.dataDeletion:
        return 'Hesap, vitrin ve mağaza verilerinizin silinmesini nasıl talep edeceğinizi açıklar.';
    }
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.type});

  final LegalPageType type;

  static LegalPageType? typeFromRoute(String routeName) {
    for (final value in LegalPageType.values) {
      if (value.routePath == routeName) return value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsFor(type);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(type.title),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(type: type),
                  const SizedBox(height: 24),
                  for (final section in sections) ...[
                    _LegalSection(section: section),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Son güncelleme: 12 Haziran 2026',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_LegalSectionData> _sectionsFor(LegalPageType type) {
    switch (type) {
      case LegalPageType.privacy:
        return const [
          _LegalSectionData(
            title: 'Ürün sahibi',
            body:
                '${LegalConfig.productOwnershipText} Bu politika, VitrinX hizmeti kapsamında işlenen kullanıcı, mağaza, vitrin ve iletişim verileri için hazırlanmıştır.',
          ),
          _LegalSectionData(
            title: 'Toplanan veriler',
            body:
                'VitrinX; hesap açtığınızda e-posta adresinizi, mağaza veya vitrin oluşturduğunuzda işletme adı, açıklama, adres, WhatsApp, Instagram, web sitesi, çalışma saatleri, ürün bilgileri, görseller ve isteğe bağlı konum bilgilerini işleyebilir.',
          ),
          _LegalSectionData(
            title: 'Verilerin kullanım amacı',
            body:
                'Bu veriler vitrininizi oluşturmak, yayınlamak, mağaza bağlantınızı göstermek, hesabınıza erişmenizi sağlamak, destek taleplerini yanıtlamak ve güvenli çalışmayı korumak için kullanılır.',
          ),
          _LegalSectionData(
            title: 'Konum ve izinler',
            body:
                'Konum bilgisi yalnızca kullanıcı izin verirse alınır. Konum, işletme adresini haritada göstermek ve müşterilerin yol tarifi almasını kolaylaştırmak için kullanılır. Konum paylaşmak zorunlu değildir; adresi elle girebilirsiniz.',
          ),
          _LegalSectionData(
            title: 'Görseller ve kullanıcı içeriği',
            body:
                'Yüklediğiniz logo, ürün ve galeri görselleri vitrininizde gösterilebilir. Başkasına ait telifli görsel, yanıltıcı bilgi, yasa dışı ürün veya uygunsuz içerik yüklememelisiniz.',
          ),
          _LegalSectionData(
            title: 'Üçüncü taraf hizmetler',
            body:
                'VitrinX; hesap, veritabanı ve görsel saklama için Supabase hizmetlerinden; harita ve dış bağlantılar için cihazınızın veya tarayıcınızın ilgili servislerinden yararlanabilir.',
          ),
          _LegalSectionData(
            title: 'Saklama ve silme',
            body:
                'Verileriniz hizmeti sunmak için gerekli olduğu sürece saklanır. Hesap, vitrin veya mağaza verilerinizin silinmesini data deletion sayfasındaki yöntemle talep edebilirsiniz.',
          ),
          _LegalSectionData(
            title: 'İletişim',
            body:
                'Gizlilik, KVKK ve veri silme talepleri için bizimle ${LegalConfig.privacyEmail} adresinden iletişime geçebilirsiniz.',
          ),
        ];
      case LegalPageType.terms:
        return const [
          _LegalSectionData(
            title: 'Marka ve telif hakları',
            body:
                '${LegalConfig.productOwnershipText} VitrinX adı, arayüzü, tasarım dili, metinleri ve hizmet yapısı Xpodiumyours tarafından sunulur. Kullanıcılar kendilerine ait olmayan marka, logo, görsel, metin veya telifli içerikleri izinsiz paylaşmamalıdır.',
          ),
          _LegalSectionData(
            title: 'Hizmetin amacı',
            body:
                'VitrinX, küçük işletmelerin ürün, hizmet, iletişim, konum ve sosyal bağlantılarını paylaşılabilir bir dijital vitrin olarak yayınlamasına yardımcı olur.',
          ),
          _LegalSectionData(
            title: 'Kullanıcı sorumluluğu',
            body:
                'Vitrininize eklediğiniz işletme bilgileri, fiyatlar, ürün açıklamaları, bağlantılar ve görsellerden siz sorumlusunuz. Bilgilerin doğru ve güncel tutulması gerekir.',
          ),
          _LegalSectionData(
            title: 'Yasak içerikler',
            body:
                'Yasa dışı ürün veya hizmet, yanıltıcı bilgi, nefret veya şiddet içeriği, cinsel içerik, başkasına ait marka/telif ihlali içeren görsel veya metin paylaşamazsınız.',
          ),
          _LegalSectionData(
            title: 'İçerik kaldırma',
            body:
                'VitrinX; hukuka, platform kurallarına veya kullanıcı güvenliğine aykırı olduğu bildirilen içerikleri inceleyebilir, kaldırabilir veya ilgili vitrine erişimi sınırlayabilir.',
          ),
          _LegalSectionData(
            title: 'Dış bağlantılar',
            body:
                'WhatsApp, Instagram, Google Maps, pazar yeri ve web sitesi bağlantıları üçüncü taraf hizmetlere yönlendirebilir. Bu hizmetlerin kendi şartları ve gizlilik politikaları geçerlidir.',
          ),
          _LegalSectionData(
            title: 'Değişiklikler',
            body:
                'VitrinX, hizmeti ve bu şartları geliştirme veya yasal gereklilikler nedeniyle güncelleme hakkını saklı tutar.',
          ),
          _LegalSectionData(
            title: 'İletişim',
            body:
                'Şartlar, içerik şikayeti veya hesap talepleri için ${LegalConfig.privacyEmail} adresinden iletişime geçebilirsiniz.',
          ),
        ];
      case LegalPageType.dataDeletion:
        return const [
          _LegalSectionData(
            title: 'Ürün sahibi',
            body:
                '${LegalConfig.productOwnershipText} Hesap, vitrin, mağaza ve ilişkili veri silme talepleri bu ürün kapsamında değerlendirilir.',
          ),
          _LegalSectionData(
            title: 'Silme talebi nasıl gönderilir?',
            body:
                'Hesap, vitrin veya mağaza verilerinizin silinmesini istemek için ${LegalConfig.privacyEmail} adresine e-posta gönderin. Konu satırına "VitrinX veri silme talebi" yazın.',
          ),
          _LegalSectionData(
            title: 'E-postaya eklenmesi gereken bilgiler',
            body:
                'Talebinize kayıtlı e-posta adresinizi, vitrin veya mağaza bağlantınızı, silinmesini istediğiniz veri türünü ve size ulaşabileceğimiz iletişim adresini ekleyin.',
          ),
          _LegalSectionData(
            title: 'Silinebilecek veriler',
            body:
                'Hesap bilgileri, vitrin/mağaza kayıtları, ürün bilgileri, galeri görselleri, logo, konum bilgileri ve yerel kayıtla ilişkili sunucu verileri silme kapsamına alınabilir.',
          ),
          _LegalSectionData(
            title: 'Saklanabilecek sınırlı veriler',
            body:
                'Yasal yükümlülük, güvenlik incelemesi, kötüye kullanım önleme veya uyuşmazlık çözümü için gerekli olan sınırlı kayıtlar mevzuatın izin verdiği süre boyunca saklanabilir.',
          ),
          _LegalSectionData(
            title: 'İşlem süresi',
            body:
                'Talebiniz alındıktan sonra kimlik/doğrulama kontrolü yapılır ve uygun talepler makul süre içinde işleme alınır.',
          ),
          _LegalSectionData(
            title: 'Uygulama içi silme',
            body:
                'Uygulama içindeki vitrin veya mağaza silme butonu mevcut vitrininizi kaldırmaya yardımcı olur. Hesap ve tüm ilişkili veri talepleri için bu sayfadaki e-posta yolunu kullanın.',
          ),
        ];
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type});

  final LegalPageType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            LegalConfig.productOwnershipText,
            style: TextStyle(
              color: Color(0xFFFF5A1F),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            type.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            type.subtitle,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({required this.section});

  final _LegalSectionData section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSectionData {
  const _LegalSectionData({required this.title, required this.body});

  final String title;
  final String body;
}
