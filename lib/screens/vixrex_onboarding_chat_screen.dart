import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/app_router.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/screens/my_vitrin/my_vitrin_state.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';
import 'package:vixrex/widgets/editor/form_location_info.dart';
import 'package:vixrex/widgets/editor/legal_consent_section.dart';

/// Rehber sohbet geçmişine onboarding transcript yazıldığını işaretler (çift yazmayı engeller).
const String _kOnboardingHandoffMarker = 'onboarding_handoff_v1';

enum _OnboardingStep {
  welcome,
  name,
  whatsapp,
  location,
  legal,
  publishing,
  done,
}

/// Faz 2: HTML örneğindeki varlık sohbeti (ad / WA / konum → yayın → link).
/// Landing’deki işletme adı alanı [initialName] ile gelir (home shell ile aynı fikir).
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
  late final MyVitrinState _vitrinState;
  late final bool _ownsController;
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _addressController = TextEditingController();
  final _inputFocus = FocusNode();

  final List<_ChatLine> _lines = [];
  _OnboardingStep _step = _OnboardingStep.welcome;
  bool _busy = false;
  String? _error;
  String? _publicLink;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.editorController == null;
    _controller = widget.editorController ?? StoreEditorController();
    _vitrinState = MyVitrinState(controller: _controller);
    _controller.addListener(_onControllerTick);
    _bootstrap();
  }

  void _onControllerTick() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    final savedData = await _controller.storage.loadVitrinData();
    final hasSavedVitrin = savedData?.name.trim().isNotEmpty == true;
    final sharedInitialization = widget.editorInitialization;
    if (sharedInitialization != null) {
      await sharedInitialization;
    } else if (_ownsController) {
      await _controller.initialize(widget.initialName);
    }
    if (!mounted) return;
    if (hasSavedVitrin) {
      _resumeSavedVitrin();
      return;
    }
    _pushBot(
      'Merhaba, ben Vixrex.\n\n'
      'Sana dijital bir vitrin oluşturmamı ister misin?',
    );
    setState(() {});
  }

  void _resumeSavedVitrin() {
    final snapshot = VixRexProfileSnapshot.from(
      _controller.data,
      _controller.publishedInfo,
    );
    final storeName = snapshot.storeName;

    _pushBot(
      'Tekrar hoş geldin, $storeName.\n\n'
      'Kayıtlı vitrinin bulundu. Yeni bir vitrin oluşturmuyoruz; '
      'kaldığın yerden devam ediyoruz.',
    );

    switch (snapshot.nextMissingField) {
      case VixRexNextStep.name:
        setState(() => _step = _OnboardingStep.name);
        _pushBot('İşletme adını tamamlayalım.');
        _focusInput();
      case VixRexNextStep.whatsapp:
        setState(() => _step = _OnboardingStep.whatsapp);
        _pushBot('Sıradaki adım: WhatsApp numaranı ekleyelim.');
        _focusInput();
      case VixRexNextStep.address:
        setState(() => _step = _OnboardingStep.location);
        _pushBot('Sıradaki adım: adres ve konum bilgini tamamlayalım.');
      case VixRexNextStep.legal:
        setState(() => _step = _OnboardingStep.legal);
        _pushBot('Sıradaki adım: yasal yayınlama onaylarını tamamlayalım.');
      case VixRexNextStep.publish:
        setState(() => _step = _OnboardingStep.legal);
        _pushBot('Bilgilerin hazır. Sıradaki adım vitrini yayınlamak.');
      case VixRexNextStep.share:
        _publicLink = snapshot.publicLink;
        setState(() => _step = _OnboardingStep.done);
        _pushBot(
          'Vitrinin yayında. Şimdi görünümünü ve ürünlerini geliştirmeye '
          'devam edebiliriz.',
          publicLink: _repairedPublicLink,
        );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerTick);
    _vitrinState.dispose();
    if (_ownsController) _controller.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _addressController.dispose();
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
    _scrollToEnd();
  }

  void _pushUser(String text) {
    _lines.add(_ChatLine.user(text));
    _scrollToEnd();
  }

  List<ChatMessage> _transcriptAsChatMessages() {
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
          snapshotStateKey: isLast ? _kOnboardingHandoffMarker : null,
        ),
      );
    }
    if (out.isEmpty) {
      out.add(
        ChatMessage.bot(
          'Kurulum sohbeti tamamlandı.',
          snapshotStateKey: _kOnboardingHandoffMarker,
        ),
      );
    }
    return out;
  }

  /// Onboarding balonlarını mevcut rehber history’sine yazar (tek sefer).
  Future<void> _handoffTranscriptToRehber() async {
    final service = ChatbotService();
    final existing = await service.loadHistory();
    if (existing.any((m) => m.snapshotStateKey == _kOnboardingHandoffMarker)) {
      return;
    }
    final transcript = _transcriptAsChatMessages();
    await service.saveHistory([...transcript, ...existing]);
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

  Future<void> _acceptWelcome() async {
    _pushUser('Evet, oluşturalım');
    setState(() => _error = null);

    final existingName = _controller.data.name.trim();
    if (existingName.length >= 2) {
      _pushUser(existingName);
      setState(() => _step = _OnboardingStep.whatsapp);
      _pushBot('Müşteriler seni nasıl bulsun?\nWhatsApp numaranı yaz.');
      _focusInput();
      return;
    }

    setState(() => _step = _OnboardingStep.name);
    _pushBot('Harika. İşletmenin adı ne?');
    _focusInput();
  }

  void _declineWelcome() {
    _pushUser('Şimdilik bakınıyorum');
    _pushBot('Tamam. Hazır olunca buradayım.');
    setState(() => _step = _OnboardingStep.welcome);
  }

  Future<void> _submitName(String raw) async {
    final name = raw.trim();
    if (name.length < 2) {
      setState(() => _error = 'İşletme adını en az 2 karakter yaz.');
      return;
    }
    _pushUser(name);
    _controller.updateName(name);
    await _controller.saveLocally();
    setState(() {
      _step = _OnboardingStep.whatsapp;
      _error = null;
      _inputController.clear();
    });
    _pushBot('Müşteriler seni nasıl bulsun?\nWhatsApp numaranı yaz.');
    _focusInput();
  }

  Future<void> _submitWhatsapp(String raw) async {
    final normalized = WhatsAppLinkHelper.normalizeTurkeyMobile(raw);
    if (normalized == null) {
      setState(() => _error = WhatsAppLinkHelper.invalidNumberMessage);
      return;
    }
    _pushUser(raw.trim());
    _controller.updateWhatsapp(normalized);
    await _controller.saveLocally();
    setState(() {
      _step = _OnboardingStep.location;
      _error = null;
      _inputController.clear();
    });
    _pushBot(
      'İşletmen nerede?\n'
      'Aşağıda profil editöründeki konum alanını kullan — '
      'GPS veya il/ilçe/adres.',
    );
  }

  Future<void> _confirmLocationFromEditor() async {
    final data = _controller.data;
    if (data.provinceCode.trim().isEmpty ||
        data.districtName.trim().isEmpty ||
        data.address.trim().isEmpty) {
      setState(
        () => _error = 'İl, ilçe ve adres gerekli. GPS veya listeden seç.',
      );
      return;
    }
    final label =
        '${data.districtName}, ${data.provinceName} — ${data.address}';
    _pushUser(label);
    await _controller.saveLocally();
    if (!mounted) return;
    setState(() {
      _step = _OnboardingStep.legal;
      _error = null;
    });
    _pushBot(
      'Son adım: editördeki yasal onayları işaretle, sonra yayınla.\n'
      'Kısa tutuyoruz.',
    );
  }

  Future<void> _acceptLegalAndPublish() async {
    if (_busy) return;
    if (!_controller.isLegalPublishReady) {
      setState(() => _error = 'Yayın için aşağıdaki yasal onayları işaretle.');
      return;
    }
    _pushUser('Yayınla');
    setState(() {
      _busy = true;
      _error = null;
      _step = _OnboardingStep.publishing;
    });
    _pushBot('Vitrinin hazırlanıyor…');

    try {
      await _controller.saveLocally();
      final link = await _controller.publish();
      if (!mounted) return;
      if (link == null || link.trim().isEmpty) {
        setState(() {
          _busy = false;
          _step = _OnboardingStep.legal;
          _error = 'Yayın tamamlanamadı. Tekrar dene.';
        });
        _pushBot('Bir sorun oluştu. Tekrar deneyebilirsin.');
        return;
      }
      _publicLink = link.trim();
      setState(() {
        _busy = false;
        _step = _OnboardingStep.done;
      });
      _pushBot(
        'İşte bu kadar.\nArtık dijitalde varsın.\n\n'
        'İşletme adına özel vitrinin hazır. Web siten var — domain masrafın yok.',
        publicLink: _repairedPublicLink,
      );
      _pushBot(
        'Sırada görünüm ve ürünler var.\n'
        'Kapak şablonunu seç; galeri, açıklama, ürün ve fiş tarayıcı '
        'için VixRex rehberinde devam et.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _step = _OnboardingStep.legal;
        _error = e.toString().replaceFirst('StorePublishException: ', '');
      });
      _pushBot(
        'Yayın şu an tamamlanamadı.\n'
        'Tekrar dene. Devam etmezse ekrandaki kırmızı hata metnini bana gönder.',
      );
    }
  }

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  Future<void> _onSend() async {
    final text = _inputController.text;
    switch (_step) {
      case _OnboardingStep.name:
        await _submitName(text);
      case _OnboardingStep.whatsapp:
        await _submitWhatsapp(text);
      default:
        break;
    }
  }

  String? get _repairedPublicLink {
    final raw = _publicLink?.trim() ?? '';
    if (raw.isEmpty) return null;
    return PublicSiteConfig.repairPublicLink(raw);
  }

  Future<void> _openPublicLink() async {
    final link = _repairedPublicLink;
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
    final showInput =
        _step == _OnboardingStep.name || _step == _OnboardingStep.whatsapp;

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
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error!,
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0E1B2E),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withAlpha(180),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withAlpha(80),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/vixrex_v_crystal_mascot.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/vixrex_mascot.webp',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vixrex',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Dijital vitrin asistanı',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed:
                widget.onClose ??
                () => AppRouter.navigateToLanding(context),
            child: const Text(
              'Kapat',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(bool showInput) {
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
          if (_step == _OnboardingStep.welcome) ...[
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _busy ? null : _acceptWelcome,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withAlpha(90),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Evet, Oluşturalım',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _busy ? null : _declineWelcome,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: const Color(0xFF0E1B2E),
                      border: Border.all(
                        color: const Color(0xFF38A0E4).withAlpha(120),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_outlined, size: 14, color: AppColors.mutedText),
                        SizedBox(width: 6),
                        Text(
                          'Bakınıyorum',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_step == _OnboardingStep.legal) ...[
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
              _busy
                  ? 'Yayınlanıyor…'
                  : (_controller.isLegalPublishReady
                      ? 'Yayınla'
                      : 'Onayları işaretle'),
              _busy || !_controller.isLegalPublishReady
                  ? null
                  : _acceptLegalAndPublish,
            ),
          ],
          if (_step == _OnboardingStep.location) ...[
            FormLocationInfo(
              controller: _controller,
              state: _vitrinState,
              addressController: _addressController,
            ),
            const SizedBox(height: 10),
            _primaryButton(
              'Konumu onayla, devam',
              _busy ? null : _confirmLocationFromEditor,
            ),
            const SizedBox(height: 8),
          ],
          if (showInput)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _inputFocus,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 15,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSend(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    minimumSize: const Size(88, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            ),
          if (_step == _OnboardingStep.done)
            _primaryButton('Vixrex ile geliştir', () {
              _navigateAfterHandoff(initialIndex: 2);
            }),
          if (_step == _OnboardingStep.publishing)
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final align = line.isBot ? Alignment.centerLeft : Alignment.centerRight;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        decoration: BoxDecoration(
          color:
              line.isBot
                  ? AppColors.surfaceSoft
                  : AppColors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(line.isBot ? 4 : 16),
            bottomRight: Radius.circular(line.isBot ? 16 : 4),
          ),
          border: Border.all(
            color:
                line.isBot
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              line.text,
              style: const TextStyle(
                color: AppColors.darkTextAlt,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            if (line.publicLink != null && line.onOpenPublicLink != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: line.onOpenPublicLink,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text(
                    'Canlı vitrini aç',
                    style: TextStyle(fontWeight: FontWeight.w800),
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
          ],
        ),
      ),
    );
  }
}
