import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wheel_reward.dart';
import '../data/wheel_storage.dart';
import '../../economy/application/wallet_provider.dart';
import '../../../ui/currency/currency_type.dart';

enum WheelStatus { idle, spinning, done }

class WheelState {
  final WheelStatus status;
  final bool canSpin;
  final WheelReward? lastReward;
  final int targetIndex;
  final int extraSpins;

  const WheelState({
    this.status = WheelStatus.idle,
    this.canSpin = true,
    this.lastReward,
    this.targetIndex = 0,
    this.extraSpins = 0,
  });

  WheelState copyWith({
    WheelStatus? status,
    bool? canSpin,
    WheelReward? lastReward,
    int? targetIndex,
    int? extraSpins,
    bool clearReward = false,
  }) =>
      WheelState(
        status: status ?? this.status,
        canSpin: canSpin ?? this.canSpin,
        lastReward: clearReward ? null : (lastReward ?? this.lastReward),
        targetIndex: targetIndex ?? this.targetIndex,
        extraSpins: extraSpins ?? this.extraSpins,
      );
}

final wheelProvider = NotifierProvider<WheelNotifier, WheelState>(
  WheelNotifier.new,
);

class WheelNotifier extends Notifier<WheelState> {
  @override
  WheelState build() {
    _checkCanSpin();
    _loadExtraSpins();
    return const WheelState();
  }

  Future<void> _checkCanSpin() async {
    final spun = await WheelStorage.isSpunToday();
    state = state.copyWith(canSpin: !spun);
  }

  Future<void> _loadExtraSpins() async {
    final spins = await WheelStorage.getExtraSpins();
    state = state.copyWith(extraSpins: spins);
  }

  Future<WheelReward> spin() async {
    if (!state.canSpin && state.extraSpins <= 0) {
      throw Exception('No spins available');
    }

    final index = pickWeightedIndex();
    final reward = wheelSegments[index].reward;

    if (state.canSpin) {
      state = state.copyWith(
        status: WheelStatus.spinning,
        targetIndex: index,
        canSpin: false,
      );
    } else {
      await WheelStorage.useExtraSpin();
      final remaining = await WheelStorage.getExtraSpins();
      state = state.copyWith(
        status: WheelStatus.spinning,
        targetIndex: index,
        extraSpins: remaining,
      );
    }

    return reward;
  }

  Future<void> claimReward(WheelReward reward) async {
    if (state.canSpin) {
      await WheelStorage.markSpun();
    }

    if (reward.isHint) {
      await ref.read(walletProvider.notifier).addHints(reward.amount);
    } else if (reward.isAdvancedNotes) {
      await ref.read(walletProvider.notifier).addSouls(3);
    } else if (reward.isFreeSpin) {
      await WheelStorage.addExtraSpins(1);
      state = state.copyWith(extraSpins: await WheelStorage.getExtraSpins());
    } else if (reward.isX2Reward) {
      await ref.read(walletProvider.notifier).addSouls(reward.amount);
      await ref.read(walletProvider.notifier).addTokens(reward.amount);
    } else if (reward.isEmpty) {
      // no reward
    } else if (reward.isCurrency && reward.currencyType == CurrencyType.tokens) {
      await ref.read(walletProvider.notifier).addTokens(reward.amount);
    } else {
      await ref.read(walletProvider.notifier).addSouls(reward.amount);
    }

    state = state.copyWith(
      status: WheelStatus.done,
      lastReward: reward,
    );
  }

  Future<void> claimDailyFree() async {
    await WheelStorage.markSpun();
    state = state.copyWith(canSpin: false);
  }

  void reset() {
    state = const WheelState(canSpin: false);
  }

  void clearReward() {
    state = state.copyWith(clearReward: true, status: WheelStatus.idle);
  }

  Future<void> refreshExtraSpins() async {
    final spins = await WheelStorage.getExtraSpins();
    state = state.copyWith(extraSpins: spins);
  }
}
