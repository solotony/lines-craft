import 'dart:ui';

import '../rendering/palette.dart';

/// The seven playable ball colors.
enum BallColor {
  red,
  magenta,
  yellow,
  orange,
  green,
  blue,
  cyan;

  Color get base {
    switch (this) {
      case BallColor.red:
        return GamePalette.ballRed;
      case BallColor.magenta:
        return GamePalette.ballMagenta;
      case BallColor.yellow:
        return GamePalette.ballYellow;
      case BallColor.orange:
        return GamePalette.ballOrange;
      case BallColor.green:
        return GamePalette.ballGreen;
      case BallColor.blue:
        return GamePalette.ballBlue;
      case BallColor.cyan:
        return GamePalette.ballCyan;
    }
  }

  Color get shade {
    switch (this) {
      case BallColor.red:
        return GamePalette.ballRedDark;
      case BallColor.magenta:
        return GamePalette.ballMagentaDark;
      case BallColor.yellow:
        return GamePalette.ballOrange;
      case BallColor.orange:
        return GamePalette.darkGray;
      case BallColor.green:
        return GamePalette.shadowGray;
      case BallColor.blue:
        return GamePalette.darkGray;
      case BallColor.cyan:
        return GamePalette.ballBlue;
    }
  }

  Color get highlight => GamePalette.white;
}
