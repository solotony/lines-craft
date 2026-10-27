import 'dart:ui';

import 'package:flutter/painting.dart';

import 'board_layout.dart';
import 'palette.dart';

/// Draws a single recessed DOS-style cell.
class CellRenderer {
  const CellRenderer();

  void paint(
    Canvas canvas,
    int col,
    int row, {
    bool selected = false,
  }) {
    final rect = BoardLayout.cellRect(col, row);
    final floor = Paint()
      ..color = GamePalette.panelGray
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, floor);

    // Light top/left bevel
    final light = Paint()
      ..color = GamePalette.white
      ..isAntiAlias = false
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(rect.topLeft, rect.topRight - const Offset(1, 0), light);
    canvas.drawLine(rect.topLeft, rect.bottomLeft - const Offset(0, 1), light);

    // Dark bottom/right bevel
    final dark = Paint()
      ..color = GamePalette.shadowGray
      ..isAntiAlias = false
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, dark);
    canvas.drawLine(rect.topRight, rect.bottomRight, dark);

    // Inner recess hint
    final inset = rect.deflate(2);
    final recess = Paint()
      ..color = GamePalette.midGray
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    canvas.drawRect(inset, recess);

    if (selected) {
      final sel = Paint()
        ..color = GamePalette.white
        ..isAntiAlias = false
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect.deflate(1), sel);
    }
  }
}
