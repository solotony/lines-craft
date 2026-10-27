import 'ball_color.dart';
import 'board_state.dart';
import 'cell_position.dart';

enum GamePhase { playing, gameOver }

/// Snapshot of an in-progress Color Lines session.
class GameState {
  GameState({
    required this.board,
    required this.nextBalls,
    this.selected,
    this.score = 0,
    this.kingScore = 100,
    this.phase = GamePhase.playing,
    this.beatKing = false,
  });

  factory GameState.initial({
    required BoardState board,
    required List<BallColor> nextBalls,
    int kingScore = 100,
  }) {
    assert(nextBalls.length == 3);
    return GameState(
      board: board,
      nextBalls: List<BallColor>.from(nextBalls),
      kingScore: kingScore,
    );
  }

  final BoardState board;
  final List<BallColor> nextBalls;
  final CellPosition? selected;
  final int score;
  final int kingScore;
  final GamePhase phase;
  final bool beatKing;

  GameState copyWith({
    BoardState? board,
    List<BallColor>? nextBalls,
    CellPosition? selected,
    bool clearSelected = false,
    int? score,
    int? kingScore,
    GamePhase? phase,
    bool? beatKing,
  }) {
    return GameState(
      board: board ?? this.board.copy(),
      nextBalls: nextBalls ?? List<BallColor>.from(this.nextBalls),
      selected: clearSelected ? null : (selected ?? this.selected),
      score: score ?? this.score,
      kingScore: kingScore ?? this.kingScore,
      phase: phase ?? this.phase,
      beatKing: beatKing ?? this.beatKing,
    );
  }
}
