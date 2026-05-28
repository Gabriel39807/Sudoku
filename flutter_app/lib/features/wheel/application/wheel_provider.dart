import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../domain/wheel_reward.dart';
import '../data/wheel_storage.dart';
import '../../economy/application/wallet_provider.dart';
import '../../../core/time/global_time_service.dart';
import '../../../ui/currency/currency_type.dart';

enum WheelStatus { ready, spinning, reward, cooldown, offline }

class WheelState {
  final WheelStatus status;
  final bool hasFreeSpin;
  final int extraSpins;
  final WheelReward? lastReward;
  final int targetIndex;
  final bool isOnline;
  final String timeUntilReset;
  final int adSpins;
  final int remainingSeconds;

  const WheelState({
    this.status = WheelStatus.cooldown,
    this.hasFreeSpin = false,
    this.extraSpins = 0,
    this.lastReward,
    this.targetIndex = 0,
    this.isOnline = true,
    this.timeUntilReset = '',
    this.adSpins = 0,
    this.remainingSeconds = 0,
  });

  WheelState copyWith({
    WheelStatus? status,
    bool? hasFreeSpin,
    int? extraSpins,
    WheelReward? lastReward,
    int? targetIndex,
    bool? clearReward,
    bool? isOnline,
    String? timeUntilReset,
    int? adSpins,
    int? remainingSeconds,
  }) => WheelState(
    status: status ?? this.status,
    hasFreeSpin: hasFreeSpin ?? this.hasFreeSpin,
    extraSpins: extraSpins ?? this.extraSpins,
    lastReward: clearReward == true ? null : (lastReward ?? this.lastReward),
    targetIndex: targetIndex ?? this.targetIndex,
    isOnline: isOnline ?? this.isOnline,
    timeUntilReset: timeUntilReset ?? this.timeUntilReset,
    adSpins: adSpins ?? this.adSpins,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
  );

  bool get canSpin =>
    isOnline &&
    status != WheelStatus.spinning &&
    (hasFreeSpin || extraSpins > 0 || adSpins > 0);
}

final wheelProvider = NotifierProvider<WheelNotifier, WheelState>(
  WheelNotifier.new,
);

class WheelNotifier extends Notifier<WheelState> {
  StreamSubscription? _connectivitySub;
  Timer? _resetTimer;
  bool _mounted = false;

  @override
  WheelState build() {
    _mounted = true;
    ref.onDispose(() {
      _mounted = false;
      _connectivitySub?.cancel();
      _resetTimer?.cancel();
    });
    _init();
    return const WheelState();
  }

  Future<void> _init() async {
    await Future.wait([_syncTimeAndState(), _listenConnectivity()]);
  }

  Future<void> _syncTimeAndState() async {
    final service = GlobalTimeService.instance;
    final serverTime = await service.serverNow();
    final valid = await service.isTimeValid(serverTime);
    if (!valid) {
      state = state.copyWith(status: WheelStatus.cooldown, isOnline: true);
      return;
    }

    final hasFree = await WheelStorage.hasFreeSpinAvailable();
    final extras = await WheelStorage.getExtraSpins();
    final adSpins = await WheelStorage.getAdSpins();
    final timeUntil = await service.timeUntilResetFormatted();
    final remainingDur = await service.timeUntilNextReset();
    final remainingSecs = remainingDur.inSeconds.clamp(0, 86400);
    final canDoAnything = hasFree || extras > 0 || adSpins > 0;

    state = state.copyWith(
      status: canDoAnything ? WheelStatus.ready : WheelStatus.cooldown,
      hasFreeSpin: hasFree,
      extraSpins: extras,
      adSpins: adSpins,
      isOnline: true,
      timeUntilReset: timeUntil,
      remainingSeconds: remainingSecs,
    );

    _startResetCountdown();
  }

  Future<void> _listenConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      final online = !result.contains(ConnectivityResult.none);
      if (online != state.isOnline) {
        state = state.copyWith(
          isOnline: online,
          status: online ? (state.hasFreeSpin || state.extraSpins > 0 ? WheelStatus.ready : WheelStatus.cooldown) : WheelStatus.offline,
        );
      }
      _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
        final online = !result.contains(ConnectivityResult.none);
        if (online != state.isOnline && _mounted) {
          state = state.copyWith(
            isOnline: online,
            status: online
                ? (state.hasFreeSpin || state.extraSpins > 0 ? WheelStatus.ready : WheelStatus.cooldown)
                : WheelStatus.offline,
          );
          if (online) _syncTimeAndState();
        }
      });
    } catch (_) {
      state = state.copyWith(isOnline: false, status: WheelStatus.offline);
    }
  }

  void _startResetCountdown() {
    _resetTimer?.cancel();
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_mounted) return;
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        await _syncTimeAndState();
        return;
      }
      state = state.copyWith(remainingSeconds: remaining);
      if (remaining % 30 == 0) {
        final hasFree = await WheelStorage.hasFreeSpinAvailable();
        if (hasFree != state.hasFreeSpin && _mounted) {
          await _syncTimeAndState();
        }
      }
    });
  }



  // ── Spin ────────────────────────────────────────────────────────────────

  Future<WheelReward> spin() async {
    if (!state.canSpin) throw Exception('No se puede girar');

    final index = pickWeightedIndex();
    final reward = wheelSegments[index].reward;

    if (state.hasFreeSpin) {
      await WheelStorage.useFreeSpin();
      state = state.copyWith(
        status: WheelStatus.spinning,
        targetIndex: index,
        hasFreeSpin: false,
        lastReward: null,
      );
    } else if (state.extraSpins > 0) {
      await WheelStorage.useExtraSpin();
      final remaining = await WheelStorage.getExtraSpins();
      state = state.copyWith(
        status: WheelStatus.spinning,
        targetIndex: index,
        extraSpins: remaining,
        lastReward: null,
      );
    } else if (state.adSpins > 0) {
      await WheelStorage.useAdSpin();
      final remaining = await WheelStorage.getAdSpins();
      state = state.copyWith(
        status: WheelStatus.spinning,
        targetIndex: index,
        adSpins: remaining,
        lastReward: null,
      );
    }

    return reward;
  }

  // ── Claim ───────────────────────────────────────────────────────────────

  Future<void> claimReward(WheelReward reward) async {
    if (reward.isHint) {
      await ref.read(walletProvider.notifier).addHints(reward.amount);
    } else if (reward.isAdvancedNotes) {
      await ref.read(walletProvider.notifier).addGems(3);
    } else if (reward.isFreeSpin) {
      await WheelStorage.addExtraSpins(1);
      state = state.copyWith(extraSpins: await WheelStorage.getExtraSpins());
    } else if (reward.isX2Reward) {
      await ref.read(walletProvider.notifier).addGems(reward.amount);
      await ref.read(walletProvider.notifier).addTokens(reward.amount);
    } else if (reward.isEmpty) {
      // no reward
    } else if (reward.isCurrency && reward.currencyType == CurrencyType.tokens) {
      await ref.read(walletProvider.notifier).addTokens(reward.amount);
    } else {
      await ref.read(walletProvider.notifier).addGems(reward.amount);
    }

    final canDoAnything = state.hasFreeSpin || state.extraSpins > 0 || state.adSpins > 0;
    state = state.copyWith(
      status: canDoAnything ? WheelStatus.ready : WheelStatus.cooldown,
      lastReward: reward,
      clearReward: false,
    );
  }

  void clearReward() {
    state = state.copyWith(
      clearReward: true,
      status: state.hasFreeSpin || state.extraSpins > 0 ? WheelStatus.ready : WheelStatus.cooldown,
    );
  }

  Future<void> refreshExtraSpins() async {
    final extras = await WheelStorage.getExtraSpins();
    final adSpins = await WheelStorage.getAdSpins();
    state = state.copyWith(extraSpins: extras, adSpins: adSpins);
  }

  Future<void> buyWithTokens(int cost, int spins) async {
    final ok = await ref.read(walletProvider.notifier).spendTokens(cost);
    if (ok) {
      await WheelStorage.addExtraSpins(spins);
      final extras = await WheelStorage.getExtraSpins();
      state = state.copyWith(extraSpins: extras, status: WheelStatus.ready);
    }
  }
}
