/// Compara dos versiones `MAJOR.MINOR.PATCH` (ignora sufijos de build tipo
/// `+16` y cualquier segmento no numérico). Devuelve `<0` si [a] < [b], `0`
/// si son iguales y `>0` si [a] > [b].
int compareSemanticVersions(String a, String b) {
  final partsA = _parseParts(a);
  final partsB = _parseParts(b);
  for (var i = 0; i < 3; i++) {
    final diff = partsA[i].compareTo(partsB[i]);
    if (diff != 0) {
      return diff;
    }
  }
  return 0;
}

List<int> _parseParts(String version) {
  final withoutBuild = version.split('+').first;
  final segments = withoutBuild.split('.');
  return List.generate(3, (i) {
    if (i >= segments.length) {
      return 0;
    }
    return int.tryParse(segments[i].trim()) ?? 0;
  });
}
