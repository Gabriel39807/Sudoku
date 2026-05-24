import 'package:go_router/go_router.dart';
import '../../core/theme/game_background_wrapper.dart';
import '../../features/menu/menu_screen.dart';
import '../../features/difficulty/presentation/difficulty_screen.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../features/game/presentation/victory_screen.dart';
import '../../features/game/presentation/defeat_screen.dart';
import '../../features/stats/presentation/stats_screen.dart';
import '../../features/stats/presentation/achievements_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/cosmetics/presentation/customization_screen.dart';
import '../../features/challenge/presentation/daily_challenge_screen.dart';
import '../../features/economy/presentation/shop_screen.dart';
import '../../features/wheel/presentation/lucky_wheel_screen.dart';
import '../../features/campaign/presentation/campaign_screen.dart';
import '../../features/campaign/presentation/campaign_game_screen.dart';
import '../../features/campaign/domain/sudoku_variant.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => GameBackgroundWrapper(child: child),
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
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/achievements',
          builder: (context, state) => const AchievementsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/customization',
          builder: (context, state) => const CustomizationScreen(),
        ),
        GoRoute(
          path: '/shop',
          builder: (context, state) => const ShopScreen(),
        ),
        GoRoute(
          path: '/daily',
          builder: (context, state) => const DailyChallengeScreen(),
        ),
        GoRoute(
          path: '/campaign',
          builder: (context, state) => const CampaignScreen(),
        ),
      ],
    ),
    // Routes WITHOUT global background
    GoRoute(
      path: '/game',
      builder: (context, state) {
        final extra = state.extra;
        assert(extra != null && extra is String, '/game requires difficulty as String');
        return GameScreen(difficulty: extra as String);
      },
    ),
    GoRoute(
      path: '/campaign-game',
      builder: (context, state) {
        final extra = state.extra;
        assert(extra != null && extra is Map, '/campaign-game requires extra as Map');
        final data = extra as Map<String, dynamic>;
        final level = data['level'] as int;
        final variantName = data['variant'] as String;
        final variant = SudokuVariant.values.firstWhere((v) => v.name == variantName);
        return CampaignGameScreen(level: level, variant: variant);
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
      path: '/lucky-wheel',
      builder: (context, state) => const LuckyWheelScreen(),
    ),
  ],
);
