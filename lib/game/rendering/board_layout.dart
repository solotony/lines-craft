import 'dart:ui';

/// Virtual-pixel geometry for the 9×9 board (see docs/visual-reference.md).
class BoardLayout {
  BoardLayout._();

  static const int columns = 9;
  static const int rows = 9;

  /// Top-left of cell (0,0) interior (inside left/top groove).
  static const int originX = 171;
  static const int originY = 83;

  static const int cellPitchX = 34;
  static const int cellPitchY = 33;

  /// Interior fill size (pitch minus 1 px groove on the far side).
  static const int cellWidth = 33;
  static const int cellHeight = 32;

  static Rect cellRect(int col, int row) {
    assert(col >= 0 && col < columns);
    assert(row >= 0 && row < rows);
    return Rect.fromLTWH(
      (originX + col * cellPitchX).toDouble(),
      (originY + row * cellPitchY).toDouble(),
      cellWidth.toDouble(),
      cellHeight.toDouble(),
    );
  }

  static Offset cellCenter(int col, int row) => cellRect(col, row).center;

  /// Outer board frame including outer grooves.
  static Rect get boardBounds => Rect.fromLTWH(
        (originX - 1).toDouble(),
        (originY - 1).toDouble(),
        (columns * cellPitchX + 1).toDouble(),
        (rows * cellPitchY + 1).toDouble(),
      );

  /// Maps a virtual-pixel point to a cell, or null if outside the board.
  static (int col, int row)? hitTest(Offset point) {
    final localX = point.dx - originX;
    final localY = point.dy - originY;
    if (localX < 0 || localY < 0) {
      return null;
    }
    final col = localX ~/ cellPitchX;
    final row = localY ~/ cellPitchY;
    if (col < 0 || col >= columns || row < 0 || row >= rows) {
      return null;
    }
    final rect = cellRect(col, row);
    if (!rect.contains(point)) {
      // Click landed on groove; still accept nearest cell if inside pitch.
      return (col, row);
    }
    return (col, row);
  }
}
