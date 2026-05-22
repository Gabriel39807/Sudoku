import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/game/application/game_provider.dart';

class GameplayOverlayGuard extends ConsumerStatefulWidget {
  final Widget child;
  const GameplayOverlayGuard({required this.child, super.key});

  @override
  ConsumerState<GameplayOverlayGuard> createState() => _GameplayOverlayGuardState();
}

class _GameplayOverlayGuardState extends ConsumerState<GameplayOverlayGuard> {
  late final GameNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(gameProvider.notifier);
    _notifier.onOverlayOpen();
  }

  @override
  void dispose() {
    _notifier.onOverlayClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}