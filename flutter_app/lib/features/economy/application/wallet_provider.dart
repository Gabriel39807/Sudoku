import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/wallet.dart';
import '../data/wallet_storage.dart';

class WalletNotifier extends Notifier<Wallet> {
  @override
  Wallet build() {
    _load();
    return const Wallet();
  }

  Future<void> _load() async {
    state = await WalletStorage.load();
  }

  Future<void> reload() async {
    state = await WalletStorage.load();
  }

  Future<void> addGems(int amount) async {
    state = state.copyWith(gems: state.gems + amount);
    await WalletStorage.save(state);
  }

  Future<void> addTokens(int amount) async {
    state = state.copyWith(tokens: state.tokens + amount);
    await WalletStorage.save(state);
  }

  Future<bool> spendGems(int amount) async {
    if (state.gems < amount) return false;
    state = state.copyWith(gems: state.gems - amount);
    await WalletStorage.save(state);
    return true;
  }

  Future<bool> spendTokens(int amount) async {
    if (state.tokens < amount) return false;
    state = state.copyWith(tokens: state.tokens - amount);
    await WalletStorage.save(state);
    return true;
  }

  Future<void> addHints(int amount) async {
    final available = Wallet.maxHints - state.hintConsumables;
    if (available <= 0) return;
    final actual = amount > available ? available : amount;
    state = state.copyWith(hintConsumables: state.hintConsumables + actual);
    await WalletStorage.save(state);
  }

  Future<bool> consumeHint() async {
    if (state.hintConsumables <= 0) return false;
    state = state.copyWith(hintConsumables: state.hintConsumables - 1);
    await WalletStorage.save(state);
    return true;
  }

  Future<void> addAdvancedNotes(int amount) async {
    final available = Wallet.maxAdvancedNotes - state.advancedNoteConsumables;
    if (available <= 0) return;
    final actual = amount > available ? available : amount;
    state = state.copyWith(advancedNoteConsumables: state.advancedNoteConsumables + actual);
    await WalletStorage.save(state);
  }

  Future<bool> consumeAdvancedNote() async {
    if (state.advancedNoteConsumables <= 0) return false;
    state = state.copyWith(advancedNoteConsumables: state.advancedNoteConsumables - 1);
    await WalletStorage.save(state);
    return true;
  }

  Future<bool> ownsPremiumCosmetic(String id) async {
    return state.ownedPremiumCosmetics.contains(id);
  }

  Future<bool> buyPremiumCosmetic(String id, int cost) async {
    if (state.gems < cost) return false;
    if (state.ownedPremiumCosmetics.contains(id)) return false;
    state = state.copyWith(
      gems: state.gems - cost,
      ownedPremiumCosmetics: [...state.ownedPremiumCosmetics, id],
    );
    await WalletStorage.save(state);
    return true;
  }
}

final walletProvider = NotifierProvider<WalletNotifier, Wallet>(
  WalletNotifier.new,
);
