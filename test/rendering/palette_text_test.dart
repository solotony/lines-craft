import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/rendering/palette.dart';
import 'package:lines/game/rendering/pixel_text_renderer.dart';

void main() {
  test('palette has exactly 16 unique colors', () {
    expect(GamePalette.all.length, 16);
    expect(GamePalette.size, 16);
    final values =
        GamePalette.all.map((c) => c.toARGB32() & 0x00FFFFFF).toSet();
    expect(values.length, 16);
  });

  test('palette contains its own colors', () {
    for (final c in GamePalette.all) {
      expect(GamePalette.contains(c), isTrue);
    }
    expect(GamePalette.contains(const Color(0xFF123456)), isFalse);
  });

  test('pixel text raster uses at most 2 colors and stays in palette', () {
    const renderer = PixelTextRenderer();
    final data = renderer.rasterize(
      'SCORE 123',
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );
    final unique = PixelTextRenderer.countUniqueColors(data);
    expect(unique, lessThanOrEqualTo(2));
    expect(unique, lessThanOrEqualTo(GamePalette.size));
  });

  test('nearest-neighbor scale is exact integer blocks', () {
    const renderer = PixelTextRenderer();
    final data = renderer.rasterize(
      'A',
      color: GamePalette.white,
      background: GamePalette.black,
      scale: 3,
    );
    expect(renderer.measureWidth('A', scale: 3), 24);
    expect(renderer.measureHeight(scale: 3), 24);
    final bytes = data.buffer.asUint8List();
    var foundBlock = false;
    for (var y = 0; y < 24 && !foundBlock; y++) {
      for (var x = 0; x < 24; x++) {
        final i = (y * 24 + x) * 4;
        if (bytes[i] == 0xFE && bytes[i + 1] == 0xFE && bytes[i + 2] == 0xFE) {
          final gx = x ~/ 3;
          final gy = y ~/ 3;
          for (var sy = 0; sy < 3; sy++) {
            for (var sx = 0; sx < 3; sx++) {
              final j = ((gy * 3 + sy) * 24 + (gx * 3 + sx)) * 4;
              expect(bytes[j], 0xFE);
              expect(bytes[j + 1], 0xFE);
              expect(bytes[j + 2], 0xFE);
            }
          }
          foundBlock = true;
          break;
        }
      }
    }
    expect(foundBlock, isTrue);
  });
}
