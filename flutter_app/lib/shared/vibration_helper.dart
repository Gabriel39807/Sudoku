import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class VibrationHelper {
  static Future<void> vibrateError() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        final hasAmplitude = await Vibration.hasAmplitudeControl();
        if (hasAmplitude) {
          await Vibration.vibrate(duration: 80, amplitude: 128);
        } else {
          await Vibration.vibrate(duration: 80);
        }
        return;
      }
    } catch (_) {}

    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }
}
