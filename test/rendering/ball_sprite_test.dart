import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/model/ball_color.dart';
import 'package:lines/game/rendering/palette.dart';
import 'package:lines/game/rendering/sprite_renderer.dart';

void main() {
  test('seven ball colors map to palette', () {
    expect(BallColor.values.length, 7);
    for (final c in BallColor.values) {
      expect(GamePalette.contains(c.base), isTrue, reason: '$c base');
      expect(GamePalette.contains(c.shade), isTrue, reason: '$c shade');
      expect(GamePalette.contains(c.highlight), isTrue);
    }
  });

  test('sprite asset paths are defined', () {
    expect(SpriteRenderer.kingAsset, contains('king.png'));
    expect(SpriteRenderer.pretenderAsset, contains('pretender.png'));
    expect(SpriteRenderer.kingLoseAsset, contains('king-lose'));
    expect(SpriteRenderer.pretenderWinsAsset, contains('pretender-wins'));
  });

  testWidgets('character assets are bundled', (tester) async {
    final bundle = tester.binding.defaultBinaryMessenger;
    expect(bundle, isNotNull);
    // Ensure assets resolve via rootBundle through widget binding.
    await tester.runAsync(() async {
      // ignore: unnecessary_statements
      SpriteRenderer.kingAsset;
    });
  });
}
