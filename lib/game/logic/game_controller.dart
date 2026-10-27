import '../model/ball_color.dart';
import '../model/board_state.dart';
import '../model/cell_position.dart';
import '../model/game_state.dart';
import 'line_detector.dart';
import 'movement_service.dart';
import 'scoring_service.dart';
import 'spawn_service.dart';

enum TurnAftermath { none, clearLine, spawn }

class MoveResult {
  const MoveResult({
    required this.state,
    this.path,
    this.cleared = const <CellPosition>[],
    this.pointsGained = 0,
    this.spawned = const <CellPosition>[],
    this.invalid = false,
    this.aftermath = TurnAftermath.none,
  });

  final GameState state;
  final List<CellPosition>? path;
  final List<CellPosition> cleared;
  final int pointsGained;
  final List<CellPosition> spawned;
  final bool invalid;
  final TurnAftermath aftermath;
}

class _PendingTurn {
  _PendingTurn.clear({
    required this.clearCells,
    required this.lineLengths,
  }) : spawnColors = null;

  _PendingTurn.spawn(this.spawnColors)
      : clearCells = null,
        lineLengths = null;

  final List<CellPosition>? clearCells;
  final List<int>? lineLengths;
  final List<BallColor>? spawnColors;
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

  _PendingTurn? _pending;
  final List<CellPosition> _spawnedThisTurn = [];

  bool get hasPendingTurn => _pending != null;

  TurnAftermath get pendingAftermath {
    final pending = _pending;
    if (pending == null) {
      return TurnAftermath.none;
    }
    if (pending.clearCells != null) {
      return TurnAftermath.clearLine;
    }
    return TurnAftermath.spawn;
  }

  /// Starts a new game. Optional [board] / [next] for tests.
  GameState startNewGame({
    BoardState? board,
    List<BallColor>? next,
    int kingScore = 100,
    List<CellPosition>? initialPositions,
  }) {
    _pending = null;
    _spawnedThisTurn.clear();
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
    _pending = null;
    _spawnedThisTurn.clear();
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

  /// Moves the selected ball to [dest] without clearing or spawning.
  /// Aftermath (line clear or spawn) stays pending for [resolvePending] /
  /// [spawnNext] / [applyPendingClear].
  MoveResult beginMove(CellPosition dest) {
    if (_state.phase == GamePhase.gameOver || _pending != null) {
      return MoveResult(state: _state, invalid: true);
    }
    final from = _state.selected;
    if (from == null) {
      return MoveResult(state: _state, invalid: true);
    }
    if (!_state.board.isEmpty(dest)) {
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

    final lineAfterMove = _lines.detect(board);
    if (lineAfterMove.found) {
      _pending = _PendingTurn.clear(
        clearCells: List<CellPosition>.from(lineAfterMove.cells),
        lineLengths: List<int>.from(lineAfterMove.lineLengths),
      );
    } else {
      _pending = _PendingTurn.spawn(List<BallColor>.from(_state.nextBalls));
      _spawnedThisTurn.clear();
    }

    _state = _state.copyWith(
      board: board,
      clearSelected: true,
    );

    return MoveResult(
      state: _state,
      path: path,
      aftermath: pendingAftermath,
    );
  }

  /// Removes a pending line and awards points. No-op if spawn is pending.
  MoveResult applyPendingClear() {
    final pending = _pending;
    final cells = pending?.clearCells;
    final lengths = pending?.lineLengths;
    if (cells == null || lengths == null) {
      return MoveResult(state: _state, invalid: true);
    }

    final board = _state.board.copy();
    for (final c in cells) {
      board.set(c, null);
    }
    final points = _scoring.pointsForLines(lengths);
    final score = _state.score + points;
    final beatKing = _state.beatKing || score > _state.kingScore;
    final phase = board.isFull ? GamePhase.gameOver : GamePhase.playing;

    _pending = null;
    _state = GameState(
      board: board,
      nextBalls: _state.nextBalls,
      selected: null,
      score: score,
      kingScore: _state.kingScore,
      phase: phase,
      beatKing: beatKing,
    );

    return MoveResult(
      state: _state,
      cleared: cells,
      pointsGained: points,
      aftermath: TurnAftermath.none,
    );
  }

  /// Places the next pending spawn ball. Returns null when none left to place
  /// (caller should then call [finishPendingSpawn]).
  CellPosition? spawnNext() {
    final pending = _pending;
    final colors = pending?.spawnColors;
    if (colors == null || colors.isEmpty) {
      return null;
    }

    final board = _state.board.copy();
    final placed = _spawn.placeBalls(board, [colors.removeAt(0)]);
    if (placed.isEmpty) {
      colors.clear();
      _state = _state.copyWith(board: board);
      return null;
    }

    _spawnedThisTurn.add(placed.first);
    _state = _state.copyWith(board: board);
    return placed.first;
  }

  bool get hasPendingSpawnBalls {
    final colors = _pending?.spawnColors;
    return colors != null && colors.isNotEmpty;
  }

  /// After all spawn balls are placed: refill preview, clear any new lines.
  MoveResult finishPendingSpawn() {
    final pending = _pending;
    if (pending == null || pending.spawnColors == null) {
      return MoveResult(state: _state, invalid: true);
    }

    final board = _state.board.copy();
    final next = _spawn.peekNext(SpawnService.spawnPerTurn);
    final cleared = <CellPosition>[];
    var points = 0;
    var score = _state.score;

    final lineAfterSpawn = _lines.detect(board);
    if (lineAfterSpawn.found) {
      points = _scoring.pointsForLines(lineAfterSpawn.lineLengths);
      score += points;
      for (final c in lineAfterSpawn.cells) {
        board.set(c, null);
        cleared.add(c);
      }
    }

    final beatKing = _state.beatKing || score > _state.kingScore;
    final phase = board.isFull ? GamePhase.gameOver : GamePhase.playing;
    final spawned = List<CellPosition>.from(_spawnedThisTurn);

    _pending = null;
    _spawnedThisTurn.clear();
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
      cleared: cleared,
      pointsGained: points,
      spawned: spawned,
      aftermath: TurnAftermath.none,
    );
  }

  /// Applies the full turn aftermath synchronously (tests / non-animated).
  MoveResult resolvePendingFully() {
    if (_pending == null) {
      return MoveResult(state: _state);
    }
    if (_pending!.clearCells != null) {
      return applyPendingClear();
    }
    while (hasPendingSpawnBalls) {
      if (spawnNext() == null) {
        break;
      }
    }
    return finishPendingSpawn();
  }

  /// Full move: relocate ball then resolve clear/spawn immediately.
  MoveResult tryMoveTo(CellPosition dest) {
    final begun = beginMove(dest);
    if (begun.invalid || begun.path == null) {
      return begun;
    }
    final resolved = resolvePendingFully();
    return MoveResult(
      state: _state,
      path: begun.path,
      cleared: resolved.cleared,
      pointsGained: resolved.pointsGained,
      spawned: resolved.spawned,
      aftermath: TurnAftermath.none,
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

  /// Animated tap: select or [beginMove] without resolving aftermath.
  MoveResult onCellTappedBegin(CellPosition pos) {
    if (_state.phase == GamePhase.gameOver) {
      return MoveResult(state: _state, invalid: true);
    }
    final selected = _state.selected;
    if (!_state.board.isEmpty(pos)) {
      select(pos);
      return MoveResult(state: _state);
    }
    if (selected != null) {
      return beginMove(pos);
    }
    return MoveResult(state: _state, invalid: true);
  }
}
