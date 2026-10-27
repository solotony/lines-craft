/// Provisional scoring from Lines 98 (see docs/counting.md).
/// Not verified as exact Gamos 1992 formula.
class ScoringService {
  const ScoringService();

  static const Map<int, int> provisionalTable = <int, int>{
    5: 10,
    6: 12,
    7: 18,
    8: 28,
    9: 42,
  };

  int pointsForLine(int length) {
    if (length < 5) {
      return 0;
    }
    if (provisionalTable.containsKey(length)) {
      return provisionalTable[length]!;
    }
    // Extrapolate gently for lines longer than 9 (rare on 9×9).
    final base = provisionalTable[9]!;
    return base + (length - 9) * 16;
  }

  int pointsForLines(List<int> lengths) {
    var total = 0;
    for (final len in lengths) {
      total += pointsForLine(len);
    }
    return total;
  }
}
