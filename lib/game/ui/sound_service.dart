import 'package:audioplayers/audioplayers.dart';

/// Plays short SFX. Placeholder tones stand in for unavailable original audio.
class SoundService {
  SoundService({AudioPlayer? player}) : _injected = player;

  final AudioPlayer? _injected;
  AudioPlayer? _player;
  bool enabled = true;
  bool _fanfarePlayed = false;

  static const selectAsset = 'sounds/select.wav';
  static const landAsset = 'sounds/land.wav';
  static const moveAsset = 'sounds/move.wav';
  static const fanfareAsset = 'sounds/fanfare.wav';
  static const titleAsset = 'sounds/title.wav';

  AudioPlayer get _audio => _player ??= (_injected ?? AudioPlayer());

  Future<void> playSelect() => _play(selectAsset);
  Future<void> playLand() => _play(landAsset);
  Future<void> playMove() => _play(moveAsset);
  Future<void> playTitle() => _play(titleAsset);

  /// Fanfare only the first time the player beats the King's score.
  Future<void> playFanfareIfNeeded(bool beatKing) async {
    if (!beatKing || _fanfarePlayed) {
      return;
    }
    _fanfarePlayed = true;
    await _play(fanfareAsset);
  }

  bool get fanfarePlayed => _fanfarePlayed;

  void resetFanfareFlag() {
    _fanfarePlayed = false;
  }

  Future<void> _play(String asset) async {
    if (!enabled) {
      return;
    }
    try {
      await _audio.stop();
      await _audio.play(AssetSource(asset));
    } catch (_) {
      // Audio may be unavailable in tests / headless CI.
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
  }
}
