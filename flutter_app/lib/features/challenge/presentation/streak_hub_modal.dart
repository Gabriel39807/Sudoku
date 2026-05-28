import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/streak_provider.dart';
import '../../../shared/widgets/game_modal_card.dart';

class StreakTier {
  final String label;
  final String icon;
  final int minStreak;
  final int? maxStreak;
  final Color color;
  final String description;

  const StreakTier({
    required this.label,
    required this.icon,
    required this.minStreak,
    this.maxStreak,
    required this.color,
    required this.description,
  });

  static const List<StreakTier> all = [
    StreakTier(label: 'Normal',      icon: '🔥', minStreak: 0,    maxStreak: 4,   color: Colors.orange,        description: 'Sin bonus'),
    StreakTier(label: 'Encendido',   icon: '🔥', minStreak: 5,    maxStreak: 9,   color: Colors.orange,        description: 'Brillo tenue'),
    StreakTier(label: 'Ardiente',    icon: '🔥🔥', minStreak: 10,   maxStreak: 19,  color: Colors.deepOrange,    description: 'Brillo intenso'),
    StreakTier(label: 'Llameante',   icon: '✨', minStreak: 20,   maxStreak: 29,  color: Colors.redAccent,     description: 'Partículas'),
    StreakTier(label: 'Aura',        icon: '🌟', minStreak: 30,   maxStreak: 59,  color: Colors.orangeAccent,  description: 'Aura visible'),
    StreakTier(label: 'Legendario',  icon: '⭐', minStreak: 60,   maxStreak: 99,  color: Color(0xFFFFD700),    description: 'Brillo dorado'),
    StreakTier(label: 'Corona',      icon: '👑', minStreak: 100,  maxStreak: 364, color: Color(0xFFFFD700),    description: 'Corona especial'),
    StreakTier(label: 'Mítico',      icon: '♾️', minStreak: 365,                   color: Color(0xFFFF69B4),    description: 'Leyenda viviente'),
  ];

  static StreakTier forStreak(int streak) {
    StreakTier? best;
    for (final t in all) {
      if (streak < t.minStreak) continue;
      if (t.maxStreak != null && streak > t.maxStreak!) continue;
      best = t;
    }
    return best ?? all.first;
  }
}

class StreakCircleBtn extends StatefulWidget {
  final int streak;
  final bool completedToday;
  final VoidCallback onTap;

  const StreakCircleBtn({
    super.key,
    required this.streak,
    required this.completedToday,
    required this.onTap,
  });

  @override
  State<StreakCircleBtn> createState() => _StreakCircleBtnState();
}

class _StreakCircleBtnState extends State<StreakCircleBtn>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late StreakTier _tier;
  late AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _tier = StreakTier.forStreak(widget.streak);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didUpdateWidget(StreakCircleBtn old) {
    super.didUpdateWidget(old);
    if (old.streak != widget.streak) {
      _tier = StreakTier.forStreak(widget.streak);
      if (!widget.completedToday && old.streak < widget.streak) {
        _popCtrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  bool get _hasGlow => widget.streak >= 5 || widget.completedToday;

  @override
  Widget build(BuildContext context) {
    final showCompleted = widget.completedToday && widget.streak > 0;
    final hasPop = _popCtrl.value > 0;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseCtrl, _popCtrl]),
      builder: (context, _) {
        final pulse = _hasGlow ? _pulseAnim.value : 0.0;
        final scale = showCompleted
            ? 1.0 + pulse * 0.04 + (hasPop ? (_popCtrl.value > 0.5
                ? (1.0 - (_popCtrl.value - 0.5) / 0.5) * 0.2
                : _popCtrl.value / 0.5 * 0.2) : 0.0)
            : 1.0 + (_hasGlow ? pulse * 0.04 : 0.0);
        final glowBlur = _tier.minStreak >= 20 ? 14.0 + pulse * 6 :
                         _tier.minStreak >= 10 ? 10.0 + pulse * 4 :
                         showCompleted ? 8.0 + pulse * 4 :
                         _tier.minStreak >= 5 ? 6.0 + pulse * 3 : 0.0;
        final glowAlpha = showCompleted ? 0.35 + pulse * 0.3 : 0.25 + pulse * 0.25;

        Widget circle;
        if (showCompleted) {
          circle = Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent.withValues(alpha: glowAlpha),
                  blurRadius: glowBlur,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.red.withValues(alpha: glowAlpha * 0.5),
                  blurRadius: glowBlur * 0.6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_tier.icon, style: TextStyle(fontSize: widget.streak >= 10 ? 11 : 13)),
                Text(
                  '${widget.streak}',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ],
            ),
          );
        } else {
          circle = Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: widget.streak > 0
                    ? _tier.color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: glowBlur > 0
                  ? [
                      BoxShadow(
                        color: _tier.color.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_tier.icon, style: TextStyle(fontSize: widget.streak >= 10 ? 11 : 13)),
                Text(
                  '${widget.streak}${widget.streak == 0 ? 'd' : ''}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: widget.streak > 0 ? _tier.color : Colors.white38,
                  ),
                ),
              ],
            ),
          );
        }

        return Tooltip(
          message: showCompleted
              ? 'Racha activa: ${widget.streak} día${widget.streak == 1 ? '' : 's'}'
              : 'Racha: ${widget.streak} día${widget.streak == 1 ? '' : 's'}',
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(26),
            child: Transform.scale(
              scale: scale,
              child: circle,
            ),
          ),
        );
      },
    );
  }
}

void showStreakHub(BuildContext context) {
  final ref = ProviderScope.containerOf(context);
  final streak = ref.read(streakProvider);
  final tier = StreakTier.forStreak(streak.currentStreak);
  final nextTier = _nextTier(streak.currentStreak);

  showDialog(
    context: context,
    builder: (ctx) => GameModalCard(
      onClose: () => Navigator.pop(ctx),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: StreakHubContent(
        streak: streak.currentStreak,
        bestStreak: streak.bestStreak,
        completedToday: streak.completedToday,
        tier: tier,
        nextTier: nextTier,
        onClose: () => Navigator.pop(ctx),
      ),
    ),
  );
}

StreakTier? _nextTier(int current) {
  for (final t in StreakTier.all) {
    if (t.minStreak > current) return t;
  }
  return null;
}

class StreakHubContent extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final bool completedToday;
  final StreakTier tier;
  final StreakTier? nextTier;
  final VoidCallback onClose;

  const StreakHubContent({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.completedToday,
    required this.tier,
    this.nextTier,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (completedToday && streak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: const Text('RACHA ACTIVA',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
          ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
          const SizedBox(height: 4),
        ],
        Text(tier.icon, style: const TextStyle(fontSize: 40))
            .animate().fade(duration: 400.ms).scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),
        const SizedBox(height: 8),
        Text(completedToday && streak > 0 ? '${tier.icon} ${streak} DÍA${streak == 1 ? '' : 'S'}' : 'RACHA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: tier.color,
            )).animate().fade(delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 12),
        Text('${streak}',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: streak > 0 ? tier.color : Colors.white38,
              shadows: [
                Shadow(color: tier.color.withValues(alpha: 0.3), blurRadius: 20),
              ],
            )).animate().fade(delay: 250.ms, duration: 400.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
        Text('día${streak == 1 ? '' : 's'} seguido${streak == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: Colors.white54))
            .animate().fade(delay: 350.ms, duration: 400.ms),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text('Mejor: $bestStreak',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber)),
            ],
          ),
        ).animate().fade(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: 16),
        Text('NIVELES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.3)))
            .animate().fade(delay: 450.ms, duration: 400.ms),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: StreakTier.all.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final t = StreakTier.all[i];
              final unlocked = streak >= t.minStreak;
              final current = t == tier;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: current
                      ? tier.color.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: current
                        ? tier.color.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                ),
                child: Row(
                  children: [
                    Text(t.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: unlocked ? t.color : Colors.white38,
                              )),
                          Text(t.description,
                              style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4))),
                        ],
                      ),
                    ),
                    Text(
                      t.maxStreak != null
                          ? '${t.minStreak}–${t.maxStreak}'
                          : '${t.minStreak}+',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? t.color : Colors.white24,
                      ),
                    ),
                    if (current)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tier.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('ACTUAL',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: tier.color,
                            )),
                      ),
                  ],
                ),
              ).animate().fade(delay: (500 + i * 60).ms, duration: 300.ms).slideX(begin: i.isEven ? -0.05 : 0.05);
            },
          ),
        ),
        const SizedBox(height: 16),
        if (nextTier case final nt?)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: nt.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: nt.color.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nt.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  '${nt.minStreak - streak} día${nt.minStreak - streak == 1 ? '' : 's'} para ${nt.label}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: nt.color),
                ),
              ],
            ),
          ).animate().fade(delay: 800.ms, duration: 400.ms),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onClose,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('CERRAR',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}