import 'dart:ui' show Offset;

import 'package:flutter/services.dart';

import '../model/cell_position.dart';
import '../rendering/board_layout.dart';

/// Maps pointer/keyboard events into game intents.
class InputHandler {
  const InputHandler();

  CellPosition? cellFromLocalOffset(Offset offset) {
    final hit = BoardLayout.hitTest(offset);
    if (hit == null) {
      return null;
    }
    return CellPosition(hit.$1, hit.$2);
  }

  bool isRestart(LogicalKeyboardKey key) => key == LogicalKeyboardKey.f4;

  bool isToggleSound(LogicalKeyboardKey key) => key == LogicalKeyboardKey.f2;

  bool isHelp(LogicalKeyboardKey key) => key == LogicalKeyboardKey.f1;

  /// F3 historically advances / confirms; we treat it as deselect.
  bool isNext(LogicalKeyboardKey key) => key == LogicalKeyboardKey.f3;
}
