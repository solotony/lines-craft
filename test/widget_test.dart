import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/rendering/virtual_resolution.dart';
import 'package:lines/game/ui/game_screen.dart';
import 'package:lines/main.dart';

void main() {
  testWidgets('LinesApp builds GameScreen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const LinesApp());
    expect(find.byType(GameScreen), findsOneWidget);
  });

  test('integer scale prefers fitting integer factor', () {
    expect(GameScreen.integerScale(640, 480), 1);
    expect(GameScreen.integerScale(1280, 960), 2);
    expect(GameScreen.integerScale(1920, 1080), 2);
    expect(GameScreen.integerScale(100, 100), 1);
  });

  test('virtual resolution is 640x480', () {
    expect(VirtualResolution.width, 640);
    expect(VirtualResolution.height, 480);
  });
}
