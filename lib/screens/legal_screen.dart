import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitrinx/config/legal_config.dart';
import 'package:vitrinx/models/legal_document.dart';
import 'package:vitrinx/services/legal_document_service.dart';
import 'package:vitrinx/theme/app_colors.dart';
import 'package:vitrinx/theme/app_text_styles.dart';

enum LegalPageType {
  privacy,
  terms,
  consent,
  dataDeletion;

  String get routePath {
    switch (this) {
      case LegalPageType.privacy:
        return LegalConfig.privacyPath;
      case LegalPageType.terms:
        return LegalConfig.termsPath;
      case LegalPageType.consent:
        return LegalConfig.consentPath;
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
      case LegalPageType.consent:
        return 'Açık Rıza Beyanı';
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
      case LegalPageType.consent:
        return 'Vitrin bilgilerinizin kamuya açık yayınlanmasına ilişkin açık rıza beyanını açıklar.';
      case LegalPageType.dataDeletion:
        return 'Hesap, vitrin ve mağaza verilerinizin silinmesini nasıl talep edeceğinizi açıklar.';
    }
  }

  IconData get icon {
    switch (this) {
      case LegalPageType.privacy:
        return Icons.security_rounded;
      case LegalPageType.terms:
        return Icons.gavel_rounded;
      case LegalPageType.consent:
        return Icons.fact_check_rounded;
      case LegalPageType.dataDeletion:
        return Icons.delete_sweep_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case LegalPageType.privacy:
        return const Color(0xFF10B981); // Mint green
      case LegalPageType.terms:
        return const Color(0xFF3B82F6); // Royal blue
      case LegalPageType.consent:
        return const Color(0xFF7C3AED);
      case LegalPageType.dataDeletion:
        return AppColors.brandOrange; // Brand orange
    }
  }
}

class LegalScreen extends StatefulWidget {
  final LegalPageType type;
  final SupabaseClient? supabaseClient;
  final LegalDocumentService? documentService;

  const LegalScreen({
    super.key,
    required this.type,
    this.supabaseClient,
    this.documentService,
  });

  static LegalPageType? typeFromRoute(String routeName) {
    final normalized = routeName.trim().split('?').first;
    for (final value in LegalPageType.values) {
      if (value.routePath == normalized ||
          '/legal/${value.name}' == normalized) {
        return value;
      }
    }
    return null;
  }

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  List<_LegalSectionData> _sections = [];
  LegalDocument? _document;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final service =
          widget.documentService ??
          LegalDocumentService(supabaseClient: widget.supabaseClient);
      final document = await service.loadActiveDocument(widget.type.name);
      if (!mounted) return;
      setState(() {
        _document = document;
        _sections = document.sections
            .map(
              (section) =>
                  _LegalSectionData(title: section.title, body: section.body),
            )
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading legal docs from Supabase: $e');
      debugPrint(
        'Stale local legal fallback is disabled '
        '(${_sectionsFor(widget.type).length} legacy sections ignored).',
      );
      if (!mounted) return;
      setState(() {
        _document = null;
        _sections = [];
        _loadError =
            'Güncel yasal belge yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.darkTextAlt,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.type.title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glowing circles for premium styling
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: widget.type.accentColor.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Page content
            if (_isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            else if (_loadError != null)
              _LegalLoadError(message: _loadError!, onRetry: _loadSections)
            else
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          type: widget.type,
                          title: _document!.title,
                          subtitle: _document!.subtitle,
                        ),
                        const SizedBox(height: 24),
                        for (final section in _sections) ...[
                          _LegalSection(
                            section: section,
                            accentColor: widget.type.accentColor,
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 8),
                        _EmailContactCard(accentColor: widget.type.accentColor),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Sürüm: ${_document?.version ?? '-'}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_LegalSectionData> _sectionsFor(LegalPageType type) {
    switch (type) {
      case LegalPageType.privacy:
        return const [
          _LegalSectionData(
            title: 'Ürün Sahibi',
            body:
                '${LegalConfig.productOwnershipText} Bu politika, VitrinX hizmeti kapsamında işlenen kullanıcı, mağaza, vitrin ve iletişim verileri için hazırlanmıştır.',
          ),
          _LegalSectionData(
            title: 'Toplanan Veriler',
            body:
                'VitrinX; hesap açtığınızda e-posta adresinizi, mağaza veya vitrin oluşturduğunuzda işletme adı, açıklama, adres, WhatsApp, Instagram, web sitesi, çalışma saatleri, ürün bilgileri, görseller ve isteğe bağlı konum bilgilerini işleyebilir.',
          ),
          _LegalSectionData(
            title: 'Instagram Entegrasyonu Kapsamında İşlenen Veriler',
            body:
                'Instagram hesabınızı VitrinX\'e bağlamanız halinde, yalnızca açıkça izin verdiğiniz ve resmi Meta/Instagram API\'leri üzerinden sağlanan veriler işlenir. Bu kapsamda Instagram kullanıcı adınız, Instagram kullanıcı kimliğiniz, hesap türünüz, izin kapsamları, bağlantı durumu, token bitiş tarihi, seçtiğiniz medya içeriklerine ait medya kimliği, görsel bağlantısı, açıklama/caption, permalink, zaman bilgisi ve ürün olarak aktarmayı seçtiğiniz medya görselleri işlenebilir.\n\nInstagram erişim token\'ları istemci tarafında saklanmaz; sunucu tarafında şifreli olarak saklanır ve yalnızca Instagram bağlantısını sürdürmek, medya listesini görüntülemek ve kullanıcının seçtiği içerikleri ürüne dönüştürmek amacıyla kullanılır.\n\nInstagram\'dan aktarılan görseller VitrinX\'in kullandığı Supabase Storage altyapısında saklanabilir. Instagram bağlantınızı kestiğinizde token bilgileriniz silinir. Ayrıca talep etmeniz halinde Instagram\'dan aktarılan ürün, görsel ve import kayıtlarının silinmesini isteyebilirsiniz.\n\nVitrinX, üçüncü taraf Instagram profillerinden, kullanıcının izin vermediği hesaplardan veya public feed\'lerden scraping yoluyla veri toplamaz.\n\nİşleme Amacı: Vitrin içeriğini zenginleştirmek, Instagram gönderilerini pratik şekilde ürüne dönüştürmek ve vitrin ziyaretçilerine sunmak.\nHukuki Sebep: Kullanıcının entegrasyonu başlatmasıyla verilen açık rıza ve platform hizmet sözleşmesinin ifası.\nAktarım: Veriler, entegrasyonun sağlanması için Meta API\'leri, görsel ve veri barındırma hizmetleri için Supabase altyapısı ve sunucu sağlayıcılarıyla paylaşılabilir.\nSaklama Süresi: Instagram entegrasyonu aktif olduğu sürece veya kullanıcı ürünleri/bağlantıyı silene kadar saklanır.\nSilme/Bağlantı Kesme: Ayarlar menüsünden Instagram bağlantısını kesebilir, dilerseniz "Bağlantıyı kes ve Instagram\'dan aktarılanları temizle" (Mod B) seçeneğiyle tüm verileri silebilir veya ${LegalConfig.privacyEmail} adresine yazılı talep gönderebilirsiniz.\nKullanıcı Hakları: KVKK Madde 11 kapsamındaki tüm haklarınız (bilgi alma, düzeltme, silme talebi vb.) saklıdır.',
          ),
          _LegalSectionData(
            title: 'Verilerin Kullanım Amacı',
            body:
                'Bu veriler vitrininizi oluşturmak, yayınlamak, mağaza bağlantınızı göstermek, hesabınıza erişmenizi sağlamak, destek taleplerini yanıtlamak ve güvenli çalışmayı korumak için kullanılır.',
          ),
          _LegalSectionData(
            title: 'Konum ve İzinler',
            body:
                'Konum bilgisi yalnızca kullanıcı izin verirse alınır. Konum, işletme adresini haritada göstermek ve müşterilerin yol tarifi almasını kolaylaştırmak için kullanılır. Konum paylaşmak zorunlu değildir; adresi elle girebilirsiniz.',
          ),
          _LegalSectionData(
            title: 'Görseller ve Kullanıcı İçeriği',
            body:
                'Yüklediğiniz logo, ürün ve galeri görselleri vitrininizde gösterilebilir. Başkasına ait telifli görsel, yanıltıcı bilgi, yasa dışı ürün veya uygunsuz içerik yüklememelisiniz.',
          ),
          _LegalSectionData(
            title: 'Üçüncü Taraf Hizmetler',
            body:
                'VitrinX; hesap, veritabanı ve görsel saklama için Supabase hizmetlerinden; harita ve dış bağlantılar için cihazınızın veya tarayıcınızın ilgili servislerinden yararlanabilir.',
          ),
          _LegalSectionData(
            title: 'Saklama ve Silme',
            body:
                'Verileriniz hizmeti sunmak için gerekli olduğu sürece saklanır. Hesap, vitrin veya mağaza verilerinizin silinmesini data deletion sayfasındaki yöntemle talep edebilirsiniz.',
          ),
          _LegalSectionData(
            title: 'İletişim',
            body:
                'Gizlilik, KVKK ve veri silme talepleri için bizimle iletişim kurabilirsiniz. Hızlı kopyalama panelini aşağıda bulabilirsiniz.',
          ),
        ];
      case LegalPageType.terms:
        return const [
          _LegalSectionData(
            title: 'Marka ve Telif Hakları',
            body:
                '${LegalConfig.productOwnershipText} VitrinX adı, arayüzü, tasarım dili, metinleri ve hizmet yapısı Xpodiumyours tarafından sunulur. Kullanıcılar kendilerine ait olmayan marka, logo, görsel, metin veya telifli içerikleri izinsiz paylaşmamalıdır.',
          ),
          _LegalSectionData(
            title: 'Hizmetin Amacı',
            body:
                'VitrinX, küçük işletmelerin ürün, hizmet, iletişim, konum ve sosyal bağlantılarını paylaşılabilir bir dijital vitrin olarak yayınlamasına yardımcı olur.',
          ),
          _LegalSectionData(
            title: 'Kullanıcı Sorumluluğu',
            body:
                'Vitrininize eklediğiniz işletme bilgileri, fiyatlar, ürün açıklamaları, bağlantılar ve görsellerden siz sorumlusunuz. Bilgilerin doğru ve güncel tutulması gerekir.',
          ),
          _LegalSectionData(
            title: 'Yasak İçerikler',
            body:
                'Yasa dışı ürün veya hizmet, yanıltıcı bilgi, nefret veya şiddet içeriği, cinsel içerik, başkasına ait marka/telif ihlali içeren görsel veya metin paylaşamazsınız.',
          ),
          _LegalSectionData(
            title: 'İçerik Kaldırma',
            body:
                'VitrinX; hukuka, platform kurallarına veya kullanıcı güvenliğine aykırı olduğu bildirilen içerikleri inceleyebilir, kaldırabilir veya ilgili vitrine erişimi sınırlayabilir.',
          ),
          _LegalSectionData(
            title: 'Dış Bağlantılar',
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
                'Şartlar, içerik şikayeti veya hesap talepleri için bizimle iletişim kurabilirsiniz. Hızlı kopyalama panelini aşağıda bulabilirsiniz.',
          ),
        ];
      case LegalPageType.consent:
        return const [
          _LegalSectionData(
            title: 'Yayınlama Açık Rızası',
            body:
                'Vitrin bilgilerimin VitrinX üzerindeki dijital vitrinimde müşterilere açık şekilde yayınlanmasına açık rıza veriyorum.',
          ),
          _LegalSectionData(
            title: 'Geri Çekme',
            body:
                'Açık rızamı geri çekerek vitrinimi yayından kaldırabileceğimi biliyorum.',
          ),
        ];
      case LegalPageType.dataDeletion:
        return const [
          _LegalSectionData(
            title: 'Ürün Sahibi',
            body:
                '${LegalConfig.productOwnershipText} Hesap, vitrin, mağaza ve ilişkili veri silme talepleri bu ürün kapsamında değerlendirilir.',
          ),
          _LegalSectionData(
            title: 'Silme Talebi Nasıl Gönderilir?',
            body:
                'Hesap, vitrin veya mağaza verilerinizin silinmesini istemek için destek e-posta adresimize bir talep göndermeniz yeterlidir. Konu satırına "VitrinX veri silme talebi" yazmanız işlemlerinizi hızlandıracaktır.',
          ),
          _LegalSectionData(
            title: 'E-postaya Eklenmesi Gereken Bilgiler',
            body:
                'Talebinize kayıtlı e-posta adresinizi, vitrin veya mağaza bağlantınızı, silinmesini istediğiniz veri türünü ve size ulaşabileceğimiz iletişim adresini ekleyin.',
          ),
          _LegalSectionData(
            title: 'Silinebilecek Veriler',
            body:
                'Hesap bilgileri, vitrin/mağaza kayıtları, ürün bilgileri, galeri görselleri, logo, konum bilgileri ve yerel kayıtla ilişkili sunucu verileri silme kapsamına alınabilir.',
          ),
          _LegalSectionData(
            title: 'Saklanabilecek Sınırlı Veriler',
            body:
                'Yasal yükümlülük, güvenlik incelemesi, kötüye kullanım önleme veya uyuşmazlık çözümü için gerekli olan sınırlı kayıtlar mevzuatın izin verdiği süre boyunca saklanabilir.',
          ),
          _LegalSectionData(
            title: 'İşlem Süresi',
            body:
                'Talebiniz alındıktan sonra kimlik/doğrulama kontrolü yapılır ve uygun talepler makul süre içinde işleme alınır.',
          ),
          _LegalSectionData(
            title: 'Uygulama İçi Silme',
            body:
                'Uygulama içindeki vitrin veya mağaza silme butonu mevcut vitrininizi kaldırmaya yardımcı olur. Hesap ve tüm ilişkili veri talepleri için bu sayfadaki e-posta yolunu kullanın.',
          ),
        ];
    }
  }
}

class _LegalLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LegalLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.mutedText,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final LegalPageType type;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  LegalConfig.productOwnershipText.toUpperCase(),
                  style: TextStyle(
                    color: type.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: type.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(type.icon, color: type.accentColor, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 30,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 15,
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
  const _LegalSection({required this.section, required this.accentColor});

  final _LegalSectionData section;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            section.body,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailContactCard extends StatefulWidget {
  const _EmailContactCard({required this.accentColor});

  final Color accentColor;

  @override
  State<_EmailContactCard> createState() => _EmailContactCardState();
}

class _EmailContactCardState extends State<_EmailContactCard> {
  bool _isCopied = false;

  Future<void> _copyEmail() async {
    await Clipboard.setData(
      const ClipboardData(text: LegalConfig.privacyEmail),
    );
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: LegalConfig.privacyEmail,
      query: 'subject=VitrinX Veri Silme Talebi',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withValues(alpha: 0.12),
            widget.accentColor.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mail_outline_rounded,
                color: widget.accentColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'İletişim & Hızlı Talep',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Sorularınız ve talepleriniz için aşağıdaki kurumsal e-posta adresimizi kullanabilir veya doğrudan e-posta göndermek için tıklayabilirsiniz.',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 420;
              return isSmall
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildEmailAddressBox(),
                      const SizedBox(height: 10),
                      _buildEmailActionButton(),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(child: _buildEmailAddressBox()),
                      const SizedBox(width: 12),
                      _buildEmailActionButton(),
                    ],
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailAddressBox() {
    return InkWell(
      onTap: _copyEmail,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: widget.accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                LegalConfig.privacyEmail,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState:
                  _isCopied
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
              firstChild: Icon(
                Icons.copy_rounded,
                color: widget.accentColor,
                size: 18,
              ),
              secondChild: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailActionButton() {
    return ElevatedButton(
      onPressed: _launchEmail,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'E-Posta Gönder',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          SizedBox(width: 6),
          Icon(Icons.open_in_new_rounded, size: 14),
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
