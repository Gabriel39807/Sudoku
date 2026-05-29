import 'package:flutter/material.dart';
import '../application/hint_engine.dart';
import 'contextual_finger.dart';

class HintOverlayManager {
  OverlayEntry? _entry;

  void show({
    required BuildContext context,
    required HintEngineEvent event,
    required Map<String, GlobalKey> targetKeys,
    VoidCallback? onDismiss,
  }) {
    hide();

    final targetKey = targetKeys[event.targetKey];
    if (targetKey == null) return;
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    _entry = OverlayEntry(
      builder: (_) => _HintOverlayContent(
        targetCenter: position,
        tooltip: event.message,
        onDismiss: () {
          hide();
          onDismiss?.call();
        },
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void hide() {
    _entry?.remove();
    _entry = null;
  }

  bool get isShowing => _entry != null;
}

class _HintOverlayContent extends StatefulWidget {
  final Offset targetCenter;
  final String tooltip;
  final VoidCallback onDismiss;

  const _HintOverlayContent({
    required this.targetCenter,
    required this.tooltip,
    required this.onDismiss,
  });

  @override
  State<_HintOverlayContent> createState() => _HintOverlayContentState();
}

class _HintOverlayContentState extends State<_HintOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onAnyTap() {
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _onAnyTap,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              left: widget.targetCenter.dx - 30,
              top: widget.targetCenter.dy - 30,
              child: IgnorePointer(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ContextualFinger(
              targetCenter: widget.targetCenter,
              tooltip: widget.tooltip,
              onComplete: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}