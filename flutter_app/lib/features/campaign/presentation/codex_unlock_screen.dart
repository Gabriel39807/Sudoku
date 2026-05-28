import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../domain/adventure_content.dart';

class CodexUnlockScreen extends StatefulWidget {
  final CodexEntry entry;
  final int totalSeen;

  const CodexUnlockScreen({super.key, required this.entry, required this.totalSeen});

  @override
  State<CodexUnlockScreen> createState() => _CodexUnlockScreenState();
}

class _CodexUnlockScreenState extends State<CodexUnlockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = switch (widget.entry.tier) {
      1 => Colors.green,
      2 => Colors.cyan,
      3 => Colors.blue,
      4 => Colors.purple,
      5 => Colors.deepOrange,
      6 => Colors.red,
      7 => Colors.amber,
      _ => Colors.white,
    };

    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tierColor.withValues(alpha: 0.15),
                    const Color(0xFF1A1A2E),
                  ],
                ),
                border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: tierColor.withValues(alpha: 0.2), blurRadius: 40),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        tierColor.withValues(alpha: 0.3),
                        tierColor.withValues(alpha: 0.05),
                      ]),
                    ),
                    child: Center(
                      child: Text(widget.entry.icon, style: const TextStyle(fontSize: 28)),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  Text('TÉCNICA DESCUBIERTA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 3,
                        color: tierColor.withValues(alpha: 0.7),
                      )).animate().fade(duration: 400.ms),
                  const SizedBox(height: 8),
                  Text(widget.entry.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                      )).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2),
                  if (_showContent) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Text(widget.entry.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4)),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Text('Tier ${widget.entry.tier} · $widget.totalSeen/${CodexEntry.registry.length}',
                        style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tierColor.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CONTINUAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 2)),
                      ),
                    ).animate().fade(duration: 400.ms, delay: 600.ms).slideY(begin: 0.3),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
