import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/logic/game_controller.dart';
import 'package:lines/game/logic/line_detector.dart';
import 'package:lines/game/logic/movement_service.dart';
import 'package:lines/game/logic/scoring_service.dart';
import 'package:lines/game/logic/spawn_service.dart';
import 'package:lines/game/model/ball_color.dart';
import 'package:lines/game/model/board_state.dart';
import 'package:lines/game/model/cell_position.dart';
import 'package:lines/game/model/game_state.dart';

void main() {
  group('BoardState', () {
    test('empty board', () {
      final board = BoardState.empty();
      expect(board.occupiedCount, 0);
      expect(board.emptyCells.length, 81);
      expect(board.isFull, isFalse);
    });
  });

  group('MovementService', () {
    const move = MovementService();

    test('moves to empty cell along clear path', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      final path = move.findPath(
        board,
        const CellPosition(0, 0),
        const CellPosition(2, 0),
      );
      expect(path, isNotNull);
      expect(path!.first, const CellPosition(0, 0));
      expect(path.last, const CellPosition(2, 0));
    });

    test('blocks inaccessible path', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      // Wall of balls blocking row 0 except start
      for (var c = 1; c < 9; c++) {
        board.set(CellPosition(c, 1), BallColor.blue);
      }
      for (var r = 0; r < 9; r++) {
        board.set(CellPosition(1, r), BallColor.blue);
      }
      board.set(const CellPosition(1, 0), BallColor.blue);
      final path = move.findPath(
        board,
        const CellPosition(0, 0),
        const CellPosition(2, 0),
      );
      expect(path, isNull);
    });
  });

  group('LineDetector', () {
    const detector = LineDetector();

    test('four balls are not enough', () {
      final board = BoardState.empty();
      for (var c = 0; c < 4; c++) {
        board.set(CellPosition(c, 0), BallColor.red);
      }
      expect(detector.detect(board).found, isFalse);
    });

    test('horizontal five', () {
      final board = BoardState.empty();
      for (var c = 0; c < 5; c++) {
        board.set(CellPosition(c, 0), BallColor.red);
      }
      final r = detector.detect(board);
      expect(r.found, isTrue);
      expect(r.cells.length, 5);
      expect(r.lineLengths, [5]);
    });

    test('vertical five', () {
      final board = BoardState.empty();
      for (var r = 0; r < 5; r++) {
        board.set(CellPosition(3, r), BallColor.green);
      }
      expect(detector.detect(board).cells.length, 5);
    });

    test('diagonal down-right', () {
      final board = BoardState.empty();
      for (var i = 0; i < 5; i++) {
        board.set(CellPosition(i, i), BallColor.yellow);
      }
      final r = detector.detect(board);
      expect(r.cells.length, 5);
      expect(r.lineLengths, [5]);
    });

    test('diagonal up-right', () {
      final board = BoardState.empty();
      for (var i = 0; i < 5; i++) {
        board.set(CellPosition(i, 4 - i), BallColor.cyan);
      }
      final r = detector.detect(board);
      expect(r.cells.length, 5);
      expect(r.lineLengths, [5]);
    });

    test('longer than five', () {
      final board = BoardState.empty();
      for (var c = 0; c < 7; c++) {
        board.set(CellPosition(c, 2), BallColor.magenta);
      }
      final r = detector.detect(board);
      expect(r.lineLengths, [7]);
      expect(r.cells.length, 7);
    });

    test('intersecting lines', () {
      final board = BoardState.empty();
      for (var c = 0; c < 5; c++) {
        board.set(CellPosition(c, 2), BallColor.red);
      }
      for (var r = 0; r < 5; r++) {
        board.set(CellPosition(2, r), BallColor.red);
      }
      final result = detector.detect(board);
      // Plus shape: 5+5-1 = 9 unique cells
      expect(result.cells.length, 9);
      expect(result.lineLengths.length, 2);
    });
  });

  group('ScoringService', () {
    const scoring = ScoringService();

    test('provisional table', () {
      expect(scoring.pointsForLine(4), 0);
      expect(scoring.pointsForLine(5), 10);
      expect(scoring.pointsForLine(6), 12);
      expect(scoring.pointsForLine(7), 18);
      expect(scoring.pointsForLine(8), 28);
      expect(scoring.pointsForLine(9), 42);
    });
  });

  group('SpawnService', () {
    test('deterministic color sequence', () {
      final spawn = SpawnService(
        colorSequence: [
          BallColor.red,
          BallColor.blue,
          BallColor.green,
          BallColor.yellow,
        ],
      );
      expect(spawn.nextColor(), BallColor.red);
      expect(spawn.peekNext(2), [BallColor.blue, BallColor.green]);
    });

    test('places on empty cells only', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      final spawn = SpawnService(random: null);
      // Use forced positions
      final placed = spawn.placeBalls(
        board,
        [BallColor.blue, BallColor.green],
        forcedPositions: const [CellPosition(1, 0), CellPosition(2, 0)],
      );
      expect(placed.length, 2);
      expect(board[const CellPosition(1, 0)], BallColor.blue);
    });
  });

  group('GameController', () {
    test('initial placement of five balls with forced state', () {
      final board = BoardState.empty();
      for (var i = 0; i < 5; i++) {
        board.set(CellPosition(i, 0), BallColor.values[i]);
      }
      final controller = GameController(
        spawn: SpawnService(
          colorSequence: List.filled(20, BallColor.red),
        ),
      );
      final state = controller.startNewGame(
        board: board,
        next: [BallColor.red, BallColor.blue, BallColor.green],
      );
      expect(state.board.occupiedCount, 5);
      expect(state.nextBalls.length, 3);
    });

    test('selection and successful move without line spawns three', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      final spawn = SpawnService(
        colorSequence: [
          // next preview refill after spawn uses more colors
          ...List.filled(30, BallColor.blue),
        ],
      );
      final controller = GameController(spawn: spawn);
      controller.startNewGame(
        board: board,
        next: [BallColor.green, BallColor.yellow, BallColor.orange],
      );
      controller.select(const CellPosition(0, 0));
      final result = controller.tryMoveTo(const CellPosition(0, 2));
      expect(result.invalid, isFalse);
      expect(result.path, isNotNull);
      expect(controller.state.board[const CellPosition(0, 2)], BallColor.red);
      expect(controller.state.board[const CellPosition(0, 0)], isNull);
      // 1 ball moved + 3 spawned = 4 occupied (unless overlap)
      expect(controller.state.board.occupiedCount, 4);
      expect(result.spawned.length, 3);
    });

    test('beginMove defers spawn until resolve', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      final controller = GameController(
        spawn: SpawnService(colorSequence: List.filled(30, BallColor.blue)),
      );
      controller.startNewGame(
        board: board,
        next: [BallColor.green, BallColor.yellow, BallColor.orange],
      );
      controller.select(const CellPosition(0, 0));
      final begun = controller.beginMove(const CellPosition(0, 2));
      expect(begun.aftermath, TurnAftermath.spawn);
      expect(controller.state.board.occupiedCount, 1);
      expect(controller.spawnNext(), isNotNull);
      expect(controller.spawnNext(), isNotNull);
      expect(controller.spawnNext(), isNotNull);
      expect(controller.hasPendingSpawnBalls, isFalse);
      final finished = controller.finishPendingSpawn();
      expect(finished.spawned.length, 3);
      expect(controller.state.board.occupiedCount, 4);
    });

    test('beginMove defers line clear until applyPendingClear', () {
      final board = BoardState.empty();
      for (var c = 0; c < 4; c++) {
        board.set(CellPosition(c, 0), BallColor.red);
      }
      board.set(const CellPosition(0, 1), BallColor.red);
      final controller = GameController(
        spawn: SpawnService(colorSequence: List.filled(20, BallColor.blue)),
      );
      controller.startNewGame(
        board: board,
        next: [BallColor.blue, BallColor.blue, BallColor.blue],
      );
      controller.select(const CellPosition(0, 1));
      final begun = controller.beginMove(const CellPosition(4, 0));
      expect(begun.aftermath, TurnAftermath.clearLine);
      expect(controller.state.board.occupiedCount, 5);
      expect(controller.state.score, 0);
      final cleared = controller.applyPendingClear();
      expect(cleared.pointsGained, 10);
      expect(controller.state.board.occupiedCount, 0);
      expect(controller.state.score, 10);
    });

    test('line clear awards points and skips spawn', () {
      final board = BoardState.empty();
      for (var c = 0; c < 4; c++) {
        board.set(CellPosition(c, 0), BallColor.red);
      }
      board.set(const CellPosition(0, 1), BallColor.red);
      final controller = GameController(
        spawn: SpawnService(colorSequence: List.filled(20, BallColor.blue)),
      );
      controller.startNewGame(
        board: board,
        next: [BallColor.blue, BallColor.blue, BallColor.blue],
      );
      controller.select(const CellPosition(0, 1));
      final result = controller.tryMoveTo(const CellPosition(4, 0));
      expect(result.pointsGained, 10);
      expect(result.spawned, isEmpty);
      expect(controller.state.score, 10);
      expect(controller.state.board.occupiedCount, 0);
    });

    test('invalid move does not change state', () {
      final board = BoardState.empty();
      board.set(const CellPosition(0, 0), BallColor.red);
      board.set(const CellPosition(1, 0), BallColor.blue);
      final controller = GameController(
        spawn: SpawnService(colorSequence: List.filled(20, BallColor.green)),
      );
      controller.startNewGame(
        board: board,
        next: [BallColor.green, BallColor.green, BallColor.green],
      );
      controller.select(const CellPosition(0, 0));
      final before = controller.state.board.occupiedCount;
      final result = controller.tryMoveTo(const CellPosition(1, 0));
      expect(result.invalid, isTrue);
      expect(controller.state.board.occupiedCount, before);
    });

    test('game over when board is full', () {
      final board = BoardState.empty();
      final colors = BallColor.values;
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (r == 0 && c == 1) {
            continue; // single empty adjacent to mover
          }
          if (r == 0 && c == 0) {
            board.set(const CellPosition(0, 0), BallColor.red);
            continue;
          }
          // Checkerboard-ish mix so no 5-in-a-row of same color.
          board.set(CellPosition(c, r), colors[(c + r * 3) % colors.length]);
        }
      }
      final controller = GameController(
        spawn: SpawnService(colorSequence: List.filled(20, BallColor.orange)),
      );
      controller.startNewGame(
        board: board,
        next: [BallColor.orange, BallColor.orange, BallColor.orange],
      );
      expect(controller.state.board.emptyCells.length, 1);
      expect(const LineDetector().detect(controller.state.board).found, isFalse);
      controller.select(const CellPosition(0, 0));
      final result = controller.tryMoveTo(const CellPosition(1, 0));
      expect(result.invalid, isFalse);
      expect(controller.state.phase, GamePhase.gameOver);
      expect(controller.state.board.isFull, isTrue);
    });
  });
}
