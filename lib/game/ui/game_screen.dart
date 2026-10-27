import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/ball_color.dart';
import '../rendering/ball_renderer.dart';
import '../rendering/board_layout.dart';
import '../rendering/board_renderer.dart';
import '../rendering/palette.dart';
import '../rendering/pixel_text_renderer.dart';
import '../rendering/sprite_renderer.dart';
import '../rendering/virtual_resolution.dart';

/// Hosts the 640×480 virtual game surface, letterboxed and integer-scaled
/// with nearest-neighbor filtering.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, this.child});

  /// Content painted in virtual 640×480 coordinates.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = integerScale(constraints.maxWidth, constraints.maxHeight);
          final viewW = VirtualResolution.width * scale;
          final viewH = VirtualResolution.height * scale;

          return Center(
            child: SizedBox(
              width: viewW.toDouble(),
              height: viewH.toDouble(),
              child: ClipRect(
                child: Transform.scale(
                  scale: scale.toDouble(),
                  alignment: Alignment.topLeft,
                  filterQuality: FilterQuality.none,
                  child: SizedBox(
                    width: VirtualResolution.width.toDouble(),
                    height: VirtualResolution.height.toDouble(),
                    child: child ?? const GameFrame(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Largest integer scale that fits; minimum 1.
  static int integerScale(double maxW, double maxH) {
    final byW = maxW / VirtualResolution.width;
    final byH = maxH / VirtualResolution.height;
    final fitted = math.min(byW, byH);
    final scale = fitted.floor();
    return scale < 1 ? 1 : scale;
  }
}

/// Full virtual frame with board, balls, and characters.
class GameFrame extends StatefulWidget {
  const GameFrame({super.key});

  @override
  State<GameFrame> createState() => _GameFrameState();
}

class _GameFrameState extends State<GameFrame> {
  (int, int)? _selected = (4, 4);
  ui.Image? _king;
  ui.Image? _pretender;

  /// Demo balls for visual verification (Stage 5).
  final Map<(int, int), BallColor> _balls = {
    (0, 0): BallColor.red,
    (2, 1): BallColor.green,
    (4, 4): BallColor.cyan,
    (6, 3): BallColor.yellow,
    (8, 8): BallColor.magenta,
    (3, 7): BallColor.blue,
    (7, 2): BallColor.orange,
  };

  final List<BallColor> _next = [
    BallColor.red,
    BallColor.blue,
    BallColor.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _loadSprites();
  }

  Future<void> _loadSprites() async {
    final king = await _decode(SpriteRenderer.kingAsset);
    final pretender = await _decode(SpriteRenderer.pretenderAsset);
    if (!mounted) {
      return;
    }
    setState(() {
      _king = king;
      _pretender = pretender;
    });
  }

  Future<ui.Image> _decode(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final hit = BoardLayout.hitTest(details.localPosition);
        setState(() => _selected = hit);
      },
      child: CustomPaint(
        painter: GameFramePainter(
          selected: _selected,
          balls: _balls,
          next: _next,
          king: _king,
          pretender: _pretender,
        ),
        size: const Size(640, 480),
      ),
    );
  }
}

class GameFramePainter extends CustomPainter {
  GameFramePainter({
    this.selected,
    required this.balls,
    required this.next,
    this.king,
    this.pretender,
    this.kingScore = 100,
    this.playerScore = 0,
  });

  final (int, int)? selected;
  final Map<(int, int), BallColor> balls;
  final List<BallColor> next;
  final ui.Image? king;
  final ui.Image? pretender;
  final int kingScore;
  final int playerScore;

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

    _board.paint(canvas, selected: selected);

    for (final entry in balls.entries) {
      final (col, row) = entry.key;
      _balls.paint(
        canvas,
        BoardLayout.cellCenter(col, row),
        color: entry.value,
        diameter: 24,
      );
    }

    // Next preview
    _text.paint(
      canvas,
      'NEXT',
      const Offset(280, 8),
      color: GamePalette.black,
      scale: 1,
    );
    for (var i = 0; i < next.length && i < 3; i++) {
      final cx = 320.0 + i * 28;
      final cell = Rect.fromLTWH(cx - 12, 18, 24, 20);
      canvas.drawRect(
        cell,
        Paint()
          ..color = GamePalette.shadowGray
          ..isAntiAlias = false,
      );
      _balls.paint(
        canvas,
        Offset(cx, 28),
        color: next[i],
        diameter: 14,
      );
    }

    _text.paint(
      canvas,
      '$kingScore',
      const Offset(24, 12),
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );
    _text.paint(
      canvas,
      '$playerScore',
      const Offset(560, 12),
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );
    _text.paint(
      canvas,
      'F1 HELP  F2 SOUND  F3 NEXT  F4 RESTART',
      const Offset(80, 440),
      color: GamePalette.white,
      scale: 1,
    );
  }

  @override
  bool shouldRepaint(covariant GameFramePainter oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.king != king ||
      oldDelegate.pretender != pretender ||
      oldDelegate.playerScore != playerScore ||
      oldDelegate.kingScore != kingScore;
}
