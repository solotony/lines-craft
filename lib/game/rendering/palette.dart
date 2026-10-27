import 'dart:ui';

/// Fixed 16-color palette for all programmatic game graphics.
class GamePalette {
  GamePalette._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFEFEFE);
  static const Color panelGray = Color(0xFFAAAAAA);
  static const Color shadowGray = Color(0xFF555555);
  static const Color darkGray = Color(0xFF3A3A3A);
  static const Color ballRed = Color(0xFFFE0000);
  static const Color ballRedDark = Color(0xFFA70000);
  static const Color ballMagenta = Color(0xFFFE00FE);
  static const Color ballMagentaDark = Color(0xFFAC00AC);
  static const Color ballYellow = Color(0xFFFEFE00);
  static const Color ballOrange = Color(0xFFFEA800);
  static const Color ballGreen = Color(0xFF00AD00);
  static const Color ballBlue = Color(0xFF0000AE);
  static const Color ballCyan = Color(0xFF00FBFE);
  static const Color labelYellow = Color(0xFFFEE901);
  static const Color midGray = Color(0xFF767676);

  /// Exactly 16 unique colors, index order matches `docs/visual-reference.md`.
  static const List<Color> all = <Color>[
    black,
    white,
    panelGray,
    shadowGray,
    darkGray,
    ballRed,
    ballRedDark,
    ballMagenta,
    ballMagentaDark,
    ballYellow,
    ballOrange,
    ballGreen,
    ballBlue,
    ballCyan,
    labelYellow,
    midGray,
  ];

  static const int size = 16;

  static bool contains(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    for (final c in all) {
      if ((c.toARGB32() & 0x00FFFFFF) == value) {
        return true;
      }
    }
    return false;
  }

  /// Nearest palette color by Manhattan RGB distance (for sprite quantization).
  static Color quantize(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    Color best = all.first;
    var bestDist = 1 << 30;
    for (final c in all) {
      final v = c.toARGB32();
      final cr = (v >> 16) & 0xFF;
      final cg = (v >> 8) & 0xFF;
      final cb = v & 0xFF;
      final d = (r - cr).abs() + (g - cg).abs() + (b - cb).abs();
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }
}
