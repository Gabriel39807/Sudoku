import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/reward_queue_provider.dart';
import '../../cosmetics/domain/unlock_reward.dart';

class RewardOverlayWidget extends ConsumerStatefulWidget {
  const RewardOverlayWidget({super.key});

  @override
  ConsumerState<RewardOverlayWidget> createState() =>
      _RewardOverlayWidgetState();
}

class _RewardOverlayWidgetState extends ConsumerState<RewardOverlayWidget> {
  bool _isShowing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(rewardQueueProvider, (prev, next) {
      if (next.isNotEmpty && !_isShowing) {
        _processQueue();
      }
    });
    return const SizedBox.shrink();
  }

  Future<void> _processQueue() async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      while (mounted) {
        final item = ref.read(rewardQueueProvider.notifier).dequeue();
        if (item == null) break;
        dev.log('[RewardOverlay] Showing reward: ${item.reward.title}');
        final result = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder: (_) => CosmeticUnlockModalContent(reward: item.reward),
        );
        if (result != null && item.onResult != null) {
          item.onResult!(result);
        }
      }
    } finally {
      _isShowing = false;
    }
  }
}
