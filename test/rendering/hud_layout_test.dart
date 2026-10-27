import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/rendering/board_layout.dart';
import 'package:lines/game/rendering/hud_layout.dart';

void main() {
  test('score boxes share width and equal edge margins', () {
    expect(HudLayout.leftScoreBox.width, HudLayout.rightScoreBox.width);
    expect(HudLayout.leftScoreBox.left, HudLayout.scoreEdgeMargin);
    expect(
      640 - HudLayout.rightScoreBox.right,
      HudLayout.scoreEdgeMargin,
    );
    expect(HudLayout.leftScoreBox.width, greaterThanOrEqualTo(6 * 8 + 4));
  });

  test('next balls are centered on the screen mid-line', () {
    expect(HudLayout.nextPreviewCenterX, 320);
    expect(HudLayout.nextBallCenter(1).dx, 320);
    expect(HudLayout.nextBallCenter(0).dx + HudLayout.nextBallCenter(2).dx, 640);
    expect(HudLayout.nextBallCenter(0).dy, HudLayout.topHudMidY);
    expect(HudLayout.leftScoreBox.center.dy, HudLayout.topHudMidY);
  });

  test('names sit on board bottom; column base above by half name height', () {
    expect(HudLayout.nameTop, BoardLayout.boardBounds.bottom);
    expect(
      HudLayout.columnBaseBottom,
      HudLayout.nameTop - HudLayout.nameHeight / 2,
    );
  });

  test('winner column is 5 cells; trailing scales; lead swap shrinks former', () {
    final maxH = 5 * BoardLayout.cellHeight;
    expect(HudLayout.columnShaftHeight(100, 40), maxH);
    expect(HudLayout.columnShaftHeight(40, 100), closeTo(maxH * 0.4, 0.01));
    expect(HudLayout.columnShaftHeight(120, 100), maxH);
    expect(HudLayout.columnShaftHeight(100, 120), closeTo(maxH * 100 / 120, 0.01));
    expect(HudLayout.columnShaftHeight(0, 100), HudLayout.minColumnShaft);
  });

  test('F-key hit testing covers raised buttons', () {
    final f1 = HudLayout.fButtonRect(0).center;
    final f4 = HudLayout.fButtonRect(3).center;
    expect(HudLayout.hitTestFKey(f1), 0);
    expect(HudLayout.hitTestFKey(f4), 3);
    expect(HudLayout.hitTestFKey(const Offset(320, 240)), isNull);
  });
}
