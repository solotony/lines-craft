import 'dart:ui';

import 'package:flutter/painting.dart';

import 'board_layout.dart';
import 'cell_renderer.dart';
import 'palette.dart';

/// Paints the full 9×9 board including outer frame and grooves.
class BoardRenderer {
  const BoardRenderer({this.cellRenderer = const CellRenderer()});

  final CellRenderer cellRenderer;

  void paint(
    Canvas canvas, {
    (int col, int row)? selected,
  }) {
    final bounds = BoardLayout.boardBounds;

    final outer = Paint()
      ..color = GamePalette.darkGray
      ..isAntiAlias = false;
    canvas.drawRect(bounds.inflate(2), outer);

    final groove = Paint()
      ..color = GamePalette.black
      ..isAntiAlias = false;
    canvas.drawRect(bounds, groove);

    for (var row = 0; row < BoardLayout.rows; row++) {
      for (var col = 0; col < BoardLayout.columns; col++) {
        final isSelected =
            selected != null && selected.$1 == col && selected.$2 == row;
        cellRenderer.paint(canvas, col, row, selected: isSelected);
      }
    }
  }

  int get cellCount => BoardLayout.columns * BoardLayout.rows;
}
