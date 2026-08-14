import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/chat/chat_progress.dart';

class VixRexScoreBar extends StatefulWidget {
  final int score; // 0–100
  const VixRexScoreBar({super.key, required this.score});

  @override
  State<VixRexScoreBar> createState() => _VixRexScoreBarState();
}

class _VixRexScoreBarState extends State<VixRexScoreBar>
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
    _fillAnim = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    return const Color(0xFFEF4444); // kırmızı
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor(widget.score);
    return AnimatedBuilder(
      animation: _fillAnim,
      builder:
          (_, __) => ChatProgress(
            leading: const Text(
              'Vitrin skoru',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Text(
              '%${(widget.score * _fillAnim.value).round()}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            progress: _fillAnim.value,
            color: color,
            trackColor: AppColors.border,
          ),
    );
  }
}
