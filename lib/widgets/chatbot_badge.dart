import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_guidance_service.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';

const double _vixrexBadgeSize = 60;

class ChatbotBadge extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final bool hasShared;
  final bool isLoading;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(VixRexAction)? onScrollToAction;
  final List<ChatMessage>? chatHistory;

  /// Verilirse eski FAQ overlay açılmaz; mevcut asistan/kapıya gider.
  final VoidCallback? onOpen;

  const ChatbotBadge({
    super.key,
    this.snapshot,
    this.hasShared = false,
    this.isLoading = false,
    this.chatHistory,
    this.onNavigateToVitrim,
    this.onNavigateToExplore,
    this.onCopyLink,
    this.onShowQr,
    this.onShareWhatsapp,
    this.onScrollToAction,
    this.onOpen,
  });

  @override
  State<ChatbotBadge> createState() => _ChatbotBadgeState();
}

class _ChatbotBadgeState extends State<ChatbotBadge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnim;
  late Animation<double> _scanAnim;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanAnim = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.linear),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context) {
    widget.onOpen?.call();
  }

  String? get _bubbleMessage {
    if (widget.isLoading) return null;
    final snapshot = widget.snapshot;
    if (snapshot == null || !snapshot.isPublished) {
      return '👋 Dijital vitrinini hazırlayayım mı?';
    }

    final cat = snapshot.category.trim().toLowerCase();
    if (cat.isEmpty || cat == 'diger' || cat == 'diğer') {
      return 'Sıradaki adım: Kategorini seç';
    }

    final rec = VixRexGuidanceService.recommendationFor(
      snapshot: snapshot,
      hasShared: widget.hasShared,
    );

    if (rec.id == 'all_done') {
      return '✨ Vitrinin harika görünüyor!';
    }
    return 'Sıradaki adım: ${rec.title}';
  }

  @override
  Widget build(BuildContext context) {
    final bubbleText = _bubbleMessage;

    return GestureDetector(
      onTap: () => _openChat(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Notification Speech Bubble Tooltip
          if (bubbleText != null && bubbleText.isNotEmpty)
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatAnim.value),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0E1B2E),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(3),
                      ),
                      border: Border.all(
                        color: const Color(0xFF0EA5E9).withAlpha(180),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0EA5E9).withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bubbleText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          // Floating Mascot Badge
          AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _scanController]),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Image.asset(
                'assets/images/vixrex_v_crystal_mascot.png',
                width: _vixrexBadgeSize,
                height: _vixrexBadgeSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/vixrex_mascot.webp',
                    width: _vixrexBadgeSize,
                    height: _vixrexBadgeSize,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            builder: (context, mascot) {
              return Container(
                width: _vixrexBadgeSize,
                height: _vixrexBadgeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0E1B2E).withAlpha(200),
                  border: Border.all(color: const Color(0xFF38A0E4).withAlpha(160), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withAlpha((255 * 0.45 * _pulseAnim.value).round()),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      mascot!,
                      Positioned(
                        top: (_vixrexBadgeSize / 2) +
                            (_scanAnim.value * (_vixrexBadgeSize * 0.35)),
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 1.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x000EA5E9),
                                Color(0xCC0EA5E9),
                                Color(0x000EA5E9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xCC10B981),
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
        ],
      ),
    );
  }
}

