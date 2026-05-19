import 'package:go_router/go_router.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/difficulty/presentation/difficulty_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/difficulty',
      builder: (context, state) => const DifficultyScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final difficulty = state.extra as String? ?? 'easy';
        return GameScreen(difficulty: difficulty);
      },
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
