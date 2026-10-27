import 'dart:collection';

import '../model/board_state.dart';
import '../model/cell_position.dart';

/// Orthogonal pathfinding through empty cells (BFS).
class MovementService {
  const MovementService();

  static const _deltas = <CellPosition>[
    CellPosition(1, 0),
    CellPosition(-1, 0),
    CellPosition(0, 1),
    CellPosition(0, -1),
  ];

  /// Returns a path from [from] to [to] inclusive, or null if unreachable.
  /// The ball's own cell is treated as empty for routing.
  List<CellPosition>? findPath(
    BoardState board,
    CellPosition from,
    CellPosition to,
  ) {
    if (!from.isValid || !to.isValid) {
      return null;
    }
    if (from == to) {
      return <CellPosition>[from];
    }
    if (!board.isEmpty(to)) {
      return null;
    }

    final queue = Queue<CellPosition>();
    final cameFrom = <CellPosition, CellPosition?>{};
    queue.add(from);
    cameFrom[from] = null;

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == to) {
        return _reconstruct(cameFrom, to);
      }
      for (final d in _deltas) {
        final next = current + d;
        if (!next.isValid || cameFrom.containsKey(next)) {
          continue;
        }
        final blocked = !board.isEmpty(next) && next != from;
        if (blocked) {
          continue;
        }
        cameFrom[next] = current;
        queue.add(next);
      }
    }
    return null;
  }

  bool canMove(BoardState board, CellPosition from, CellPosition to) =>
      findPath(board, from, to) != null;

  List<CellPosition> _reconstruct(
    Map<CellPosition, CellPosition?> cameFrom,
    CellPosition end,
  ) {
    final path = <CellPosition>[];
    CellPosition? cur = end;
    while (cur != null) {
      path.add(cur);
      cur = cameFrom[cur];
    }
    return path.reversed.toList();
  }
}
