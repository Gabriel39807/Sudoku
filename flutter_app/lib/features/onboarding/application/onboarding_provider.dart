import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/onboarding_progress.dart';

class OnboardingNotifier extends Notifier<OnboardingProgress> {
  @override
  OnboardingProgress build() {
    _load();
    return const OnboardingProgress();
  }

  Future<void> _load() async {
    state = await OnboardingProgress.load();
  }

  Future<void> completeIntro() async {
    state = state.copyWith(hasSeenIntro: true);
    await state.save();
  }

  Future<void> completeTutorial() async {
    state = state.copyWith(tutorialCompleted: true);
    await state.save();
  }

  Future<void> unlockDaily() async {
    if (state.unlockedDaily) return;
    state = state.copyWith(unlockedDaily: true);
    await state.save();
  }

  Future<void> unlockShop() async {
    if (state.unlockedShop) return;
    state = state.copyWith(unlockedShop: true);
    await state.save();
  }

  Future<void> unlockCustomization() async {
    if (state.unlockedCustomization) return;
    state = state.copyWith(unlockedCustomization: true);
    await state.save();
  }

  Future<void> claimRewards() async {
    state = state.copyWith(claimedRewards: true);
    await state.save();
  }

  Future<void> reset() async {
    state = const OnboardingProgress();
    await state.save();
  }
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingProgress>(
  OnboardingNotifier.new,
);
