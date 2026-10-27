import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'palette.dart';

/// Draws character sprites and pedestals with nearest-neighbor filtering.
class SpriteRenderer {
  const SpriteRenderer();

  static const String kingAsset = 'assets/images/king.png';
  static const String pretenderAsset = 'assets/images/pretender.png';
  static const String kingLoseAsset = 'assets/images/king-lose.png';
  static const String pretenderWinsAsset = 'assets/images/pretender-wins.png';

  /// King pedestal top-center and sprite anchor.
  static const Offset kingPedestalTop = Offset(70, 280);
  static const Offset pretenderPedestalTop = Offset(570, 300);

  void paintPedestal(
    Canvas canvas, {
    required Offset topCenter,
    required double height,
    double width = 36,
  }) {
    final left = (topCenter.dx - width / 2).roundToDouble();
    final top = topCenter.dy.roundToDouble();
    final body = Paint()
      ..color = GamePalette.midGray
      ..isAntiAlias = false;
    final light = Paint()
      ..color = GamePalette.panelGray
      ..isAntiAlias = false;
    final dark = Paint()
      ..color = GamePalette.shadowGray
      ..isAntiAlias = false;

    // Column
    canvas.drawRect(Rect.fromLTWH(left, top, width, height), body);
    canvas.drawRect(Rect.fromLTWH(left, top, 3, height), light);
    canvas.drawRect(Rect.fromLTWH(left + width - 3, top, 3, height), dark);

    // Cap
    canvas.drawRect(Rect.fromLTWH(left - 4, top - 6, width + 8, 8), light);
    // Base
    canvas.drawRect(
      Rect.fromLTWH(left - 6, top + height, width + 12, 10),
      dark,
    );
  }

  void paintSprite(
    Canvas canvas,
    ui.Image image,
    Offset bottomCenter, {
    double maxHeight = 90,
  }) {
    final scale = (maxHeight / image.height).clamp(0.5, 2.0);
    // Prefer integer scale when close.
    final intScale = scale.round().clamp(1, 2);
    final w = image.width * intScale;
    final h = image.height * intScale;
    final left = (bottomCenter.dx - w / 2).roundToDouble();
    final top = (bottomCenter.dy - h).roundToDouble();
    final dest = Rect.fromLTWH(left, top, w.toDouble(), h.toDouble());
    paintImage(
      canvas: canvas,
      rect: dest,
      image: image,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      fit: BoxFit.fill,
    );
  }
}
