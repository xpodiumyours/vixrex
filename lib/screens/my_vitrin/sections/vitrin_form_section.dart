import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/store_publish_payload_builder.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/form_accordion_section.dart';
import 'package:vixrex/widgets/editor/public_link_card.dart';
import 'package:vixrex/widgets/editor/sections/gorseller_bolumu.dart';
import 'package:vixrex/widgets/editor/sections/icerik_seo_bolumu.dart';
import 'package:vixrex/widgets/editor/sections/iletisim_bolumu.dart';
import 'package:vixrex/widgets/editor/sections/kimlik_bolumu.dart';
import 'package:vixrex/widgets/editor/sections/konum_saatler_bolumu.dart';
import 'package:vixrex/widgets/editor/sections/yasal_yayin_bolumu.dart';
import 'package:vixrex/widgets/editor/vitrin_completion_meter.dart';

/// Vitrin düzenleme formunun orkestratörü.
///
/// Faz 0 kalanı (Tek Asistan planı): bu dosya eskiden 1419 satırdı, altı
/// bölüm gövdesini de kendi içinde taşıyordu. Artık yalnız başlık, sabit
/// "genel bağlantı" kartı, akordeon iskeleti (5 bölüm) ve yasal-yayın
/// bloğunu birleştiriyor — her bölümün gövdesi kendi dosyasında
/// (`lib/widgets/editor/sections/*_bolumu.dart`). Akordeon sayısı, sıra,
/// GlobalKey'ler ve VixRex asistanının bölüme kaydırma davranışı
/// değişmedi — yalnız gövdeler taşındı.
class VitrinFormSection extends StatelessWidget {
  final StoreEditorController controller;
  final MyVitrinState state;
  final Map<String, TextEditingController> textControllers;
  final VoidCallback? onPublished;
  final VoidCallback? onOpenExplore;

  const VitrinFormSection({
    super.key,
    required this.controller,
    required this.state,
    required this.textControllers,
    this.onPublished,
    this.onOpenExplore,
  });

  TextEditingController get _name => textControllers['name']!;
  TextEditingController get _whatsapp => textControllers['whatsapp']!;
  TextEditingController get _phone => textControllers['phone']!;
  TextEditingController get _email => textControllers['email']!;
  TextEditingController get _heroBadge => textControllers['heroBadge']!;
  TextEditingController get _galleryKicker => textControllers['galleryKicker']!;
  TextEditingController get _galleryTitle => textControllers['galleryTitle']!;
  TextEditingController get _galleryActionLabel =>
      textControllers['galleryActionLabel']!;
  TextEditingController get _galleryActionHref =>
      textControllers['galleryActionHref']!;
  TextEditingController get _workingHours => textControllers['workingHours']!;
  TextEditingController get _address => textControllers['address']!;
  TextEditingController get _heroLocationText =>
      textControllers['heroLocationText']!;
  TextEditingController get _mapLabel => textControllers['mapLabel']!;
  TextEditingController get _desc => textControllers['description']!;
  TextEditingController get _insta => textControllers['instagram']!;
  TextEditingController get _google => textControllers['googleBusiness']!;
  TextEditingController get _references => textControllers['references']!;
  TextEditingController get _businessType => textControllers['businessType']!;
  TextEditingController get _categorySectionTitle =>
      textControllers['categorySectionTitle']!;
  TextEditingController get _productSectionTitle =>
      textControllers['productSectionTitle']!;
  TextEditingController get _blogKicker => textControllers['blogKicker']!;
  TextEditingController get _blogTitle => textControllers['blogTitle']!;
  TextEditingController get _faqKicker => textControllers['faqKicker']!;
  TextEditingController get _faqTitle => textControllers['faqTitle']!;
  TextEditingController get _faqDescription =>
      textControllers['faqDescription']!;

  @override
  Widget build(BuildContext context) {
    final hasPublished = controller.publishedInfo?.isComplete == true;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final snapshot = VixRexProfileSnapshot.from(
      controller.data,
      controller.publishedInfo,
    );
    final progress = _sectionProgress(snapshot);
    final totalFilled = progress.fold(0, (sum, item) => sum + item.filled);
    final totalFields = progress.fold(0, (sum, item) => sum + item.total);
    final completionPercent =
        totalFields == 0 ? 0 : ((totalFilled / totalFields) * 100).round();
    final missingRequiredLabels = <String>[
      if (!snapshot.nameCompleted) 'İşletme adı',
      if (!snapshot.categoryCompleted) 'Kategori',
      if (!snapshot.whatsappCompleted) 'WhatsApp',
      if (!snapshot.addressCompleted) 'Adres',
      if (!controller.isLegalPublishReady) 'Yasal onay',
    ];
    final sections = _buildAccordionSections(
      context,
      hasPublished: hasPublished,
      progress: progress,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _buildHeader(hasPublished),
        const SizedBox(height: 8),
        _buildSubHeader(hasPublished),
        const SizedBox(height: 16),
        // Yayın aksiyonu — bölümlerin dışında, her zaman görünür kalır
        // (bkz. Adım 5 planı: "yayın aksiyonları formun altında sabit
        // kalır"). Kapalı bir akordeon bölümünün içine gömülürse kullanıcı
        // linke/QR'a/önizlemeye ulaşamaz.
        _buildPublicLinkCard(context, hasPublished),
        const SizedBox(height: 16),
        Container(
          decoration: _cardDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VitrinCompletionMeter(
                percent: completionPercent,
                missingRequiredLabels: missingRequiredLabels,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sectionWidth =
                      isDesktop
                          ? (constraints.maxWidth - AppColors.spacing24) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: AppColors.spacing24,
                    children: [
                      for (final section in sections)
                        SizedBox(width: sectionWidth, child: section),
                    ],
                  );
                },
              ),
              Padding(
                padding: EdgeInsets.all(isDesktop ? 24 : 18),
                child: YasalYayinBolumu(
                  controller: controller,
                  state: state,
                  hasPublished: hasPublished,
                  onPublished: onPublished,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<FormAccordionSection> _buildAccordionSections(
    BuildContext context, {
    required bool hasPublished,
    required List<_FormSectionProgress> progress,
  }) {
    final children = [
      KimlikBolumu(
        controller: controller,
        state: state,
        nameController: _name,
        businessTypeController: _businessType,
        descriptionController: _desc,
        heroBadgeController: _heroBadge,
      ),
      IletisimBolumu(
        controller: controller,
        state: state,
        whatsappController: _whatsapp,
        phoneController: _phone,
        emailController: _email,
        instagramController: _insta,
      ),
      KonumSaatlerBolumu(
        controller: controller,
        state: state,
        addressController: _address,
        heroLocationTextController: _heroLocationText,
        mapLabelController: _mapLabel,
        workingHoursController: _workingHours,
      ),
      GorsellerBolumu(
        controller: controller,
        state: state,
        galleryKickerController: _galleryKicker,
        galleryTitleController: _galleryTitle,
        galleryActionLabelController: _galleryActionLabel,
        galleryActionHrefController: _galleryActionHref,
      ),
      IcerikSeoBolumu(
        controller: controller,
        state: state,
        hasPublished: hasPublished,
        instagramController: _insta,
        referencesController: _references,
        categorySectionTitleController: _categorySectionTitle,
        productSectionTitleController: _productSectionTitle,
        blogKickerController: _blogKicker,
        blogTitleController: _blogTitle,
        faqKickerController: _faqKicker,
        faqTitleController: _faqTitle,
        faqDescriptionController: _faqDescription,
        googleBusinessController: _google,
      ),
    ];
    const titles = [
      'Kimlik',
      'İletişim',
      'Konum ve saatler',
      'Görseller',
      'İçerik ve SEO',
    ];

    return [
      for (var index = 0; index < children.length; index++)
        FormAccordionSection(
          index: index,
          title: titles[index],
          filledCount: progress[index].filled,
          totalCount: progress[index].total,
          isOpen: state.openSectionIndex == index,
          isRequired: index <= MyVitrinState.locationSectionIndex,
          onToggle: () => state.toggleSection(index),
          child: children[index],
        ),
    ];
  }

  List<_FormSectionProgress> _sectionProgress(VixRexProfileSnapshot snapshot) {
    final data = controller.data;
    return [
      _FormSectionProgress.from([
        snapshot.nameCompleted,
        snapshot.categoryCompleted,
        data.businessType.trim().isNotEmpty,
        data.description.trim().isNotEmpty,
        data.heroBadge.trim().isNotEmpty,
      ]),
      _FormSectionProgress.from([
        snapshot.whatsappCompleted,
        data.phone.trim().isNotEmpty,
        data.email.trim().isNotEmpty,
        data.instagram.trim().isNotEmpty,
      ]),
      _FormSectionProgress.from([
        snapshot.addressCompleted,
        data.heroLocationText.trim().isNotEmpty,
        data.mapLabel.trim().isNotEmpty,
        data.workingHours.trim().isNotEmpty,
      ]),
      _FormSectionProgress.from([
        controller.coverBytes != null ||
            (controller.coverUrl?.trim().isNotEmpty ?? false),
        controller.galleryItems.any((item) => !item.isRemoved),
        data.gallerySectionKicker.trim().isNotEmpty,
        data.gallerySectionTitle.trim().isNotEmpty,
        data.galleryActionLabel.trim().isNotEmpty,
        data.galleryActionHref.trim().isNotEmpty,
      ]),
      _FormSectionProgress.from([
        controller.hasAboutSection,
        data.products.isNotEmpty || data.offerings.isNotEmpty,
        controller.hasFeaturedCampaign,
        data.faqItems.isNotEmpty,
        data.blogSectionKicker.trim().isNotEmpty,
        data.blogSectionTitle.trim().isNotEmpty,
        data.googleBusinessLink.trim().isNotEmpty,
        data.marketplaceLinks.any((link) => link.url.trim().isNotEmpty),
        data.referencesLink.trim().isNotEmpty,
        data.categorySectionTitle.trim().isNotEmpty,
        data.productSectionTitle.trim().isNotEmpty,
        data.status.trim().isNotEmpty,
      ]),
    ];
  }

  Widget _buildHeader(bool hasPublished) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hasPublished ? 'Vixrex Düzenle' : 'Vixrex Oluştur',
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildVixRexBadge(),
      ],
    );
  }

  Widget _buildVixRexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_rounded, color: AppColors.onPrimary, size: 13),
          SizedBox(width: 4),
          Text(
            'Vixrex ile',
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(bool hasPublished) {
    return Text(
      hasPublished
          ? 'Düzenledikten sonra kaydet, linkin ve QR kodun güncellenir.'
          : 'Ad, WhatsApp ve konumunu gir — vitrin hazır. Diğer detayları sonra ekleyebilirsin.',
      style: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  }

  Widget _buildPublicLinkCard(BuildContext context, bool hasPublished) {
    const builder = StorePublishPayloadBuilder();
    final publishedLink = controller.publishedInfo?.publicLink.trim() ?? '';
    final previewLink = builder.previewVitrinLink(controller.data.name);
    final displayLink =
        hasPublished && publishedLink.isNotEmpty
            ? publishedLink
            : (previewLink.isEmpty ? null : previewLink);

    return PublicLinkCard(
      displayLink: displayLink,
      isLive: hasPublished && publishedLink.isNotEmpty,
      onCopyLink:
          () => _copyDisplayLink(context, displayLink, isLive: hasPublished),
      onPreview: () => _openInAppPreview(context),
      onShareLink: hasPublished ? () => _shareLink(context) : null,
      onShowQr: hasPublished ? () => _showQrSheet(context) : null,
      onOpenLiveLink: hasPublished ? () => _openLink(context) : null,
      onScrollToPublish:
          hasPublished
              ? null
              : () => state.scrollToVixRexAction(VixRexAction.scrollToLegal),
    );
  }

  /// Yayındaki vitrinin QR kodunu gösterir.
  ///
  /// Esnaf bunu tezgâha yapıştırıyor; kiralama vaadinde de "özel paylaşım
  /// linki ve QR kod" diye geçiyor. Eski PublishActionsSection'da vardı,
  /// PublicLinkCard'a geçişte düşmüştü.
  ///
  /// Görsel, vitrin sayfasının kullandığı aynı hizmetten geliyor — iki
  /// yerde iki farklı QR üretmemek için.
  void _showQrSheet(BuildContext ctx) {
    final raw = controller.publishedInfo?.publicLink.trim() ?? '';
    if (raw.isEmpty) {
      state.showSnackBar(ctx, 'Önce vitrini yayına al.');
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=320x320&data='
        '${Uri.encodeComponent(link)}';

    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Vitrin QR Kodun',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Yazdırıp tezgâhına koyabilirsin. Müşteri okuttuğunda '
                    'doğrudan vitrinine gelir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        qrUrl,
                        width: 220,
                        height: 220,
                        errorBuilder:
                            (_, __, ___) => const SizedBox(
                              width: 220,
                              height: 220,
                              child: Center(
                                child: Text(
                                  'QR kodu getirilemedi.\nİnternet bağlantını '
                                  'kontrol et.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    link,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _copyDisplayLink(ctx, link, isLive: true);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Linki Kopyala'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // Taslak/yayın ayrımı controller.openOwnerPreview() arkasında saklanır
  // (implementation_plan.md §5.1) — bu ekran hangi durumda olduğunu bilmez.
  Future<void> _openInAppPreview(BuildContext ctx) async {
    try {
      final owner = await controller.openOwnerPreview();
      if (!ctx.mounted) return;
      await AppRouter.openPublicUrl(
        ctx,
        owner.url,
        failureMessage: 'Önizleme açılamadı.',
      );
    } catch (e) {
      if (!ctx.mounted) return;
      state.showSnackBar(ctx, 'Önizleme hazırlanamadı: $e');
    }
  }

  Future<void> _copyDisplayLink(
    BuildContext ctx,
    String? link, {
    required bool isLive,
  }) async {
    final raw = link?.trim() ?? '';
    if (raw.isEmpty) {
      state.showSnackBar(ctx, 'Önce işletme adını yazın.');
      return;
    }
    final repaired = isLive ? PublicSiteConfig.repairPublicLink(raw) : raw;
    await Clipboard.setData(ClipboardData(text: repaired));
    if (!ctx.mounted) return;
    state.showSnackBar(
      ctx,
      isLive
          ? 'Vitrin linki kopyalandı.'
          : 'Öngörülen vitrin linki kopyalandı. Yayına alınca tarayıcıda açılır.',
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.cardBorderDark),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );

  Future<void> _openLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(
        ctx,
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.',
      );
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      state.showSnackBar(ctx, 'Vitrin linki açılamadı.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    } catch (_) {
      if (ctx.mounted) state.showSnackBar(ctx, 'Tarayıcı açılamadı.');
    }
  }

  Future<void> _shareLink(BuildContext ctx) async {
    final raw = controller.publishedInfo?.publicLink.trim();
    if (raw == null || raw.isEmpty) {
      state.showSnackBar(
        ctx,
        'Vitrininizi yayına aldığınızda size özel web linkiniz oluşacak.',
      );
      return;
    }
    final link = PublicSiteConfig.repairPublicLink(raw);
    try {
      final r = await SharePlus.instance.share(
        ShareParams(
          text: 'Vixrex web linkim:\n$link',
          title: 'Vixrex Web Linki',
        ),
      );
      if (r.status != ShareResultStatus.unavailable) return;
    } catch (e) {
      if (kDebugMode) debugPrint('_shareLink error: $e');
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (ctx.mounted) {
      state.showSnackBar(ctx, 'Paylaşım açılamadı, link kopyalandı.');
    }
  }
}

class _FormSectionProgress {
  const _FormSectionProgress({required this.filled, required this.total});

  factory _FormSectionProgress.from(List<bool> values) {
    return _FormSectionProgress(
      filled: values.where((value) => value).length,
      total: values.length,
    );
  }

  final int filled;
  final int total;
}
