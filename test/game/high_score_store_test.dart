import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/persistence/high_score_store.dart';

void main() {
  late Directory tempDir;
  late File scoreFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lines_scores_');
    scoreFile = File('${tempDir.path}/scores.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('default king score is 100', () async {
    final store = HighScoreStore(file: scoreFile);
    expect(await store.loadKingScore(), 100);
  });

  test('saves only when higher', () async {
    final store = HighScoreStore(file: scoreFile);
    await store.saveIfHigher(50);
    expect(await store.loadKingScore(), 100);
    await store.saveIfHigher(150);
    expect(await store.loadKingScore(), 150);
    await store.saveIfHigher(120);
    expect(await store.loadKingScore(), 150);
  });
}
