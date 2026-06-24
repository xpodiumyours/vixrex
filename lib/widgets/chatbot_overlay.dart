import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vitrinx/config/chatbot_config.dart';
import 'package:vitrinx/models/chat_message.dart';
import 'package:vitrinx/services/chatbot_service.dart';
import 'package:vitrinx/services/xrex_profile_snapshot.dart';
import 'package:vitrinx/theme/app_colors.dart';

// ─── Robot Rozet (Sol Kenar) ─────────────────────────────────────────────────
class ChatbotBadge extends StatefulWidget {
  /// Anlık vitrin snapshot'ı. null ise genel karşılama gösterilir.
  final XrexProfileSnapshot? snapshot;

  /// Vitrinim sekmesine git callback'i.
  final VoidCallback? onNavigateToVitrim;

  /// Keşfet sekmesine git callback'i.
  final VoidCallback? onNavigateToExplore;

  /// Public linki kopyala callback'i.
  final VoidCallback? onCopyLink;

  /// QR bottom sheet callback'i.
  final VoidCallback? onShowQr;

  /// WhatsApp paylaşım callback'i.
  final VoidCallback? onShareWhatsapp;

  /// Sayfa içi kaydırma callback'i.
  final void Function(XrexAction)? onScrollToAction;

  const ChatbotBadge({
    super.key,
    this.snapshot,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
  });

  @override
  State<ChatbotBadge> createState() => _ChatbotBadgeState();
}

class _ChatbotBadgeState extends State<ChatbotBadge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scanAnim;
  bool _blinking = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    // Pulsing halka
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scan line
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    // Göz kırpma
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _blinking = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _blinking = false);
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  void _openChat(BuildContext context) {
    XrexOverlay.show(
      context,
      snapshot: widget.snapshot,
      onNavigateToVitrim: widget.onNavigateToVitrim,
      onNavigateToExplore: widget.onNavigateToExplore,
      onCopyLink: widget.onCopyLink,
      onShowQr: widget.onShowQr,
      onShareWhatsapp: widget.onShareWhatsapp,
      onScrollToAction: widget.onScrollToAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openChat(context),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _scanController]),
        builder: (context, child) {
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.primary.withAlpha((255 * _pulseAnim.value).round()),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((255 * 0.35 * _pulseAnim.value).round()),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Robot yüzü
                  CustomPaint(
                    size: const Size(52, 52),
                    painter: _RobotFacePainter(blinking: _blinking),
                  ),
                  // Scan line
                  Positioned(
                    top: 26 + (_scanAnim.value * 26),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      color: AppColors.primary.withAlpha(60),
                    ),
                  ),
                  // LED aktif göstergesi
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withAlpha(180),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Robot Yüzü CustomPainter ────────────────────────────────────────────────
class _RobotFacePainter extends CustomPainter {
  final bool blinking;
  const _RobotFacePainter({required this.blinking});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Arka plan
    canvas.drawCircle(
      Offset(cx, cy),
      size.width / 2,
      Paint()..color = const Color(0xFFF4F5F8),
    );

    // Kafa kutusu
    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 30, height: 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      faceRect,
      Paint()
        ..color = const Color(0xFFE2ECF0)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      faceRect,
      Paint()
        ..color = AppColors.primary.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Anten
    final antennaPaint = Paint()
      ..color = AppColors.primaryDark
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, cy - 13), Offset(cx, cy - 19), antennaPaint);
    canvas.drawCircle(Offset(cx, cy - 20), 2, Paint()..color = AppColors.primary);

    // Gözler
    final eyePaint = Paint()..color = AppColors.primary;
    final eyeHeight = blinking ? 1.0 : 5.0;

    // Sol göz
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx - 6, cy - 1),
          width: 7,
          height: eyeHeight,
        ),
        const Radius.circular(2),
      ),
      eyePaint,
    );
    // Sağ göz
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 6, cy - 1),
          width: 7,
          height: eyeHeight,
        ),
        const Radius.circular(2),
      ),
      eyePaint,
    );

    // Göz içi ışıltı
    if (!blinking) {
      canvas.drawCircle(
        Offset(cx - 4.5, cy - 2),
        1,
        Paint()..color = Colors.white.withAlpha(180),
      );
      canvas.drawCircle(
        Offset(cx + 7.5, cy - 2),
        1,
        Paint()..color = Colors.white.withAlpha(180),
      );
    }

    // Ağız (küçük çizgi)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 6), width: 10, height: 2),
        const Radius.circular(1),
      ),
      Paint()..color = AppColors.primaryDark.withAlpha(120),
    );
  }

  @override
  bool shouldRepaint(_RobotFacePainter old) => old.blinking != blinking;
}

// ─── Xrex Overlay Panel ──────────────────────────────────────────────────────
class XrexOverlay {
  static OverlayEntry? _entry;

  /// [snapshot] varsa Xrex kişiselleştirilmiş karşılama gösterir.
  /// Callback'ler action butonlarını ilgili ekrana bağlar.
  static void show(
    BuildContext context, {
    XrexProfileSnapshot? snapshot,
    VoidCallback? onNavigateToVitrim,
    VoidCallback? onNavigateToExplore,
    VoidCallback? onCopyLink,
    VoidCallback? onShowQr,
    VoidCallback? onShareWhatsapp,
    void Function(XrexAction)? onScrollToAction,
  }) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => _XrexPanelWrapper(
        onClose: close,
        snapshot: snapshot,
        onNavigateToVitrim: onNavigateToVitrim,
        onNavigateToExplore: onNavigateToExplore,
        onCopyLink: onCopyLink,
        onShowQr: onShowQr,
        onShareWhatsapp: onShareWhatsapp,
        onScrollToAction: onScrollToAction,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  static void close() {
    _entry?.remove();
    _entry = null;
  }
}

class _XrexPanelWrapper extends StatefulWidget {
  final VoidCallback onClose;
  final XrexProfileSnapshot? snapshot;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(XrexAction)? onScrollToAction;

  const _XrexPanelWrapper({
    required this.onClose,
    this.snapshot,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
  });

  @override
  State<_XrexPanelWrapper> createState() => _XrexPanelWrapperState();
}

class _XrexPanelWrapperState extends State<_XrexPanelWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _slideController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = screenWidth * 0.82;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _close,
            child: Container(color: AppColors.darkText.withAlpha(40)),
          ),
          SlideTransition(
            position: _slideAnim,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: panelWidth,
                height: double.infinity,
                child: _XrexPanel(
                  onClose: _close,
                  snapshot: widget.snapshot,
                  onNavigateToVitrim: widget.onNavigateToVitrim,
                  onNavigateToExplore: widget.onNavigateToExplore,
                  onCopyLink: widget.onCopyLink,
                  onShowQr: widget.onShowQr,
                  onShareWhatsapp: widget.onShareWhatsapp,
                  onScrollToAction: widget.onScrollToAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel İçeriği ───────────────────────────────────────────────────────────
class _XrexPanel extends StatefulWidget {
  final VoidCallback onClose;
  final XrexProfileSnapshot? snapshot;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(XrexAction)? onScrollToAction;

  const _XrexPanel({
    required this.onClose,
    this.snapshot,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
  });

  @override
  State<_XrexPanel> createState() => _XrexPanelState();
}

class _XrexPanelState extends State<_XrexPanel> with TickerProviderStateMixin {
  final ChatbotService _service = ChatbotService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late AnimationController _scanController;
  late Animation<double> _scanAnim;
  bool _blinking = false;
  Timer? _blinkTimer;
  bool _cursorVisible = true;
  Timer? _cursorTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    // Scan line
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(_scanController);

    // Göz kırpma
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _blinking = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _blinking = false);
      });
    });

    // İmleç
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    // Karşılama mesajı: snapshot varsa kişiselleştirilmiş, yoksa genel
    final snapshot = widget.snapshot;
    if (snapshot != null) {
      _addBotMessage(_service.respondWithSnapshot(snapshot));
    } else {
      _addBotMessage(ChatbotConfig.welcomeMessage);
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _blinkTimer?.cancel();
    _cursorTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addBotMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    final userMsg = ChatMessage.user(text.trim());
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(_service.respond(text.trim()));
    });
  }

  void _onQuickReply(QuickReply reply) {
    // Action routing: navigasyon aksiyonu varsa önce callback'i çağır
    if (reply.action != XrexAction.none) {
      _handleAction(reply.action);
      return;
    }

    final userMsg = ChatMessage.user(reply.label);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTyping = false);
      _addBotMessage(_service.respondToPayload(reply.payload));
    });
  }

  /// Aksiyona göre ilgili callback'i çağırır ve paneli kapatır.
  void _handleAction(XrexAction action) {
    // Callback referanslarını önceden al (panel kapandıktan sonra widget
    // unmount olabilir, bu yüzden doğrudan widget'a erişemeyiz)
    final onVitrim   = widget.onNavigateToVitrim;
    final onExplore  = widget.onNavigateToExplore;
    final onCopy     = widget.onCopyLink;
    final onQr       = widget.onShowQr;
    final onWhatsapp = widget.onShareWhatsapp;
    final onScroll   = widget.onScrollToAction;

    // onClose void döndürür — Future.delayed ile animasyon süresini bekle
    widget.onClose();
    Future.delayed(const Duration(milliseconds: 320), () {
      switch (action) {
        case XrexAction.openVitrim:
          onVitrim?.call();
          break;
        case XrexAction.openExplore:
          onExplore?.call();
          break;
        case XrexAction.copyLink:
          onCopy?.call();
          break;
        case XrexAction.showQr:
          onQr?.call();
          break;
        case XrexAction.shareWhatsapp:
          onWhatsapp?.call();
          break;
        case XrexAction.scrollToCover:
        case XrexAction.scrollToGallery:
        case XrexAction.scrollToName:
        case XrexAction.scrollToWhatsapp:
        case XrexAction.scrollToAddress:
        case XrexAction.scrollToDesc:
        case XrexAction.scrollToProducts:
          onScroll?.call(action);
          break;
        case XrexAction.none:
          break;
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastMsg = _messages.isNotEmpty ? _messages.last : null;
    final quickReplies = (lastMsg?.isBot == true) ? lastMsg!.quickReplies : <QuickReply>[];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkText.withAlpha(25),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Başlık ──────────────────────────────────────────────────
            _buildHeader(),
            // ── Robot Avatar ────────────────────────────────────────────
            _buildAvatar(),
            const Divider(color: AppColors.border, height: 1),
            // ── Mesajlar ────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_isTyping && i == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageRow(_messages[i]);
                },
              ),
            ),
            // ── Quick Replies ───────────────────────────────────────────
            if (quickReplies.isNotEmpty) _buildQuickReplies(quickReplies),
            const Divider(color: AppColors.border, height: 1),
            // ── Giriş Alanı ─────────────────────────────────────────────
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.bgEditor,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.success.withAlpha(180), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            ChatbotConfig.botName,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ChatbotConfig.systemStatus,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: const Icon(Icons.close_rounded, color: AppColors.mutedText, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        return Container(
          color: AppColors.bgEditor,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Robot mini avatar
              SizedBox(
                width: 44,
                height: 44,
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(44, 44),
                        painter: _RobotFacePainter(blinking: _blinking),
                      ),
                      Positioned(
                        top: 22 + (_scanAnim.value * 22),
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1.5,
                          color: AppColors.primary.withAlpha(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ChatbotConfig.botName,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ChatbotConfig.botSubtitle,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageRow(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: msg.isBot ? _buildBotMessage(msg) : _buildUserMessage(msg),
    );
  }

  Widget _buildBotMessage(ChatMessage msg) {
    final lines = msg.text.split('\n');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('X', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bgEditor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...lines.map((line) {
                  if (line.isEmpty) return const SizedBox(height: 4);
                  final isCursor = !_isTyping && lines.last == line;
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: line,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontSize: 12.5,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (isCursor && _cursorVisible)
                          const TextSpan(
                            text: ' ▌',
                            style: TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                      ],
                    ),
                  );
                }),
                // ── [İyileştirme #1] Skor çubuğu ────────────────────────
                if (msg.snapshotScore != null) ...
                  [
                    const SizedBox(height: 10),
                    _XrexScoreBar(score: msg.snapshotScore!),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(ChatMessage msg) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.ctaGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('X', style: TextStyle(color: AppColors.primaryDark, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgEditor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Analiz ediliyor...',
              style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(List<QuickReply> replies) {
    return Container(
      color: AppColors.bgEditor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((r) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _onQuickReply(r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.ctaGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 12.5,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Bir şey sorun...',
                  hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 12.5),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_inputCtrl.text),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: AppColors.ctaGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── [İyileştirme #1] Animasyonlu Skor Çubuğu ───────────────────────────────
class _XrexScoreBar extends StatefulWidget {
  final int score; // 0–100
  const _XrexScoreBar({required this.score});

  @override
  State<_XrexScoreBar> createState() => _XrexScoreBarState();
}

class _XrexScoreBarState extends State<_XrexScoreBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fillAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fillAnim = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _barColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E); // yeşil
    if (score >= 50) return const Color(0xFFF59E0B); // sarı
    return const Color(0xFFEF4444);                  // kırmızı
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor(widget.score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vitrin skoru',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            AnimatedBuilder(
              animation: _fillAnim,
              builder: (_, __) => Text(
                '%${(widget.score * _fillAnim.value).round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AnimatedBuilder(
            animation: _fillAnim,
            builder: (_, __) => LinearProgressIndicator(
              value: _fillAnim.value,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore_for_file: unused_element
// Kullanılmayan math import uyarısını bastır
final _mathRef = math.pi;
// Kullanılmayan services import uyarısını bastır
final _servicesRef = HapticFeedback.selectionClick;
