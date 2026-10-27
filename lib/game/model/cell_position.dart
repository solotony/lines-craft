/// Board coordinates (column x, row y), origin top-left.
class CellPosition {
  const CellPosition(this.col, this.row);

  final int col;
  final int row;

  bool get isValid =>
      col >= 0 && col < 9 && row >= 0 && row < 9;

  CellPosition operator +(CellPosition other) =>
      CellPosition(col + other.col, row + other.row);

  @override
  bool operator ==(Object other) =>
      other is CellPosition && other.col == col && other.row == row;

  @override
  int get hashCode => Object.hash(col, row);

  @override
  String toString() => '($col,$row)';
}
