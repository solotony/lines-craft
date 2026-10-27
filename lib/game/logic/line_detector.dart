import '../model/ball_color.dart';
import '../model/board_state.dart';
import '../model/cell_position.dart';

class LineResult {
  const LineResult({
    required this.cells,
    required this.lineLengths,
  });

  /// Union of all cells belonging to qualifying lines.
  final Set<CellPosition> cells;

  /// Length of each distinct qualifying run (≥5).
  final List<int> lineLengths;

  bool get found => cells.isNotEmpty;
}

/// Detects lines of 5+ same-color balls in 4 directions.
class LineDetector {
  const LineDetector({this.minLength = 5});

  final int minLength;

  static const _dirs = <(int, int)>[
    (1, 0), // horizontal
    (0, 1), // vertical
    (1, 1), // diagonal down-right
    (1, -1), // diagonal up-right
  ];

  LineResult detect(BoardState board) {
    final cells = <CellPosition>{};
    final lengths = <int>[];
    final seenRuns = <String>{};

    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final start = CellPosition(col, row);
        final color = board[start];
        if (color == null) {
          continue;
        }
        for (final dir in _dirs) {
          // Only start a run at the beginning of a streak in this direction.
          final prev = CellPosition(col - dir.$1, row - dir.$2);
          if (prev.isValid && board[prev] == color) {
            continue;
          }
          final run = _collectRun(board, start, color, dir);
          if (run.length >= minLength) {
            final key = _runKey(run);
            if (seenRuns.add(key)) {
              cells.addAll(run);
              lengths.add(run.length);
            }
          }
        }
      }
    }

    return LineResult(cells: cells, lineLengths: lengths);
  }

  List<CellPosition> _collectRun(
    BoardState board,
    CellPosition start,
    BallColor color,
    (int, int) dir,
  ) {
    final run = <CellPosition>[];
    var cur = start;
    while (cur.isValid && board[cur] == color) {
      run.add(cur);
      cur = CellPosition(cur.col + dir.$1, cur.row + dir.$2);
    }
    return run;
  }

  String _runKey(List<CellPosition> run) {
    final sorted = List<CellPosition>.from(run)
      ..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);
    return sorted.map((p) => '${p.col},${p.row}').join('|');
  }
}
