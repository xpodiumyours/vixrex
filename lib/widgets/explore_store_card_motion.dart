import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExploreStoreCardMotion extends StatefulWidget {
  const ExploreStoreCardMotion({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<ExploreStoreCardMotion> createState() => _ExploreStoreCardMotionState();
}

class _ExploreStoreCardMotionState extends State<ExploreStoreCardMotion>
    with SingleTickerProviderStateMixin {
  static const _entryDuration = Duration(milliseconds: 220);
  static const _reactionDuration = Duration(milliseconds: 180);

  late final AnimationController _entryController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _entryTimer;
  bool _hovered = false;
  bool _pressed = false;

  bool get _reacting => _hovered || _pressed;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: _entryDuration,
    );
    final entryCurve = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _opacity = entryCurve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(entryCurve);
    final delay = Duration(milliseconds: math.min(widget.index, 6) * 30);
    _entryTimer = Timer(delay, () => _entryController.forward());
  }

  @override
  void dispose() {
    _entryTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => _setHovered(true),
            onExit: (_) {
              _setHovered(false);
              _setPressed(false);
            },
            child: Listener(
              onPointerDown: (_) => _setPressed(true),
              onPointerUp: (_) => _setPressed(false),
              onPointerCancel: (_) => _setPressed(false),
              child: AnimatedScale(
                scale: _reacting ? 1.015 : 1,
                duration: _reactionDuration,
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: _reactionDuration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow:
                        _reacting
                            ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ]
                            : const [],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
