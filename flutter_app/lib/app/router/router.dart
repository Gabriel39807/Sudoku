import 'package:go_router/go_router.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/difficulty/presentation/difficulty_screen.dart';
import '../../features/game/presentation/game_screen.dart';

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
  ],
);
