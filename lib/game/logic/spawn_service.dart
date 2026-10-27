import 'dart:math';

import '../model/ball_color.dart';
import '../model/board_state.dart';
import '../model/cell_position.dart';

/// Produces upcoming ball colors and places them on empty cells.
class SpawnService {
  SpawnService({Random? random, List<BallColor>? colorSequence})
      : _random = random ?? Random(),
        _sequence = colorSequence == null
            ? null
            : List<BallColor>.from(colorSequence),
        _seqIndex = 0;

  final Random _random;
  final List<BallColor>? _sequence;
  int _seqIndex;

  static const int initialBallCount = 5;
  static const int spawnPerTurn = 3;

  BallColor nextColor() {
    if (_sequence != null) {
      if (_seqIndex >= _sequence!.length) {
        throw StateError('Color sequence exhausted');
      }
      return _sequence![_seqIndex++];
    }
    final values = BallColor.values;
    return values[_random.nextInt(values.length)];
  }

  List<BallColor> peekNext(int count) {
    final result = <BallColor>[];
    for (var i = 0; i < count; i++) {
      result.add(nextColor());
    }
    return result;
  }

  /// Places up to [count] balls from [colors] onto random empty cells.
  /// Returns positions that were filled (may be fewer if board fills).
  List<CellPosition> placeBalls(
    BoardState board,
    List<BallColor> colors, {
    List<CellPosition>? forcedPositions,
  }) {
    final placed = <CellPosition>[];
    final empties = board.emptyCells;
    if (empties.isEmpty) {
      return placed;
    }

    if (forcedPositions != null) {
      for (var i = 0; i < colors.length && i < forcedPositions.length; i++) {
        final pos = forcedPositions[i];
        if (board.isEmpty(pos)) {
          board.set(pos, colors[i]);
          placed.add(pos);
        }
      }
      return placed;
    }

    empties.shuffle(_random);
    final n = min(colors.length, empties.length);
    for (var i = 0; i < n; i++) {
      board.set(empties[i], colors[i]);
      placed.add(empties[i]);
    }
    return placed;
  }
}
