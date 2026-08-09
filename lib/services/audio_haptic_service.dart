import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AudioHapticService {
  static final AudioHapticService instance = AudioHapticService._internal();
  AudioHapticService._internal();

  /// Play audible eye drop reminder alarm chime tone
  Future<void> playNotificationTone(String toneName) async {
    try {
      // Trigger sequence of system alert audio tones
      await SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 300));
      await SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 300));
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Trigger alarm vibration pattern
  Future<void> triggerVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }
}
