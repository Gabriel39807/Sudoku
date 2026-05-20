import 'package:go_router/go_router.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/difficulty/presentation/difficulty_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/victory_screen.dart';
import '../../features/game/presentation/defeat_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

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
        final extra = state.extra;
        assert(extra != null && extra is String, '/game requires difficulty as extra');
        return GameScreen(difficulty: extra as String);
      },
    ),
    GoRoute(
      path: '/victory',
      builder: (context, state) {
        final extra = state.extra;
        assert(extra != null && extra is String, '/victory requires difficulty as extra');
        return VictoryScreen(difficulty: extra as String);
      },
    ),
    GoRoute(
      path: '/defeat',
      builder: (context, state) {
        final extra = state.extra;
        assert(extra != null && extra is String, '/defeat requires difficulty as extra');
        return DefeatScreen(difficulty: extra as String);
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
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
