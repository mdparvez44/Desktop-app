/// Natural alphanumeric comparator for machine codes and strings.
/// Orders A1, A2, ..., A9, A10, A11, B1, B2 naturally instead of A1, A10, A11, A2.
library;

int compareNatural(String a, String b) {
  final regExp = RegExp(r'^([A-Za-z]+)(\d+)$');
  final matchA = regExp.firstMatch(a.trim());
  final matchB = regExp.firstMatch(b.trim());

  if (matchA != null && matchB != null) {
    final prefixA = matchA.group(1)!;
    final prefixB = matchB.group(1)!;
    final prefixComp = prefixA.compareTo(prefixB);
    if (prefixComp != 0) return prefixComp;

    final numA = int.parse(matchA.group(2)!);
    final numB = int.parse(matchB.group(2)!);
    return numA.compareTo(numB);
  }

  // Fallback chunked natural comparison
  final chunkRegExp = RegExp(r'(\d+|\D+)');
  final matchesA = chunkRegExp.allMatches(a).map((m) => m.group(0)!).toList();
  final matchesB = chunkRegExp.allMatches(b).map((m) => m.group(0)!).toList();

  final minLen = matchesA.length < matchesB.length ? matchesA.length : matchesB.length;
  for (var i = 0; i < minLen; i++) {
    final partA = matchesA[i];
    final partB = matchesB[i];

    final intA = int.tryParse(partA);
    final intB = int.tryParse(partB);

    if (intA != null && intB != null) {
      final comp = intA.compareTo(intB);
      if (comp != 0) return comp;
    } else {
      final comp = partA.compareTo(partB);
      if (comp != 0) return comp;
    }
  }

  return matchesA.length.compareTo(matchesB.length);
}

extension NaturalSortList on List<String> {
  void sortNaturally() {
    sort(compareNatural);
  }
}
