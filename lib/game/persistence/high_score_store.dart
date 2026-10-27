import 'dart:convert';
import 'dart:io';

/// Local high-score persistence via a JSON file (no Flutter plugins).
class HighScoreStore {
  HighScoreStore({File? file}) : _file = file;

  static const defaultKingScore = 100;

  File? _file;

  Future<File> _ensureFile() async {
    if (_file != null) {
      return _file!;
    }
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    _file = File('$home/.color_lines_highscore.json');
    return _file!;
  }

  Future<Map<String, dynamic>> _read() async {
    final file = await _ensureFile();
    if (!await file.exists()) {
      return <String, dynamic>{};
    }
    try {
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _write(Map<String, dynamic> data) async {
    final file = await _ensureFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  Future<int> loadKingScore() async {
    final data = await _read();
    final value = data['king_high_score'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return defaultKingScore;
  }

  Future<void> saveIfHigher(int score) async {
    final data = await _read();
    final current = await loadKingScore();
    if (score > current) {
      data['king_high_score'] = score;
      await _write(data);
    }
  }

  Future<String> loadPlayerName() async {
    final data = await _read();
    final value = data['player_name'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'PRETENDER';
  }

  Future<void> savePlayerName(String name) async {
    final data = await _read();
    data['player_name'] = name;
    await _write(data);
  }
}
