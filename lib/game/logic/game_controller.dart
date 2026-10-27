import '../model/ball_color.dart';
import '../model/board_state.dart';
import '../model/cell_position.dart';
import '../model/game_state.dart';
import 'line_detector.dart';
import 'movement_service.dart';
import 'scoring_service.dart';
import 'spawn_service.dart';

class MoveResult {
  const MoveResult({
    required this.state,
    this.path,
    this.cleared = const <CellPosition>[],
    this.pointsGained = 0,
    this.spawned = const <CellPosition>[],
    this.invalid = false,
  });

  final GameState state;
  final List<CellPosition>? path;
  final List<CellPosition> cleared;
  final int pointsGained;
  final List<CellPosition> spawned;
  final bool invalid;
}

/// Orchestrates selection, movement, clears, spawn, and game-over.
class GameController {
  GameController({
    MovementService? movement,
    LineDetector? lines,
    ScoringService? scoring,
    SpawnService? spawn,
  })  : _movement = movement ?? const MovementService(),
        _lines = lines ?? const LineDetector(),
        _scoring = scoring ?? const ScoringService(),
        _spawn = spawn ?? SpawnService();

  final MovementService _movement;
  final LineDetector _lines;
  final ScoringService _scoring;
  final SpawnService _spawn;

  GameState get state => _state;
  late GameState _state;

  /// Starts a new game. Optional [board] / [next] for tests.
  GameState startNewGame({
    BoardState? board,
    List<BallColor>? next,
    int kingScore = 100,
    List<CellPosition>? initialPositions,
  }) {
    final b = board?.copy() ?? BoardState.empty();
    final upcoming = next ?? _spawn.peekNext(SpawnService.spawnPerTurn);

    if (board == null) {
      final colors = _spawn.peekNext(SpawnService.initialBallCount);
      _spawn.placeBalls(b, colors, forcedPositions: initialPositions);
    }

    _state = GameState.initial(
      board: b,
      nextBalls: upcoming.length >= 3
          ? upcoming.sublist(0, 3)
          : [
              ...upcoming,
              ..._spawn.peekNext(3 - upcoming.length),
            ],
      kingScore: kingScore,
    );
    return _state;
  }

  /// Loads an exact state (tests / restore).
  void load(GameState state) {
    _state = state.copyWith(board: state.board);
  }

  GameState select(CellPosition pos) {
    if (_state.phase == GamePhase.gameOver) {
      return _state;
    }
    if (!_state.board.isEmpty(pos)) {
      _state = _state.copyWith(selected: pos);
    } else if (_state.selected != null) {
      // Destination click handled by moveTo.
    }
    return _state;
  }

  MoveResult tryMoveTo(CellPosition dest) {
    if (_state.phase == GamePhase.gameOver) {
      return MoveResult(state: _state, invalid: true);
    }
    final from = _state.selected;
    if (from == null) {
      return MoveResult(state: _state, invalid: true);
    }
    if (!_state.board.isEmpty(dest)) {
      // Select other ball instead.
      select(dest);
      return MoveResult(state: _state, invalid: true);
    }

    final path = _movement.findPath(_state.board, from, dest);
    if (path == null) {
      return MoveResult(state: _state, invalid: true);
    }

    final board = _state.board.copy();
    final color = board[from]!;
    board.set(from, null);
    board.set(dest, color);

    var score = _state.score;
    var beatKing = _state.beatKing;
    var next = List<BallColor>.from(_state.nextBalls);
    final cleared = <CellPosition>[];
    var points = 0;
    final spawned = <CellPosition>[];

    final lineAfterMove = _lines.detect(board);
    if (lineAfterMove.found) {
      points = _scoring.pointsForLines(lineAfterMove.lineLengths);
      score += points;
      for (final c in lineAfterMove.cells) {
        board.set(c, null);
        cleared.add(c);
      }
      // Successful clear: no spawn this turn.
    } else {
      // Spawn the previewed balls, then refill preview.
      final toPlace = List<BallColor>.from(next);
      spawned.addAll(_spawn.placeBalls(board, toPlace));
      next = _spawn.peekNext(SpawnService.spawnPerTurn);

      // Spawned balls may form lines; clear and score, but no extra turn.
      final lineAfterSpawn = _lines.detect(board);
      if (lineAfterSpawn.found) {
        final spawnPoints = _scoring.pointsForLines(lineAfterSpawn.lineLengths);
        points += spawnPoints;
        score += spawnPoints;
        for (final c in lineAfterSpawn.cells) {
          board.set(c, null);
          cleared.add(c);
        }
      }
    }

    if (!beatKing && score > _state.kingScore) {
      beatKing = true;
    }

    final phase =
        board.isFull ? GamePhase.gameOver : GamePhase.playing;

    _state = GameState(
      board: board,
      nextBalls: next,
      selected: null,
      score: score,
      kingScore: _state.kingScore,
      phase: phase,
      beatKing: beatKing,
    );

    return MoveResult(
      state: _state,
      path: path,
      cleared: cleared,
      pointsGained: points,
      spawned: spawned,
    );
  }

  /// Tap handler: select ball or attempt move.
  MoveResult onCellTapped(CellPosition pos) {
    if (_state.phase == GamePhase.gameOver) {
      return MoveResult(state: _state, invalid: true);
    }
    final selected = _state.selected;
    if (!_state.board.isEmpty(pos)) {
      select(pos);
      return MoveResult(state: _state);
    }
    if (selected != null) {
      return tryMoveTo(pos);
    }
    return MoveResult(state: _state, invalid: true);
  }
}
