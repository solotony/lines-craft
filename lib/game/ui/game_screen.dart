import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../rendering/virtual_resolution.dart';
import 'game_frame.dart';

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
