import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_profile_snapshot.dart';
import 'package:vixrex/theme/app_colors.dart';

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

  /// Verilirse eski FAQ overlay açılmaz; mevcut asistan/kapıya gider.
  final VoidCallback? onOpen;

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
    this.onOpen,
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
    widget.onOpen?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openChat(context),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _scanController]),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/vixrex_mascot.webp',
            width: _vixrexBadgeSize,
            height: _vixrexBadgeSize,
            fit: BoxFit.contain,
          ),
        ),
        builder: (context, mascot) {
          return Container(
            width: _vixrexBadgeSize,
            height: _vixrexBadgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(20),
              border: Border.all(color: AppColors.primary.withAlpha(40), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha((255 * 0.35 * _pulseAnim.value).round()),
                  blurRadius: 18,
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
                        (_scanAnim.value * (_vixrexBadgeSize * 0.4)),
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(0),
                            AppColors.primary.withAlpha(120),
                            AppColors.primary.withAlpha(0),
                          ],
                        ),
                      ),
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
