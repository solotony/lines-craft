import 'package:shared_preferences/shared_preferences.dart';

/// Local high-score persistence (King / Handicap record).
class HighScoreStore {
  HighScoreStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const defaultKingScore = 100;
  static const _key = 'king_high_score';
  static const _nameKey = 'player_name';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<int> loadKingScore() async {
    final prefs = await _ensure();
    return prefs.getInt(_key) ?? defaultKingScore;
  }

  Future<void> saveIfHigher(int score) async {
    final prefs = await _ensure();
    final current = prefs.getInt(_key) ?? defaultKingScore;
    if (score > current) {
      await prefs.setInt(_key, score);
    }
  }

  Future<String> loadPlayerName() async {
    final prefs = await _ensure();
    return prefs.getString(_nameKey) ?? 'PRETENDER';
  }

  Future<void> savePlayerName(String name) async {
    final prefs = await _ensure();
    await prefs.setString(_nameKey, name);
  }
}
