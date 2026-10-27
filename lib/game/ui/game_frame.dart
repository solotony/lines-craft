import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/game_controller.dart';
import '../model/ball_color.dart';
import '../model/cell_position.dart';
import '../model/game_state.dart';
import '../persistence/high_score_store.dart';
import '../rendering/ball_renderer.dart';
import '../rendering/board_layout.dart';
import '../rendering/board_renderer.dart';
import '../rendering/hud_layout.dart';
import '../rendering/palette.dart';
import '../rendering/pixel_text_renderer.dart';
import '../rendering/sprite_renderer.dart';
import 'input_handler.dart';
import 'sound_service.dart';

/// Playable 640×480 game composition wired to [GameController].
class GameFrame extends StatefulWidget {
  const GameFrame({
    super.key,
    this.controller,
    this.sound,
    this.highScores,
  });

  final GameController? controller;
  final SoundService? sound;
  final HighScoreStore? highScores;

  @override
  State<GameFrame> createState() => GameFrameState();
}

class GameFrameState extends State<GameFrame> with TickerProviderStateMixin {
  late final GameController _controller;
  late final SoundService _sound;
  late final HighScoreStore _scores;
  late final bool _ownsSound;
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
  bool _showHelp = false;
  bool _busy = false;
  bool _playedLandThisHop = false;
  int? _pressedFKey;

  GameController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? GameController();
    _ownsSound = widget.sound == null;
    _sound = widget.sound ?? SoundService();
    _scores = widget.highScores ?? HighScoreStore();
    if (widget.controller == null) {
      _controller.startNewGame();
      _loadKingScore();
    }

    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);

    _move = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )
      ..addStatusListener(_onMoveStatus)
      ..addListener(_onMoveTick);

    _loadAssets();
  }

  Future<void> _loadKingScore() async {
    final king = await _scores.loadKingScore();
    if (!mounted) {
      return;
    }
    setState(() {
      _controller.load(
        _controller.state.copyWith(kingScore: king),
      );
    });
  }

  Future<void> _persistScoreIfNeeded() async {
    await _scores.saveIfHigher(_controller.state.score);
    final king = await _scores.loadKingScore();
    if (!mounted) {
      return;
    }
    if (king != _controller.state.kingScore) {
      setState(() {
        _controller.load(
          _controller.state.copyWith(kingScore: king),
        );
      });
    }
  }

  void _onMoveTick() {
    // Land SFX near squash (end of hop).
    if (_busy && _move.value > 0.85 && !_playedLandThisHop) {
      _playedLandThisHop = true;
      _sound.playLand();
    }
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
      _playedLandThisHop = false;
      _sound.playMove();
      _move
        ..reset()
        ..forward();
    } else {
      setState(() {
        _movePath = null;
        _movingColor = null;
        _footprintTrail = [];
      });
      _afterMoveLanded();
    }
  }

  /// Ball has landed: brief pause, then clear the line or spawn balls one-by-one.
  Future<void> _afterMoveLanded() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted || !_busy) {
      return;
    }

    final beatBefore = _controller.state.beatKing;

    if (_controller.pendingAftermath == TurnAftermath.clearLine) {
      setState(() {
        _controller.applyPendingClear();
      });
      if (!beatBefore && _controller.state.beatKing) {
        _sound.playFanfareIfNeeded(true);
      }
      if (_controller.state.phase == GamePhase.gameOver) {
        _persistScoreIfNeeded();
      }
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      return;
    }

    if (_controller.pendingAftermath == TurnAftermath.spawn) {
      while (_controller.hasPendingSpawnBalls) {
        if (!mounted || !_busy) {
          return;
        }
        setState(() {
          _controller.spawnNext();
        });
        await Future<void>.delayed(const Duration(milliseconds: 140));
      }
      if (!mounted || !_busy) {
        return;
      }
      // Let the last spawned ball sit briefly before spawn-line clear / preview refill.
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted || !_busy) {
        return;
      }
      setState(() {
        _controller.finishPendingSpawn();
      });
      if (!beatBefore && _controller.state.beatKing) {
        _sound.playFanfareIfNeeded(true);
      }
      if (_controller.state.phase == GamePhase.gameOver) {
        _persistScoreIfNeeded();
      }
    }

    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
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
    if (_ownsSound) {
      _sound.dispose();
    }
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
      setState(() => _sound.enabled = !_sound.enabled);
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
    _persistScoreIfNeeded();
    setState(() {
      _busy = false;
      _movePath = null;
      _movingColor = null;
      _footprintTrail = [];
      _showHelp = false;
      _sound.resetFanfareFlag();
      _controller.startNewGame();
      _sound.playTitle();
    });
    _loadKingScore();
  }

  void _activateFKey(int index) {
    switch (index) {
      case 0:
        setState(() => _showHelp = !_showHelp);
      case 1:
        setState(() => _sound.enabled = !_sound.enabled);
      case 2:
        setState(() {
          _controller.load(
            _controller.state.copyWith(clearSelected: true),
          );
        });
      case 3:
        _restart();
    }
  }

  void _onPointerDown(Offset local) {
    final fKey = HudLayout.hitTestFKey(local);
    if (fKey != null) {
      setState(() => _pressedFKey = fKey);
      return;
    }
  }

  void _onPointerUp(Offset local) {
    final pressed = _pressedFKey;
    if (pressed != null) {
      final hit = HudLayout.hitTestFKey(local);
      setState(() => _pressedFKey = null);
      if (hit == pressed) {
        _activateFKey(pressed);
      }
      return;
    }

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
    final result = _controller.onCellTappedBegin(cell);

    if (result.path != null && result.path!.length > 1) {
      setState(() {
        _busy = true;
        _movePath = result.path;
        _movingColor = _controller.state.board[result.path!.last];
        _moveCellIndex = 0;
        _footprintTrail = [];
        _playedLandThisHop = false;
      });
      _sound.playMove();
      _move
        ..reset()
        ..forward();
    } else {
      setState(() {});
      if (before != _controller.state.selected &&
          _controller.state.selected != null) {
        _sound.playSelect();
        _bounce
          ..reset()
          ..repeat(reverse: true);
      }
    }
  }

  void _onPointerCancel() {
    if (_pressedFKey != null) {
      setState(() => _pressedFKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _onPointerDown(e.localPosition),
        onPointerUp: (e) => _onPointerUp(e.localPosition),
        onPointerCancel: (_) => _onPointerCancel(),
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
                soundOn: _sound.enabled,
                showHelp: _showHelp,
                animating: _busy,
                pressedFKey: _pressedFKey,
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
    required this.pressedFKey,
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
  final int? pressedFKey;

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
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 640, HudLayout.topBarHeight),
      panel,
    );
    canvas.drawRect(
      const Rect.fromLTWH(
        0,
        HudLayout.bottomBarTop,
        640,
        HudLayout.bottomBarHeight,
      ),
      panel,
    );

    _paintCharacters(canvas);
    _paintBoardAndBalls(canvas);
    _paintTopHud(canvas);
    _paintBottomHud(canvas);

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

  void _paintCharacters(Canvas canvas) {
    final kingShaft = HudLayout.columnShaftHeight(
      state.kingScore,
      state.score,
    );
    final pretenderShaft = HudLayout.columnShaftHeight(
      state.score,
      state.kingScore,
    );
    final kingTop = HudLayout.pedestalTop(
      HudLayout.kingCenterX,
      kingShaft,
    );
    final pretenderTop = HudLayout.pedestalTop(
      HudLayout.pretenderCenterX,
      pretenderShaft,
    );

    _sprites.paintPedestal(
      canvas,
      topCenter: kingTop,
      height: kingShaft,
      width: HudLayout.pedestalWidth,
      baseHeight: HudLayout.pedestalBaseHeight,
      capHeight: HudLayout.pedestalCapHeight,
    );
    _sprites.paintPedestal(
      canvas,
      topCenter: pretenderTop,
      height: pretenderShaft,
      width: 32,
      baseHeight: HudLayout.pedestalBaseHeight,
      capHeight: HudLayout.pedestalCapHeight,
    );

    if (king != null) {
      _sprites.paintSprite(
        canvas,
        king!,
        kingTop,
        maxHeight: 90,
      );
    }
    if (pretender != null) {
      _sprites.paintSprite(
        canvas,
        pretender!,
        pretenderTop,
        maxHeight: 78,
      );
    }

    _text.paint(
      canvas,
      'HANDICAP',
      Offset(HudLayout.kingCenterX, HudLayout.nameTop),
      color: GamePalette.labelYellow,
      scale: HudLayout.nameScale,
      align: PixelTextAlign.center,
    );
    _text.paint(
      canvas,
      'PRETENDER',
      Offset(HudLayout.pretenderCenterX, HudLayout.nameTop),
      color: GamePalette.labelYellow,
      scale: HudLayout.nameScale,
      align: PixelTextAlign.center,
    );
  }

  void _paintBoardAndBalls(Canvas canvas) {
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
        final isSelected = state.selected == pos && !animating;
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
      final hop = -6 * 4 * t * (1 - t);
      final pos = Offset(
        ui.lerpDouble(a.dx, b.dx, t)!,
        ui.lerpDouble(a.dy, b.dy, t)! + hop,
      );
      _paintBouncingBall(canvas, pos, movingColor!, t);
    }
  }

  void _paintTopHud(Canvas canvas) {
    _paintInsetBox(canvas, HudLayout.leftScoreBox);
    _paintInsetBox(canvas, HudLayout.rightScoreBox);

    final scoreY = HudLayout.topHudMidY -
        _text.measureHeight(scale: HudLayout.scoreScale) / 2;
    _text.paint(
      canvas,
      _scoreText(state.kingScore),
      Offset(HudLayout.leftScoreBox.center.dx, scoreY),
      color: GamePalette.ballGreen,
      scale: HudLayout.scoreScale,
      align: PixelTextAlign.center,
    );
    _text.paint(
      canvas,
      _scoreText(state.score),
      Offset(HudLayout.rightScoreBox.center.dx, scoreY),
      color: GamePalette.ballGreen,
      scale: HudLayout.scoreScale,
      align: PixelTextAlign.center,
    );

    _text.paint(
      canvas,
      'NEXT',
      HudLayout.nextLabelOrigin,
      color: GamePalette.black,
      scale: HudLayout.scoreScale,
    );
    _text.paint(
      canvas,
      'COLORS',
      HudLayout.colorsLabelOrigin,
      color: GamePalette.black,
      scale: HudLayout.scoreScale,
    );

    for (var i = 0; i < 3; i++) {
      final cell = HudLayout.nextBallCell(i);
      _paintInsetBox(canvas, cell);
      if (i < state.nextBalls.length) {
        _balls.paint(
          canvas,
          HudLayout.nextBallCenter(i),
          color: state.nextBalls[i],
          diameter: HudLayout.nextBallDiameter,
        );
      }
    }
  }

  void _paintBottomHud(Canvas canvas) {
    const keys = ['F1', 'F2', 'F3', 'F4'];
    final labels = [
      'HELP',
      soundOn ? 'SOUND' : 'MUTE',
      'NEXT',
      'RESTART',
    ];
    for (var i = 0; i < 4; i++) {
      final button = HudLayout.fButtonRect(i);
      _paintRaisedButton(
        canvas,
        button,
        pressed: pressedFKey == i,
      );
      final keyY = button.center.dy -
          _text.measureHeight(scale: HudLayout.scoreScale) / 2;
      _text.paint(
        canvas,
        keys[i],
        Offset(button.center.dx, keyY),
        color: GamePalette.black,
        scale: HudLayout.scoreScale,
        align: PixelTextAlign.center,
      );

      final labelBox = HudLayout.fLabelRect(i, labels[i]);
      _paintInsetBox(canvas, labelBox);
      final labelY = labelBox.center.dy -
          _text.measureHeight(scale: HudLayout.scoreScale) / 2;
      _text.paint(
        canvas,
        labels[i],
        Offset(labelBox.center.dx, labelY),
        color: GamePalette.ballGreen,
        scale: HudLayout.scoreScale,
        align: PixelTextAlign.center,
      );
    }
  }

  String _scoreText(int value) {
    final raw = '$value';
    if (raw.length >= HudLayout.scoreDigits) {
      return raw;
    }
    return raw; // left-pad visually via fixed box; digits stay natural width
  }

  void _paintInsetBox(Canvas canvas, Rect rect) {
    final outer = Paint()
      ..color = GamePalette.shadowGray
      ..isAntiAlias = false;
    final light = Paint()
      ..color = GamePalette.white
      ..isAntiAlias = false;
    final dark = Paint()
      ..color = GamePalette.darkGray
      ..isAntiAlias = false;
    final face = Paint()
      ..color = GamePalette.black
      ..isAntiAlias = false;

    canvas.drawRect(rect, outer);
    // Inset bevel: dark top/left, light bottom/right (recessed).
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2),
      light,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 2, rect.top, 2, rect.height),
      light,
    );
    canvas.drawRect(rect.deflate(2), face);
  }

  void _paintRaisedButton(Canvas canvas, Rect rect, {required bool pressed}) {
    final face = Paint()
      ..color = GamePalette.panelGray
      ..isAntiAlias = false;
    final light = Paint()
      ..color = pressed ? GamePalette.shadowGray : GamePalette.white
      ..isAntiAlias = false;
    final dark = Paint()
      ..color = pressed ? GamePalette.white : GamePalette.shadowGray
      ..isAntiAlias = false;

    canvas.drawRect(rect, face);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, 2),
      light,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, 2, rect.height),
      light,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 2, rect.width, 2),
      dark,
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 2, rect.top, 2, rect.height),
      dark,
    );
    if (pressed) {
      canvas.drawRect(
        rect.deflate(2),
        Paint()
          ..color = GamePalette.midGray
          ..isAntiAlias = false,
      );
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
