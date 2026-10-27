import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart';

import 'palette.dart';
import 'pixel_font_8.dart';

enum PixelTextAlign { left, center, right }

/// Renders HUD text as crisp pixel blocks from the embedded 8×8 font.
class PixelTextRenderer {
  const PixelTextRenderer();

  int measureWidth(String text, {int scale = 2}) {
    return text.length * PixelFont8.glyphWidth * scale;
  }

  int measureHeight({int scale = 2}) => PixelFont8.glyphHeight * scale;

  /// Draws [text] onto [canvas] at virtual-pixel [origin].
  ///
  /// Only [color] and optional opaque [background] are used; both must be
  /// palette colors. Glyphs are enlarged by integer [scale] without smoothing.
  void paint(
    Canvas canvas,
    String text,
    Offset origin, {
    Color color = GamePalette.ballGreen,
    Color? background,
    int scale = 2,
    PixelTextAlign align = PixelTextAlign.left,
  }) {
    assert(GamePalette.contains(color), 'text color outside palette');
    assert(
      background == null || GamePalette.contains(background),
      'background outside palette',
    );
    assert(scale >= 1);

    var x = origin.dx.round();
    final y = origin.dy.round();
    final width = measureWidth(text, scale: scale);

    switch (align) {
      case PixelTextAlign.left:
        break;
      case PixelTextAlign.center:
        x -= width ~/ 2;
        break;
      case PixelTextAlign.right:
        x -= width;
        break;
    }

    if (background != null) {
      final bg = Paint()
        ..color = background
        ..isAntiAlias = false
        ..filterQuality = FilterQuality.none;
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          measureHeight(scale: scale).toDouble(),
        ),
        bg,
      );
    }

    final fg = Paint()
      ..color = color
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..style = PaintingStyle.fill;

    var cursor = x;
    for (final unit in text.toUpperCase().codeUnits) {
      final ch = String.fromCharCode(unit);
      final rows = PixelFont8.glyph(ch) ?? PixelFont8.glyph('?')!;
      for (var row = 0; row < PixelFont8.glyphHeight; row++) {
        final bits = rows[row];
        for (var col = 0; col < PixelFont8.glyphWidth; col++) {
          final on = (bits & (0x80 >> col)) != 0;
          if (!on) {
            continue;
          }
          canvas.drawRect(
            Rect.fromLTWH(
              (cursor + col * scale).toDouble(),
              (y + row * scale).toDouble(),
              scale.toDouble(),
              scale.toDouble(),
            ),
            fg,
          );
        }
      }
      cursor += PixelFont8.glyphWidth * scale;
    }
  }

  /// Builds an ARGB8888 buffer of the text at [scale] for tests / diagnostics.
  /// Transparent pixels use alpha 0; opaque pixels use [color].
  ByteData rasterize(
    String text, {
    Color color = GamePalette.ballGreen,
    Color background = GamePalette.black,
    int scale = 2,
  }) {
    assert(GamePalette.contains(color));
    assert(GamePalette.contains(background));
    final w = measureWidth(text, scale: scale);
    final h = measureHeight(scale: scale);
    final bytes = Uint8List(w * h * 4);

    void putPixel(int px, int py, Color c) {
      if (px < 0 || py < 0 || px >= w || py >= h) {
        return;
      }
      final i = (py * w + px) * 4;
      final v = c.toARGB32();
      bytes[i] = (v >> 16) & 0xFF;
      bytes[i + 1] = (v >> 8) & 0xFF;
      bytes[i + 2] = v & 0xFF;
      bytes[i + 3] = (v >> 24) & 0xFF;
    }

    for (var py = 0; py < h; py++) {
      for (var px = 0; px < w; px++) {
        putPixel(px, py, background);
      }
    }

    var cursor = 0;
    for (final unit in text.toUpperCase().codeUnits) {
      final ch = String.fromCharCode(unit);
      final rows = PixelFont8.glyph(ch) ?? PixelFont8.glyph('?')!;
      for (var row = 0; row < PixelFont8.glyphHeight; row++) {
        final bits = rows[row];
        for (var col = 0; col < PixelFont8.glyphWidth; col++) {
          if ((bits & (0x80 >> col)) == 0) {
            continue;
          }
          for (var sy = 0; sy < scale; sy++) {
            for (var sx = 0; sx < scale; sx++) {
              putPixel(cursor + col * scale + sx, row * scale + sy, color);
            }
          }
        }
      }
      cursor += PixelFont8.glyphWidth * scale;
    }

    return ByteData.sublistView(bytes);
  }

  /// Counts unique opaque RGB colors in a rasterized buffer.
  static int countUniqueColors(ByteData data) {
    final seen = <int>{};
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    for (var i = 0; i + 3 < bytes.length; i += 4) {
      final a = bytes[i + 3];
      if (a == 0) {
        continue;
      }
      final rgb = (bytes[i] << 16) | (bytes[i + 1] << 8) | bytes[i + 2];
      seen.add(rgb);
    }
    return seen.length;
  }
}
