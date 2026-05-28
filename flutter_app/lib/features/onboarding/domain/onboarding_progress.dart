import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class OnboardingProgress {
  static const _key = 'onboarding_progress';

  final bool hasSeenIntro;
  final bool tutorialCompleted;
  final bool unlockedDaily;
  final bool unlockedShop;
  final bool unlockedCustomization;
  final bool claimedRewards;

  const OnboardingProgress({
    this.hasSeenIntro = false,
    this.tutorialCompleted = false,
    this.unlockedDaily = false,
    this.unlockedShop = false,
    this.unlockedCustomization = false,
    this.claimedRewards = false,
  });

  bool get isFirstLaunch => !hasSeenIntro;

  OnboardingProgress copyWith({
    bool? hasSeenIntro,
    bool? tutorialCompleted,
    bool? unlockedDaily,
    bool? unlockedShop,
    bool? unlockedCustomization,
    bool? claimedRewards,
  }) {
    return OnboardingProgress(
      hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
      unlockedDaily: unlockedDaily ?? this.unlockedDaily,
      unlockedShop: unlockedShop ?? this.unlockedShop,
      unlockedCustomization: unlockedCustomization ?? this.unlockedCustomization,
      claimedRewards: claimedRewards ?? this.claimedRewards,
    );
  }

  Map<String, dynamic> toJson() => {
    'hasSeenIntro': hasSeenIntro,
    'tutorialCompleted': tutorialCompleted,
    'unlockedDaily': unlockedDaily,
    'unlockedShop': unlockedShop,
    'unlockedCustomization': unlockedCustomization,
    'claimedRewards': claimedRewards,
  };

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) => OnboardingProgress(
    hasSeenIntro: json['hasSeenIntro'] as bool? ?? false,
    tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
    unlockedDaily: json['unlockedDaily'] as bool? ?? false,
    unlockedShop: json['unlockedShop'] as bool? ?? false,
    unlockedCustomization: json['unlockedCustomization'] as bool? ?? false,
    claimedRewards: json['claimedRewards'] as bool? ?? false,
  );

  static Future<OnboardingProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const OnboardingProgress();
    try {
      return OnboardingProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const OnboardingProgress();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }
}
