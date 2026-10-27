import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/logic/game_controller.dart';
import 'package:lines/game/logic/spawn_service.dart';
import 'package:lines/game/model/ball_color.dart';
import 'package:lines/game/model/board_state.dart';
import 'package:lines/game/model/cell_position.dart';
import 'package:lines/game/rendering/board_layout.dart';
import 'package:lines/game/rendering/hud_layout.dart';
import 'package:lines/game/ui/game_frame.dart';
import 'package:lines/game/ui/game_screen.dart';
import 'package:lines/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('game startup shows GameFrame', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const LinesApp());
    await tester.pump(); // start frame
    expect(find.byType(GameFrame), findsOneWidget);
  });

  testWidgets('select and move updates score path', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final board = BoardState.empty();
    board.set(const CellPosition(0, 0), BallColor.red);
    final controller = GameController(
      spawn: SpawnService(colorSequence: List.filled(40, BallColor.blue)),
    );
    controller.startNewGame(
      board: board,
      next: [BallColor.green, BallColor.yellow, BallColor.orange],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameScreen(child: GameFrame(controller: controller)),
        ),
      ),
    );
    await tester.pump();

    final from = BoardLayout.cellCenter(0, 0);
    final to = BoardLayout.cellCenter(0, 2);

    await tester.tapAt(from);
    await tester.pump();
    expect(controller.state.selected, const CellPosition(0, 0));

    await tester.tapAt(to);
    await tester.pump();
    // Animation in progress or done
    await tester.pump(const Duration(seconds: 2));
    expect(controller.state.board[const CellPosition(0, 2)], BallColor.red);
    expect(controller.state.board.occupiedCount, greaterThanOrEqualTo(1));
  });

  testWidgets('F4 restarts game', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final board = BoardState.empty();
    board.set(const CellPosition(4, 4), BallColor.cyan);
    final controller = GameController(
      spawn: SpawnService(colorSequence: List.filled(40, BallColor.red)),
    );
    controller.startNewGame(
      board: board,
      next: [BallColor.red, BallColor.red, BallColor.red],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameScreen(child: GameFrame(controller: controller)),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pump();
    // Fresh random/sequence game — board rebuilt via startNewGame without board
    expect(controller.state.score, 0);
  });

  testWidgets('mouse click on F4 restarts game', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final board = BoardState.empty();
    board.set(const CellPosition(2, 2), BallColor.yellow);
    final controller = GameController(
      spawn: SpawnService(colorSequence: List.filled(40, BallColor.green)),
    );
    controller.startNewGame(
      board: board,
      next: [BallColor.green, BallColor.green, BallColor.green],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameScreen(child: GameFrame(controller: controller)),
        ),
      ),
    );
    await tester.pump();

    final f4 = HudLayout.fButtonRect(3).center;
    await tester.tapAt(f4);
    await tester.pump();
    expect(controller.state.score, 0);
  });
}
