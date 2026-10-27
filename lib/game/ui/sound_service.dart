import 'package:flutter/services.dart';

/// Lightweight SFX via built-in [SystemSound] — no native audio plugins.
///
/// Asset path constants document the intended original cues; WAV placeholders
/// remain in `assets/sounds/` for a future optional player.
class SoundService {
  SoundService();

  bool enabled = true;
  bool _fanfarePlayed = false;

  static const selectAsset = 'sounds/select.wav';
  static const landAsset = 'sounds/land.wav';
  static const moveAsset = 'sounds/move.wav';
  static const fanfareAsset = 'sounds/fanfare.wav';
  static const titleAsset = 'sounds/title.wav';

  Future<void> playSelect() => _click();
  Future<void> playLand() => _click();
  Future<void> playMove() => _click();
  Future<void> playTitle() async {}

  /// Fanfare only the first time the player beats the King's score.
  Future<void> playFanfareIfNeeded(bool beatKing) async {
    if (!beatKing || _fanfarePlayed) {
      return;
    }
    _fanfarePlayed = true;
    await _click();
  }

  bool get fanfarePlayed => _fanfarePlayed;

  void resetFanfareFlag() {
    _fanfarePlayed = false;
  }

  Future<void> _click() async {
    if (!enabled) {
      return;
    }
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Unavailable in some test / headless environments.
    }
  }

  Future<void> dispose() async {}
}
