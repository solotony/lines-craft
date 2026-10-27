import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/game_controller.dart';
import '../model/ball_color.dart';
import '../model/cell_position.dart';
import '../model/game_state.dart';
import '../rendering/ball_renderer.dart';
import '../rendering/board_layout.dart';
import '../rendering/board_renderer.dart';
import '../rendering/palette.dart';
import '../rendering/pixel_text_renderer.dart';
import '../rendering/sprite_renderer.dart';
import 'input_handler.dart';

/// Playable 640×480 game composition wired to [GameController].
class GameFrame extends StatefulWidget {
  const GameFrame({super.key, this.controller});

  final GameController? controller;

  @override
  State<GameFrame> createState() => GameFrameState();
}

class GameFrameState extends State<GameFrame> with TickerProviderStateMixin {
  late final GameController _controller;
  final InputHandler _input = const InputHandler();

  ui.Image? _king;
  ui.Image? _pretender;
  ui.Image? _kingLose;
  ui.Image? _pretenderWins;
  final Map<String, ui.Image> _footprints = {};

  late final AnimationController _bounce;
  late final AnimationController _move;

  List<CellPosition>? _movePath;
  BallColor? _movingColor;
  List<CellPosition> _footprintTrail = [];
  int _moveCellIndex = 0;
  bool _soundOn = true;
  bool _showHelp = false;
  bool _busy = false;

  GameController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameController();
    if (widget.controller == null) {
      _controller.startNewGame();
    }

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);

    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..addStatusListener(_onMoveStatus);

    _loadAssets();
  }

  void _onMoveStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _movePath == null) {
      return;
    }
    if (_moveCellIndex < _movePath!.length - 1) {
      setState(() {
        _moveCellIndex++;
        if (_moveCellIndex > 0) {
          _footprintTrail = _movePath!.sublist(0, _moveCellIndex);
        }
      });
      _move
        ..reset()
        ..forward();
    } else {
      setState(() {
        _movePath = null;
        _movingColor = null;
        _footprintTrail = [];
        _busy = false;
      });
    }
  }

  Future<void> _loadAssets() async {
    final king = await _decode(SpriteRenderer.kingAsset);
    final pretender = await _decode(SpriteRenderer.pretenderAsset);
    final kingLose = await _decode(SpriteRenderer.kingLoseAsset);
    final pretenderWins = await _decode(SpriteRenderer.pretenderWinsAsset);
    final dirs = ['up', 'down', 'left', 'right'];
    final prints = <String, ui.Image>{};
    for (final d in dirs) {
      prints['1-$d'] =
          await _decode('assets/images/footprints/footprint1-$d.png');
      prints['2-$d'] =
          await _decode('assets/images/footprints/footprint2-$d.png');
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _king = king;
      _pretender = pretender;
      _kingLose = kingLose;
      _pretenderWins = pretenderWins;
      _footprints
        ..clear()
        ..addAll(prints);
    });
  }

  Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  void dispose() {
    _bounce.dispose();
    _move.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_input.isRestart(key)) {
      _restart();
      return KeyEventResult.handled;
    }
    if (_input.isToggleSound(key)) {
      setState(() => _soundOn = !_soundOn);
      return KeyEventResult.handled;
    }
    if (_input.isHelp(key)) {
      setState(() => _showHelp = !_showHelp);
      return KeyEventResult.handled;
    }
    if (_input.isNext(key)) {
      setState(() {
        _controller.load(
          _controller.state.copyWith(clearSelected: true),
        );
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _restart() {
    setState(() {
      _busy = false;
      _movePath = null;
      _movingColor = null;
      _footprintTrail = [];
      _showHelp = false;
      _controller.startNewGame();
    });
  }

  void _onTap(Offset local) {
    if (_busy || _showHelp) {
      if (_showHelp) {
        setState(() => _showHelp = false);
      }
      return;
    }
    final cell = _input.cellFromLocalOffset(local);
    if (cell == null) {
      return;
    }

    final before = _controller.state.selected;
    final result = _controller.onCellTapped(cell);

    if (result.path != null && result.path!.length > 1) {
      // Animate along path; board state already updated — paint moving ghost
      // from path while hiding destination ball until done.
      setState(() {
        _busy = true;
        _movePath = result.path;
        _movingColor = _controller.state.board[result.path!.last];
        // Temporarily hide the arrived ball during animation by tracking path.
        _moveCellIndex = 0;
        _footprintTrail = [];
      });
      // Put ball back visually at start for animation: restore temporarily
      // by storing path; painter draws moving ball and skips final cell until done.
      _move
        ..reset()
        ..forward();
    } else {
      setState(() {});
      if (before != _controller.state.selected &&
          _controller.state.selected != null) {
        _bounce
          ..reset()
          ..repeat(reverse: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _onTap(d.localPosition),
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounce, _move]),
          builder: (context, _) {
            return CustomPaint(
              painter: _PlayPainter(
                state: _controller.state,
                bounceT: _bounce.value,
                moveT: _move.value,
                movePath: _movePath,
                moveIndex: _moveCellIndex,
                movingColor: _movingColor,
                footprints: _footprintTrail,
                footprintImages: _footprints,
                king: _controller.state.beatKing ? _kingLose : _king,
                pretender:
                    _controller.state.beatKing ? _pretenderWins : _pretender,
                soundOn: _soundOn,
                showHelp: _showHelp,
                animating: _busy,
              ),
              size: const Size(640, 480),
            );
          },
        ),
      ),
    );
  }
}

class _PlayPainter extends CustomPainter {
  _PlayPainter({
    required this.state,
    required this.bounceT,
    required this.moveT,
    required this.movePath,
    required this.moveIndex,
    required this.movingColor,
    required this.footprints,
    required this.footprintImages,
    required this.king,
    required this.pretender,
    required this.soundOn,
    required this.showHelp,
    required this.animating,
  });

  final GameState state;
  final double bounceT;
  final double moveT;
  final List<CellPosition>? movePath;
  final int moveIndex;
  final BallColor? movingColor;
  final List<CellPosition> footprints;
  final Map<String, ui.Image> footprintImages;
  final ui.Image? king;
  final ui.Image? pretender;
  final bool soundOn;
  final bool showHelp;
  final bool animating;

  static const _board = BoardRenderer();
  static const _balls = BallRenderer();
  static const _text = PixelTextRenderer();
  static const _sprites = SpriteRenderer();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..color = GamePalette.black
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, bg);

    final panel = Paint()
      ..color = GamePalette.panelGray
      ..isAntiAlias = false;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 640, 42), panel);
    canvas.drawRect(const Rect.fromLTWH(0, 423, 640, 57), panel);

    _sprites.paintPedestal(
      canvas,
      topCenter: SpriteRenderer.kingPedestalTop,
      height: 90,
    );
    _sprites.paintPedestal(
      canvas,
      topCenter: SpriteRenderer.pretenderPedestalTop,
      height: 60,
      width: 32,
    );

    if (king != null) {
      _sprites.paintSprite(
        canvas,
        king!,
        SpriteRenderer.kingPedestalTop,
        maxHeight: 90,
      );
    }
    if (pretender != null) {
      _sprites.paintSprite(
        canvas,
        pretender!,
        SpriteRenderer.pretenderPedestalTop,
        maxHeight: 78,
      );
    }

    _text.paint(
      canvas,
      'HANDICAP',
      const Offset(70, 380),
      color: GamePalette.labelYellow,
      scale: 1,
      align: PixelTextAlign.center,
    );
    _text.paint(
      canvas,
      'PRETENDER',
      const Offset(570, 380),
      color: GamePalette.labelYellow,
      scale: 1,
      align: PixelTextAlign.center,
    );

    final selected = state.selected == null
        ? null
        : (state.selected!.col, state.selected!.row);
    _board.paint(canvas, selected: selected);

    _paintFootprints(canvas);

    final hideCell = animating && movePath != null ? movePath!.last : null;

    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final pos = CellPosition(col, row);
        final color = state.board[pos];
        if (color == null) {
          continue;
        }
        if (hideCell == pos) {
          continue;
        }
        final center = BoardLayout.cellCenter(col, row);
        final isSelected =
            state.selected == pos && !animating;
        if (isSelected) {
          _paintBouncingBall(canvas, center, color, bounceT);
        } else {
          _balls.paint(canvas, center, color: color, diameter: 24);
        }
      }
    }

    if (animating && movePath != null && movingColor != null) {
      final from = movePath![moveIndex];
      final to = moveIndex + 1 < movePath!.length
          ? movePath![moveIndex + 1]
          : from;
      final a = BoardLayout.cellCenter(from.col, from.row);
      final b = BoardLayout.cellCenter(to.col, to.row);
      final t = moveT;
      final hop = -6 * 4 * t * (1 - t); // parabolic hop
      final pos = Offset(
        ui.lerpDouble(a.dx, b.dx, t)!,
        ui.lerpDouble(a.dy, b.dy, t)! + hop,
      );
      _paintBouncingBall(canvas, pos, movingColor!, t);
    }

    _text.paint(
      canvas,
      'NEXT',
      const Offset(280, 8),
      color: GamePalette.black,
      scale: 1,
    );
    for (var i = 0; i < state.nextBalls.length && i < 3; i++) {
      final cx = 320.0 + i * 28;
      canvas.drawRect(
        Rect.fromLTWH(cx - 12, 18, 24, 20),
        Paint()
          ..color = GamePalette.shadowGray
          ..isAntiAlias = false,
      );
      _balls.paint(
        canvas,
        Offset(cx, 28),
        color: state.nextBalls[i],
        diameter: 14,
      );
    }

    _text.paint(
      canvas,
      '${state.kingScore}',
      const Offset(24, 12),
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );
    _text.paint(
      canvas,
      '${state.score}',
      const Offset(560, 12),
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );

    final soundLabel = soundOn ? 'F2 SOUND' : 'F2 MUTE';
    _text.paint(
      canvas,
      'F1 HELP  $soundLabel  F3 NEXT  F4 RESTART',
      const Offset(64, 440),
      color: GamePalette.white,
      scale: 1,
    );

    if (state.phase == GamePhase.gameOver) {
      canvas.drawRect(
        const Rect.fromLTWH(180, 200, 280, 60),
        Paint()
          ..color = GamePalette.black
          ..isAntiAlias = false,
      );
      _text.paint(
        canvas,
        'GAME OVER',
        const Offset(320, 212),
        color: GamePalette.ballRed,
        scale: 2,
        align: PixelTextAlign.center,
      );
      _text.paint(
        canvas,
        'F4 RESTART',
        const Offset(320, 240),
        color: GamePalette.white,
        scale: 1,
        align: PixelTextAlign.center,
      );
    }

    if (showHelp) {
      canvas.drawRect(
        const Rect.fromLTWH(100, 120, 440, 200),
        Paint()
          ..color = GamePalette.black
          ..isAntiAlias = false,
      );
      const lines = [
        'MAKE LINES OF 5+',
        'SAME COLOR BALLS',
        'CLICK BALL THEN CELL',
        'F4 NEW GAME',
      ];
      for (var i = 0; i < lines.length; i++) {
        _text.paint(
          canvas,
          lines[i],
          Offset(320, 140.0 + i * 36),
          color: GamePalette.white,
          scale: 2,
          align: PixelTextAlign.center,
        );
      }
    }
  }

  void _paintBouncingBall(
    Canvas canvas,
    Offset center,
    BallColor color,
    double t,
  ) {
    // Squash at contact (t~0/1), stretch mid-air (t~0.5).
    final stretch = 1.0 + 0.18 * math.sin(t * math.pi);
    final squash = 1.0 - 0.14 * math.sin(t * math.pi);
    final lift = -4.0 * math.sin(t * math.pi);
    canvas.save();
    canvas.translate(center.dx, center.dy + lift);
    canvas.scale(squash, stretch);
    _balls.paint(canvas, Offset.zero, color: color, diameter: 24);
    canvas.restore();
  }

  void _paintFootprints(Canvas canvas) {
    for (var i = 0; i < footprints.length; i++) {
      final cell = footprints[i];
      CellPosition? next;
      if (i + 1 < footprints.length) {
        next = footprints[i + 1];
      } else if (movePath != null && moveIndex < movePath!.length) {
        next = movePath![moveIndex];
      }
      final dir = _dirName(cell, next);
      final key = '${(i % 2) + 1}-$dir';
      final image = footprintImages[key];
      if (image == null) {
        continue;
      }
      final center = BoardLayout.cellCenter(cell.col, cell.row);
      final fade = ((i + 1) / (footprints.length + 1)).clamp(0.25, 1.0);
      final dest = Rect.fromCenter(
        center: center,
        width: 22,
        height: 22,
      );
      paintImage(
        canvas: canvas,
        rect: dest,
        image: image,
        filterQuality: FilterQuality.none,
        isAntiAlias: false,
        opacity: fade,
      );
    }
  }

  String _dirName(CellPosition from, CellPosition? to) {
    if (to == null) {
      return 'down';
    }
    final dc = to.col - from.col;
    final dr = to.row - from.row;
    if (dc.abs() >= dr.abs()) {
      return dc >= 0 ? 'right' : 'left';
    }
    return dr >= 0 ? 'down' : 'up';
  }

  @override
  bool shouldRepaint(covariant _PlayPainter oldDelegate) => true;
}
