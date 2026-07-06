import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/vixrex_panel.dart';

const double _vixrexBadgeSize = 84;

class ChatbotBadge extends StatefulWidget {
  final VixRexProfileSnapshot? snapshot;
  final VoidCallback? onNavigateToVitrim;
  final VoidCallback? onNavigateToExplore;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShowQr;
  final VoidCallback? onShareWhatsapp;
  final void Function(VixRexAction)? onScrollToAction;
  final List<ChatMessage>? chatHistory;

  const ChatbotBadge({
    super.key,
    this.snapshot,
    this.chatHistory,
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context) {
    VixRexOverlay.show(
      context,
      snapshot: widget.snapshot,
      chatHistory: widget.chatHistory,
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
        child: Image.asset(
          'assets/images/vixrex_mascot.webp',
          width: _vixrexBadgeSize,
          height: _vixrexBadgeSize,
          fit: BoxFit.cover,
        ),
        builder: (context, mascot) {
          return Container(
            width: _vixrexBadgeSize,
            height: _vixrexBadgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((255 * 0.25 * _pulseAnim.value).round()),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  mascot!,
                  Positioned(
                    top:
                        (_vixrexBadgeSize / 2) +
                        (_scanAnim.value * (_vixrexBadgeSize / 2)),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      color: AppColors.primary.withAlpha(60),
                    ),
                  ),
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

class VixRexOverlay {
  static OverlayEntry? _entry;

  static void show(
    BuildContext context, {
    VixRexProfileSnapshot? snapshot,
    List<ChatMessage>? chatHistory,
    VoidCallback? onNavigateToVitrim,
    VoidCallback? onNavigateToExplore,
    VoidCallback? onCopyLink,
    VoidCallback? onShowQr,
    VoidCallback? onShareWhatsapp,
    void Function(VixRexAction)? onScrollToAction,
  }) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => VixRexPanelWrapper(
        onClose: close,
        snapshot: snapshot,
        chatHistory: chatHistory,
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
