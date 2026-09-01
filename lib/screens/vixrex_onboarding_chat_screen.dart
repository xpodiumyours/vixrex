import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/controllers/vixrex_onboarding_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/models/assistant_handoff.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/chat/chat_bubble.dart';
import 'package:vixrex/widgets/chat/chat_composer.dart';
import 'package:vixrex/widgets/chat/chat_pill.dart';
import 'package:vixrex/widgets/chat/chat_top_bar.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';
import 'package:vixrex/widgets/onboarding/kategori_secici.dart';

/// Rehber sohbet geçmişine onboarding transcript yazıldığını işaretler (çift yazmayı engeller).
const String _kOnboardingHandoffMarker = 'onboarding_handoff_v1';

/// Faz 2: HTML örneğindeki varlık sohbeti (ad / WA / konum → yayın → link).
/// Landing’deki işletme adı alanı [initialName] ile gelir (home shell ile aynı fikir).
///
/// Faz D (Tek Asistan planı): adım makinesi, doğrulama ve kaydetme çağrıları
/// [VixRexOnboardingController]'a taşındı — bu ekran artık o controller'ı
/// dinleyen ince bir `build`: Faz A bileşenlerini (`ChatTopBar`,
/// `ChatComposer`, `ChatBubble`, `ChatPill`) dizer, sohbet satırlarının
/// kendisini (`_lines`, kaydırma, geçmişe yazma) ve widget'a bağlı işleri
/// (navigasyon, `ScaffoldMessenger`) tutar.
class VixRexOnboardingChatScreen extends StatefulWidget {
  const VixRexOnboardingChatScreen({
    super.key,
    this.initialName,
    this.editorController,
    this.editorInitialization,
    this.compact = false,
    this.onClose,
    this.embeddedInShell = false,
    this.onSetupComplete,
  });

  final String? initialName;
  final StoreEditorController? editorController;
  final Future<void>? editorInitialization;
  final bool compact;
  final VoidCallback? onClose;

  /// HomeShell Vixrex sekmesi içinde: üst bar yok, handoff navigate etmez.
  final bool embeddedInShell;

  /// [embeddedInShell] iken “Vixrex ile geliştir” → parent snapshot yeniler.
  final VoidCallback? onSetupComplete;

  @override
  State<VixRexOnboardingChatScreen> createState() =>
      _VixRexOnboardingChatScreenState();
}

class _VixRexOnboardingChatScreenState
    extends State<VixRexOnboardingChatScreen> {
  late final StoreEditorController _controller;
  late final VixRexOnboardingController _onboarding;
  late final MyVitrinState _vitrinState;
  late final bool _ownsController;
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _addressController = TextEditingController();
  final _heroLocationTextController = TextEditingController();
  final _mapLabelController = TextEditingController();
  final _inputFocus = FocusNode();

  final List<_ChatLine> _lines = [];
  Future<void> _transcriptPersistQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.editorController == null;
    _controller = widget.editorController ?? StoreEditorController();
    _vitrinState = MyVitrinState(controller: _controller);
    _controller.addListener(_onControllerTick);
    _onboarding = VixRexOnboardingController(
      editorController: _controller,
      onBotMessage: _pushBot,
      onUserMessage: _pushUser,
      onPersistTranscript: _handoffTranscriptToRehber,
      onRequestFocus: _focusInput,
      onChooseReadyTemplate: _openReadyTemplatePicker,
    );
    _onboarding.addListener(_onOnboardingTick);
    _bootstrap();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  /// Keşfet'i "sadece kiralık" modunda sohbetin üstüne açar. "Uygun olan
  /// yok" derse ekranı kapatıp sıfırdan-oluştur yoluna döner — sohbet
  /// aynı yerde bekliyor olur, kaybolmaz.
  void _openReadyTemplatePicker() {
    AppRouter.pushReadyTemplatePicker(
      context,
      onNoneMatch: () {
        Navigator.of(context).pop();
        _onboarding.chooseScratch();
      },
    );
  }

  void _onOnboardingTick() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await _onboarding.bootstrap(
      sharedInitialization: widget.editorInitialization,
      ownsController: _ownsController,
      initialName: widget.initialName,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    _onboarding.removeListener(_onOnboardingTick);
    _onboarding.dispose();
    _vitrinState.dispose();
    if (_ownsController) _controller.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _addressController.dispose();
    _heroLocationTextController.dispose();
    _mapLabelController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _pushBot(String text, {String? publicLink}) {
    _lines.add(
      _ChatLine.bot(
        text,
        publicLink: publicLink,
        onOpenPublicLink: publicLink == null ? null : _openPublicLink,
      ),
    );
    _queueTranscriptPersistence();
    _scrollToEnd();
  }

  void _pushUser(String text) {
    _lines.add(_ChatLine.user(text));
    _queueTranscriptPersistence();
    _scrollToEnd();
  }

  // Faz C: bu mesajlar gerçek transkript, "üretilmiş rehberlik" değil —
  // uretilmis varsayılan false'ta kalır, reconcileGuidanceHistory bunları
  // asla ayıklamaz (onboarding_handoff_v1 işaretçili son mesaj dahil).
  List<ChatMessage> _transcriptAsChatMessages({bool markHandoff = true}) {
    final now = DateTime.now();
    final out = <ChatMessage>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final link = line.publicLink?.trim();
      final text =
          (link == null || link.isEmpty) ? line.text : '${line.text}\n\n$link';
      final isLast = i == _lines.length - 1;
      out.add(
        ChatMessage(
          id: 'onboarding_$i',
          text: text,
          isBot: line.isBot,
          timestamp: now.add(Duration(milliseconds: i)),
          snapshotStateKey:
              isLast && markHandoff ? _kOnboardingHandoffMarker : null,
        ),
      );
    }
    if (out.isEmpty && markHandoff) {
      out.add(
        ChatMessage.bot(
          'Kurulum sohbeti tamamlandı.',
          snapshotStateKey: _kOnboardingHandoffMarker,
        ),
      );
    }
    return out;
  }

  Future<void> _persistTranscriptIncrementally() async {
    final service = ChatbotService();
    final transcript = _transcriptAsChatMessages(markHandoff: false);
    final existing = await service.loadHistory();
    final transcriptIds = transcript.map((message) => message.id).toSet();
    await service.saveHistory([
      ...transcript,
      ...existing.where((message) => !transcriptIds.contains(message.id)),
    ]);
  }

  void _queueTranscriptPersistence() {
    _transcriptPersistQueue = _transcriptPersistQueue
        .then((_) => _persistTranscriptIncrementally())
        .catchError((Object _) {});
    unawaited(_transcriptPersistQueue);
  }

  /// Onboarding balonlarını mevcut rehber history’sine yazar (tek sefer).
  ///
  /// Faz C (Tek Asistan planı): eskiden transkript hem yayın scope'una hem
  /// scope'suz (şimdiki "local") anahtara ayrı ayrı yazılıyordu — tam olarak
  /// planın bitirdiği "iki geçmiş" sorunu. Artık tek scope'a yazılır: yayın
  /// varsa yayın scope'una (önce yereldeki geçmiş oraya taşınır), yoksa
  /// "local"a.
  Future<void> _handoffTranscriptToRehber() async {
    final service = ChatbotService();
    final rawScope = _onboarding.repairedPublicLink?.trim();
    final scope = (rawScope == null || rawScope.isEmpty) ? null : rawScope;
    if (scope != null) {
      await service.migrateLocalToPublishedScope(scope);
    }
    final transcript = _transcriptAsChatMessages();
    final existing = await service.loadHistory(scope: scope);
    if (existing.any((m) => m.snapshotStateKey == _kOnboardingHandoffMarker)) {
      return;
    }
    await service.saveHistory([...transcript, ...existing], scope: scope);
  }

  Future<void> _navigateAfterHandoff({
    int initialIndex = 0,
    VixRexAction? initialVixRexAction,
  }) async {
    await _handoffTranscriptToRehber();
    if (!mounted) return;
    if (widget.embeddedInShell && widget.onSetupComplete != null) {
      widget.onSetupComplete!();
      return;
    }
    AppRouter.navigateToHomeShell(
      context,
      initialIndex: initialIndex,
      initialVixRexAction: initialVixRexAction,
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  Future<void> _onSend() async {
    final accepted = await _onboarding.onSend(_inputController.text);
    if (accepted) _inputController.clear();
  }

  Future<void> _openPublicLink() async {
    final link = _onboarding.repairedPublicLink;
    if (link == null) return;
    final uri = Uri.tryParse(link);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vitrin linki açılamadı.')));
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tarayıcı açılamadı.')));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarayıcı açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _onboarding.step;
    final showInput =
        step == VixRexOnboardingStep.name ||
        step == VixRexOnboardingStep.whatsapp;

    final column = Column(
      children: [
        if (!widget.embeddedInShell) _buildTopBar(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            itemCount: _lines.length,
            itemBuilder: (context, index) => _ChatBubble(line: _lines[index]),
          ),
        ),
        if (_onboarding.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _onboarding.error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ),
        _buildComposer(showInput),
      ],
    );

    if (widget.embeddedInShell) {
      return ColoredBox(color: AppColors.bgEditor, child: column);
    }

    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      body: SafeArea(child: column),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ChatTopBar(
        avatarSize: 40,
        subtitle: 'Dijital vitrin asistanı',
        padding: EdgeInsets.zero,
        trailing: TextButton(
          onPressed:
              widget.onClose ?? () => AppRouter.navigateToLanding(context),
          child: const Text(
            'Kapat',
            style: TextStyle(color: AppColors.mutedText),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(bool showInput) {
    final step = _onboarding.step;
    final busy = _onboarding.busy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (step == VixRexOnboardingStep.welcome) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'Hızlı Seçenekler',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ChatPill(
              label: vixRexHizliSecenekler
                  .firstWhere((e) => e.id == 'hazir_vitrin_sec')
                  .etiket,
              icon: Icons.storefront_rounded,
              primary: true,
              onTap: busy ? null : _onboarding.chooseReadyTemplate,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChatPill(
                    label: vixRexHizliSecenekler
                        .firstWhere((e) => e.id == 'sifirdan_olustur')
                        .etiket,
                    icon: Icons.auto_awesome,
                    primary: false,
                    onTap: busy ? null : _onboarding.chooseScratch,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChatPill(
                    label: vixRexHizliSecenekler
                        .firstWhere((e) => e.id == 'bakiniyorum')
                        .etiket,
                    icon: Icons.visibility_outlined,
                    primary: false,
                    onTap: busy ? null : _onboarding.declineWelcome,
                  ),
                ),
              ],
            ),
          ],
          // Kategori seçimi — sohbetin içinde, ayrı ekrana götürmeden.
          if (step == VixRexOnboardingStep.category) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'İşini seç',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            KategoriSecici(busy: busy, onSelected: _onboarding.selectCategory),
          ],
          if (step == VixRexOnboardingStep.legal) ...[
            LegalConsentSection(
              canAccept: !_controller.isLoadingLegalDocuments,
              isLoading: _controller.isLoadingLegalDocuments,
              errorText: _controller.legalDocumentsError,
              privacyNoticeAcknowledged: _controller.privacyNoticeAcknowledged,
              termsAccepted: _controller.termsAccepted,
              publicationConsentAccepted:
                  _controller.publicationConsentAccepted,
              onPrivacyChanged: _controller.setPrivacyNoticeAcknowledged,
              onTermsChanged: _controller.setTermsAccepted,
              onPublicationChanged: _controller.setPublicationConsentAccepted,
              onReloadDocuments: _controller.reloadLegalDocuments,
              onOpenLegalPage:
                  (type) => AppRouter.navigateToLegal(context, type),
            ),
            const SizedBox(height: 10),
            _primaryButton(
              busy
                  ? 'Yayınlanıyor…'
                  : (_controller.isLegalPublishReady
                      ? 'Yayınla'
                      : 'Onayları işaretle'),
              busy || !_controller.isLegalPublishReady
                  ? null
                  : _onboarding.acceptLegalAndPublish,
            ),
          ],
          if (step == VixRexOnboardingStep.location) ...[
            // showAdvancedFields: false — Hero Konum Metni ve Harita Kartı
            // Etiketi manuel panele özel alanlardır (PR #70); asistan
            // sohbeti yalnız il/ilçe/adres sorar, kapsam dışına çıkmaz
            // (2026-08-12 bulgusu).
            FormLocationInfo(
              controller: _controller,
              state: _vitrinState,
              addressController: _addressController,
              heroLocationTextController: _heroLocationTextController,
              mapLabelController: _mapLabelController,
              showAdvancedFields: false,
            ),
            const SizedBox(height: 10),
            _primaryButton(
              'Konumu onayla, devam',
              (busy || _onboarding.konumEksigi != null)
                  ? null
                  : _onboarding.confirmLocationFromEditor,
            ),
            if (_onboarding.konumEksigi != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Devam etmek için: ${_onboarding.konumEksigi!}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (showInput)
            ChatComposer(
              controller: _inputController,
              focusNode: _inputFocus,
              enabled: !busy,
              // Ad/WhatsApp/konum girişi — genel sohbet sorusu değil,
              // ChatComposer'ın varsayılan "Vixrex'e sor…" ipucu burada
              // yanıltıcı olur.
              hintText: '',
              onSubmit: (_) => _onSend(),
            ),
          // TEK ASİSTAN (C2): birincil yol vitrini AÇIP birlikte devam
          // etmek. Manuel panel ikincil kalıyor — silinmedi, yerinde
          // duruyor (VIXREX_RULES §1) ama artık varsayılan değil.
          if (step == VixRexOnboardingStep.done) ...[
            if (_onboarding.hesapKorumasiz) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppColors.radius14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Vitrinini hesabına bağla',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Şu an vitrinin bu cihaza bağlı. Telefonunu '
                      'değiştirirsen ya da tarayıcı verilerini silersen '
                      'erişimini kaybedersin.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _onboarding.hesabiBagla,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Google ile bağla'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            _primaryButton(
              busy ? 'Vitrinin açılıyor…' : 'Vitrinini aç',
              busy
                  ? null
                  : () => _onboarding.openOwnerWorkspace(
                    visibleMessages: _lines.map(
                      (line) =>
                          line.isBot
                              ? AssistantHandoffMessage.assistant(line.text)
                              : AssistantHandoffMessage.user(line.text),
                    ),
                  ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _navigateAfterHandoff(initialIndex: 2),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                minimumSize: const Size.fromHeight(40),
              ),
              child: const Text(
                'Detaylı formu aç',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
          if (step == VixRexOnboardingStep.publishing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radius12),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ChatLine {
  final String text;
  final bool isBot;
  final String? publicLink;
  final VoidCallback? onOpenPublicLink;

  const _ChatLine.bot(this.text, {this.publicLink, this.onOpenPublicLink})
    : isBot = true;
  const _ChatLine.user(this.text)
    : isBot = false,
      publicLink = null,
      onOpenPublicLink = null;
}

class _ChatBubble extends StatelessWidget {
  final _ChatLine line;
  const _ChatBubble({required this.line});

  bool get _hasPublicLink =>
      line.publicLink != null && line.onOpenPublicLink != null;

  @override
  Widget build(BuildContext context) {
    final align = line.isBot ? Alignment.centerLeft : Alignment.centerRight;

    return Align(
      alignment: align,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child:
            line.isBot
                ? ChatBubble.bot(
                  text: line.text,
                  footer: _hasPublicLink ? _publicLinkFooter() : null,
                )
                : ChatBubble.user(text: line.text),
      ),
    );
  }

  // TEK KAPI (bulgu 8).
  //
  // Burada eskiden birincil bir "Canlı vitrini aç" düğmesi vardı; aşağıda
  // da "Vitrinimi birlikte düzenleyelim". İkisi de aynı sayfayı açıyordu.
  // Esnaf önce bakıyor, geri dönüyor, sonra ikinci düğmeye basıyordu — tek
  // iş için iki yolculuk.
  //
  // Artık asıl kapı aşağıdaki "Vitrinini aç" (sahip modunda). Burası
  // ikincil kaldı ve işi değişti: müşterinin gördüğü hâli göstermek
  // (bulgu 7 — sahip kendi vitrinini müşteri gözüyle göremiyordu).
  Widget _publicLinkFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: line.onOpenPublicLink,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColors.radius10),
              ),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: const Text(
              'Müşterinin gördüğü hâli',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          line.publicLink!,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
