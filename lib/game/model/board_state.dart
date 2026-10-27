import 'ball_color.dart';
import 'cell_position.dart';

/// Mutable 9×9 board of optional ball colors.
class BoardState {
  BoardState([List<BallColor?>? cells])
      : _cells = cells ?? List<BallColor?>.filled(81, null);

  factory BoardState.empty() => BoardState();

  factory BoardState.fromMap(Map<CellPosition, BallColor> balls) {
    final board = BoardState.empty();
    for (final e in balls.entries) {
      board.set(e.key, e.value);
    }
    return board;
  }

  final List<BallColor?> _cells;

  BallColor? operator [](CellPosition pos) {
    if (!pos.isValid) {
      return null;
    }
    return _cells[_index(pos)];
  }

  void set(CellPosition pos, BallColor? color) {
    assert(pos.isValid);
    _cells[_index(pos)] = color;
  }

  bool isEmpty(CellPosition pos) => this[pos] == null;

  bool get isFull => _cells.every((c) => c != null);

  int get occupiedCount => _cells.where((c) => c != null).length;

  List<CellPosition> get emptyCells {
    final result = <CellPosition>[];
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final p = CellPosition(col, row);
        if (isEmpty(p)) {
          result.add(p);
        }
      }
    }
    return result;
  }

  BoardState copy() => BoardState(List<BallColor?>.from(_cells));

  static int _index(CellPosition pos) => pos.row * 9 + pos.col;
}
