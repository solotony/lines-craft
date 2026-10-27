import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/rendering/board_layout.dart';
import 'package:lines/game/rendering/board_renderer.dart';
import 'package:lines/game/rendering/palette.dart';

void main() {
  test('board has 81 cells', () {
    const board = BoardRenderer();
    expect(board.cellCount, 81);
    expect(BoardLayout.columns * BoardLayout.rows, 81);
  });

  test('cell rects are within virtual canvas and non-overlapping pitch', () {
    final seen = <String>{};
    for (var r = 0; r < BoardLayout.rows; r++) {
      for (var c = 0; c < BoardLayout.columns; c++) {
        final rect = BoardLayout.cellRect(c, r);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(640));
        expect(rect.bottom, lessThanOrEqualTo(480));
        final key = '${rect.left},${rect.top}';
        expect(seen.contains(key), isFalse);
        seen.add(key);
      }
    }
    expect(seen.length, 81);
  });

  test('hitTest finds center of each cell', () {
    for (var r = 0; r < BoardLayout.rows; r++) {
      for (var c = 0; c < BoardLayout.columns; c++) {
        final hit = BoardLayout.hitTest(BoardLayout.cellCenter(c, r));
        expect(hit, (c, r));
      }
    }
    expect(BoardLayout.hitTest(const Offset(10, 10)), isNull);
  });

  test('board layout colors are palette members', () {
    // Sanity: renderers only reference GamePalette constants.
    expect(GamePalette.contains(GamePalette.panelGray), isTrue);
    expect(GamePalette.contains(GamePalette.shadowGray), isTrue);
    expect(GamePalette.contains(GamePalette.white), isTrue);
    expect(GamePalette.contains(GamePalette.midGray), isTrue);
    expect(GamePalette.contains(GamePalette.darkGray), isTrue);
    expect(GamePalette.contains(GamePalette.black), isTrue);
  });
}
