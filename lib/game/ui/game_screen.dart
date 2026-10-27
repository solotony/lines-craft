import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../rendering/palette.dart';
import '../rendering/pixel_text_renderer.dart';
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
                    child: child ?? const _SkeletonFrame(),
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

/// Placeholder composition used until board/UI renderers exist.
class _SkeletonFrame extends StatelessWidget {
  const _SkeletonFrame();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _SkeletonPainter(),
      size: Size(640, 480),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const _SkeletonPainter();

  static const _text = PixelTextRenderer();

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

    final board = Paint()
      ..color = GamePalette.shadowGray
      ..isAntiAlias = false;
    canvas.drawRect(const Rect.fromLTWH(171, 83, 306, 297), board);

    _text.paint(
      canvas,
      'COLOR LINES',
      const Offset(320, 12),
      color: GamePalette.black,
      scale: 2,
      align: PixelTextAlign.center,
    );
    _text.paint(
      canvas,
      '100',
      const Offset(24, 12),
      color: GamePalette.ballGreen,
      background: GamePalette.black,
      scale: 2,
    );
    _text.paint(
      canvas,
      '0',
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
