import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AudioHapticService {
  static final AudioHapticService instance = AudioHapticService._internal();
  AudioHapticService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play reminder chime tone
  Future<void> playNotificationTone(String toneName) async {
    try {
      // Use system feedback audio or sound synthesis
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Trigger vibration pattern
  Future<void> triggerVibration() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 500);
      }
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }
}
