import 'package:flutter_test/flutter_test.dart';
import 'package:lines/game/persistence/high_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('default king score is 100', () async {
    final store = HighScoreStore();
    expect(await store.loadKingScore(), 100);
  });

  test('saves only when higher', () async {
    final store = HighScoreStore();
    await store.saveIfHigher(50);
    expect(await store.loadKingScore(), 100);
    await store.saveIfHigher(150);
    expect(await store.loadKingScore(), 150);
    await store.saveIfHigher(120);
    expect(await store.loadKingScore(), 150);
  });
}
