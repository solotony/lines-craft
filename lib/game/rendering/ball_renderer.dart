import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart';

import '../model/ball_color.dart';
import 'palette.dart';

/// Draws a lit 3-D sphere, frequency-dithered into [GamePalette] (Bayer 4×4).
class BallRenderer {
  const BallRenderer();

  /// Ordered dither matrix; thresholds are `(value + 0.5) / 16`.
  static const List<List<int>> bayer4 = <List<int>>[
    <int>[0, 8, 2, 10],
    <int>[12, 4, 14, 6],
    <int>[3, 11, 1, 9],
    <int>[15, 7, 13, 5],
  ];

  // Unit-ish light from upper-left toward the camera.
  static const double _lx = -0.42;
  static const double _ly = -0.58;
  static const double _lz = 0.70;

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

    final cx = center.dx.roundToDouble();
    final cy = center.dy.roundToDouble();
    final ir = r.round();
    final r2 = ir * ir;

    final pixel = Paint()..isAntiAlias = false;

    for (var dy = -ir; dy <= ir; dy++) {
      for (var dx = -ir; dx <= ir; dx++) {
        if (dx * dx + dy * dy > r2) {
          continue;
        }

        final intensity = _intensity(dx, dy, ir);
        if (intensity == null) {
          continue;
        }
        pixel.color = _ditheredColor(color, intensity, dx, dy);
        canvas.drawRect(Rect.fromLTWH(cx + dx, cy + dy, 1, 1), pixel);
      }
    }
  }

  /// Lambert + specular intensity in \[0, 1\], or null outside the sphere.
  static double? _intensity(int dx, int dy, int r) {
    final nx = dx / r;
    final ny = dy / r;
    final rr = nx * nx + ny * ny;
    if (rr > 1.0) {
      return null;
    }
    final nz = math.sqrt(1.0 - rr);

    final ndotl = nx * _lx + ny * _ly + nz * _lz;
    final diff = math.max(0.0, ndotl);

    // R = 2(N·L)N − L; V = (0,0,1) → R·V = Rz
    final rz = 2 * ndotl * nz - _lz;
    final spec = math.pow(math.max(0.0, rz), 28).toDouble();

    var i = 0.12 + 0.72 * diff + 0.55 * spec;
    // Soft rim darkening so the silhouette reads as round.
    i *= 0.65 + 0.35 * nz;
    return i.clamp(0.0, 1.0);
  }

  /// Maps intensity onto black → shade → base → white with Bayer dither.
  static Color _ditheredColor(
    BallColor color,
    double intensity,
    int dx,
    int dy,
  ) {
    final stops = <Color>[
      GamePalette.black,
      color.shade,
      color.base,
      color.highlight,
    ];
    return ditherStops(_toneMap(intensity), stops, dx, dy);
  }

  /// Bias midtones toward [base]; keep the specular highlight compact.
  static double _toneMap(double i) {
    if (i < 0.32) {
      return (i / 0.32) * (1 / 3);
    }
    if (i < 0.70) {
      return (1 / 3) + ((i - 0.32) / 0.38) * (1 / 3);
    }
    return (2 / 3) + ((i - 0.70) / 0.30).clamp(0.0, 1.0) * (1 / 3);
  }

  /// Frequency dither along a discrete palette ramp.
  static Color ditherStops(double t, List<Color> stops, int x, int y) {
    assert(stops.length >= 2);
    final n = stops.length - 1;
    final scaled = t.clamp(0.0, 1.0) * n;
    final i = scaled.floor().clamp(0, n - 1);
    final f = scaled - i;
    final thr = (bayer4[y & 3][x & 3] + 0.5) / 16.0;
    return f > thr ? stops[i + 1] : stops[i];
  }
}
