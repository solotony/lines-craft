import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/rendering/palette.dart';
import 'package:lines/game/ui/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sound assets paths are distinct for title and fanfare', () {
    expect(SoundService.titleAsset, isNot(SoundService.fanfareAsset));
    expect(SoundService.selectAsset, contains('select'));
    expect(SoundService.landAsset, contains('land'));
  });

  test('fanfare flag fires once when muted', () async {
    final sound = SoundService();
    sound.enabled = false;
    await sound.playFanfareIfNeeded(true);
    expect(sound.fanfarePlayed, isTrue);
    await sound.playFanfareIfNeeded(true);
    expect(sound.fanfarePlayed, isTrue);
    sound.resetFanfareFlag();
    expect(sound.fanfarePlayed, isFalse);
    await sound.dispose();
  });

  test('palette still exactly 16 after stage 8', () {
    final values =
        GamePalette.all.map((c) => c.toARGB32() & 0x00FFFFFF).toSet();
    expect(values.length, 16);
  });
}
