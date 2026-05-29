import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cosmetics/domain/unlock_reward.dart';

class QueuedRewardItem {
  final UnlockReward reward;
  final void Function(String action)? onResult;
  QueuedRewardItem({required this.reward, this.onResult});
}

class RewardQueueNotifier extends Notifier<List<QueuedRewardItem>> {
  @override
  List<QueuedRewardItem> build() => [];

  void enqueue(UnlockReward reward, {void Function(String action)? onResult}) {
    state = [...state, QueuedRewardItem(reward: reward, onResult: onResult)];
  }

  QueuedRewardItem? dequeue() {
    if (state.isEmpty) return null;
    final first = state.first;
    state = state.sublist(1);
    return first;
  }
}

final rewardQueueProvider =
    NotifierProvider<RewardQueueNotifier, List<QueuedRewardItem>>(
  RewardQueueNotifier.new,
);
