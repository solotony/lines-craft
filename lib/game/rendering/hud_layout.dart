import 'dart:math' as math;
import 'dart:ui';

import 'board_layout.dart';
import 'pixel_font_8.dart';
import 'pixel_text_renderer.dart';

/// Geometry for top/bottom chrome, score boxes, next preview, and F-keys.
class HudLayout {
  HudLayout._();

  static const double canvasWidth = 640;
  static const double canvasHeight = 480;

  static const double topBarHeight = 42;
  static const double bottomBarTop = 423;
  static const double bottomBarHeight = 57;

  /// King / pretender column anchors (horizontal centers).
  static const double kingCenterX = 70;
  static const double pretenderCenterX = 570;

  /// Score / F-key caption digit scale (slightly smaller than prior HUD 2×).
  static const int scoreScale = 1;
  static const int scoreDigits = 6;
  static const double scoreEdgeMargin = 16;
  static const double scorePadX = 6;
  static const double scorePadY = 4;
  static const double frameBorder = 2;

  static const int nameScale = 1;

  static const double maxColumnCells = 5;
  static const double minColumnShaft = 16;
  static const double pedestalBaseHeight = 10;
  static const double pedestalCapHeight = 6;
  static const double pedestalWidth = 36;

  static const double nextBallSpacing = 28;
  static const double nextBallDiameter = 14;
  static const double nextCellSize = 20;

  static const double fButtonWidth = 40;
  static const double fButtonHeight = 22;
  static const double fLabelPadX = 4;
  static const double fLabelPadY = 2;
  static const double fStackGap = 4;
  static const double fBarSideMargin = 36;

  static final PixelTextRenderer _text = const PixelTextRenderer();

  static double get scoreInnerWidth =>
      scoreDigits * PixelFont8.glyphWidth * scoreScale.toDouble();

  static double get scoreInnerHeight =>
      PixelFont8.glyphHeight * scoreScale.toDouble();

  static double get scoreBoxWidth =>
      scoreInnerWidth + scorePadX * 2 + frameBorder * 2;

  static double get scoreBoxHeight =>
      scoreInnerHeight + scorePadY * 2 + frameBorder * 2;

  /// Vertical center line shared by scores, Next/Colors, and preview balls.
  static double get topHudMidY => topBarHeight / 2;

  static Rect get leftScoreBox => Rect.fromLTWH(
        scoreEdgeMargin,
        topHudMidY - scoreBoxHeight / 2,
        scoreBoxWidth,
        scoreBoxHeight,
      );

  static Rect get rightScoreBox => Rect.fromLTWH(
        canvasWidth - scoreEdgeMargin - scoreBoxWidth,
        topHudMidY - scoreBoxHeight / 2,
        scoreBoxWidth,
        scoreBoxHeight,
      );

  /// Center X of the three next-ball cells (exactly mid-screen).
  static double get nextPreviewCenterX => canvasWidth / 2;

  static Offset nextBallCenter(int index) {
    assert(index >= 0 && index < 3);
    return Offset(
      nextPreviewCenterX + (index - 1) * nextBallSpacing,
      topHudMidY,
    );
  }

  static Rect nextBallCell(int index) {
    final c = nextBallCenter(index);
    return Rect.fromCenter(
      center: c,
      width: nextCellSize,
      height: nextCellSize,
    );
  }

  static double get nextLabelY =>
      topHudMidY - _text.measureHeight(scale: scoreScale) / 2;

  /// Right edge gap before the first next cell.
  static Offset get nextLabelOrigin {
    final first = nextBallCell(0);
    final w = _text.measureWidth('NEXT', scale: scoreScale);
    return Offset(first.left - 10 - w, nextLabelY);
  }

  static Offset get colorsLabelOrigin {
    final last = nextBallCell(2);
    return Offset(last.right + 10, nextLabelY);
  }

  static double get boardBottom => BoardLayout.boardBounds.bottom;

  static double get nameHeight =>
      _text.measureHeight(scale: nameScale).toDouble();

  /// Top of character name text — flush with board bottom.
  static double get nameTop => boardBottom;

  /// Bottom of pedestal base sits half a name-height above the name.
  static double get columnBaseBottom => nameTop - nameHeight / 2;

  static double maxColumnShaftHeight() =>
      maxColumnCells * BoardLayout.cellHeight;

  /// Winner shaft is max height; trailing score scales down toward zero.
  static double columnShaftHeight(int ownScore, int rivalScore) {
    final maxH = maxColumnShaftHeight();
    final lead = math.max(ownScore, rivalScore);
    if (lead <= 0) {
      return maxH;
    }
    if (ownScore >= rivalScore) {
      return maxH;
    }
    final scaled = maxH * ownScore / lead;
    return math.max(minColumnShaft, scaled);
  }

  /// Top-center of the column shaft (sprite stands here).
  static Offset pedestalTop(double centerX, double shaftHeight) {
    final shaftBottom = columnBaseBottom - pedestalBaseHeight;
    return Offset(centerX, shaftBottom - shaftHeight);
  }

  static double get fLabelInnerHeight =>
      PixelFont8.glyphHeight * scoreScale.toDouble();

  static double fLabelBoxWidth(String label) {
    final textW = _text.measureWidth(label, scale: scoreScale);
    return textW + fLabelPadX * 2 + frameBorder * 2;
  }

  static double get fLabelBoxHeight =>
      fLabelInnerHeight + fLabelPadY * 2 + frameBorder * 2;

  static double get fStackHeight =>
      fButtonHeight + fStackGap + fLabelBoxHeight;

  static double get fStackTop =>
      bottomBarTop + (bottomBarHeight - fStackHeight) / 2;

  /// Centers of the four F-key stacks across the bottom bar.
  static double fKeyCenterX(int index) {
    assert(index >= 0 && index < 4);
    final usable = canvasWidth - fBarSideMargin * 2;
    final step = usable / 4;
    return fBarSideMargin + step * (index + 0.5);
  }

  static Rect fButtonRect(int index) {
    final cx = fKeyCenterX(index);
    return Rect.fromCenter(
      center: Offset(cx, fStackTop + fButtonHeight / 2),
      width: fButtonWidth,
      height: fButtonHeight,
    );
  }

  static Rect fLabelRect(int index, String label) {
    final cx = fKeyCenterX(index);
    final w = fLabelBoxWidth(label);
    final top = fStackTop + fButtonHeight + fStackGap;
    return Rect.fromLTWH(cx - w / 2, top, w, fLabelBoxHeight);
  }

  /// Returns 0..3 for F1..F4, or null if miss.
  static int? hitTestFKey(Offset point) {
    for (var i = 0; i < 4; i++) {
      if (fButtonRect(i).inflate(2).contains(point)) {
        return i;
      }
    }
    return null;
  }
}
