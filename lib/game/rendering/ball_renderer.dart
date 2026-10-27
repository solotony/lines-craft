import 'dart:ui';

import 'package:flutter/painting.dart';

import '../model/ball_color.dart';
import 'palette.dart';

/// Draws a discrete-region ball with no anti-aliasing.
class BallRenderer {
  const BallRenderer();

  void paint(
    Canvas canvas,
    Offset center, {
    required BallColor color,
    double diameter = 24,
  }) {
    final r = (diameter / 2).floorToDouble();
    if (r < 2) {
      return;
    }

    final base = Paint()
      ..color = color.base
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    final shade = Paint()
      ..color = color.shade
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    final highlight = Paint()
      ..color = color.highlight
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = GamePalette.black
      ..isAntiAlias = false
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cx = center.dx.roundToDouble();
    final cy = center.dy.roundToDouble();

    // Filled disc via pixel blocks (integer coords).
    final ir = r.round();
    for (var dy = -ir; dy <= ir; dy++) {
      for (var dx = -ir; dx <= ir; dx++) {
        if (dx * dx + dy * dy > ir * ir) {
          continue;
        }
        final paint = _regionPaint(dx, dy, ir, base, shade, highlight);
        canvas.drawRect(
          Rect.fromLTWH(cx + dx, cy + dy, 1, 1),
          paint,
        );
      }
    }

    // Crisp outline on the ring.
    for (var dy = -ir; dy <= ir; dy++) {
      for (var dx = -ir; dx <= ir; dx++) {
        final d2 = dx * dx + dy * dy;
        if (d2 > ir * ir || d2 < (ir - 1) * (ir - 1)) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(cx + dx, cy + dy, 1, 1),
          Paint()
            ..color = GamePalette.black
            ..isAntiAlias = false,
        );
      }
    }

    // Silence unused warning if tree-shaken differently
    outline;
  }

  Paint _regionPaint(
    int dx,
    int dy,
    int r,
    Paint base,
    Paint shade,
    Paint highlight,
  ) {
    // Highlight: upper-left quadrant near rim
    if (dx < -r * 0.15 && dy < -r * 0.15 && dx * dx + dy * dy < r * r * 0.55) {
      return highlight;
    }
    // Shade: lower-right
    if (dx > r * 0.1 && dy > r * 0.1) {
      return shade;
    }
    return base;
  }
}
