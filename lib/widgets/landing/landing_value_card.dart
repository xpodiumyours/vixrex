import 'package:flutter/material.dart';
import 'package:vixrex/theme/app_colors.dart';

class LandingValueCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final bool isHorizontal;
  final bool enableHover;

  const LandingValueCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    this.isHorizontal = false,
    this.enableHover = true,
  });

  @override
  State<LandingValueCard> createState() => _LandingValueCardState();
}

class _LandingValueCardState extends State<LandingValueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shouldLift = widget.enableHover && _hovered;
    final icon = Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(widget.icon, color: widget.color, size: 26),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.desc,
          style: const TextStyle(
            color: AppColors.darkTextAlt,
            fontSize: 16,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: widget.isHorizontal ? 420 : 260,
        transform: shouldLift
            ? (Matrix4.identity()..translate(0.0, -6.0)..scale(1.01))
            : Matrix4.identity(),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.85),
            width: 1.2,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.16),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: widget.isHorizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 15),
                  Expanded(child: content),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [icon, const SizedBox(height: 18), content],
              ),
      ),
    );
  }
}
