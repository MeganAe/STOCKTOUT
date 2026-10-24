/// Nom d'une sauvegarde automatique/manuelle :
/// `stocktout-backup-20261023-143005.zip`.
String backupFileName(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'stocktout-backup-${d.year.toString().padLeft(4, '0')}${two(d.month)}${two(d.day)}'
      '-${two(d.hour)}${two(d.minute)}${two(d.second)}.zip';
}

final RegExp _backupRe = RegExp(
    r'^stocktout-backup-(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.zip$');

/// Date contenue dans le nom d'une sauvegarde (null si ce n'en est pas une).
DateTime? parseBackupDate(String fileName) {
  final m = _backupRe.firstMatch(fileName);
  if (m == null) return null;
  int g(int i) => int.parse(m.group(i)!);
  return DateTime(g(1), g(2), g(3), g(4), g(5), g(6));
}

/// Fichiers à supprimer pour ne garder que les [keep] plus récentes
/// sauvegardes. Les fichiers qui ne suivent pas le format sont ignorés
/// (jamais supprimés).
List<String> backupsToDelete(Iterable<String> fileNames, {int keep = 7}) {
  final dated = <MapEntry<String, DateTime>>[];
  for (final n in fileNames) {
    final d = parseBackupDate(n);
    if (d != null) dated.add(MapEntry(n, d));
  }
  dated.sort((a, b) => b.value.compareTo(a.value));
  if (dated.length <= keep) return const [];
  return dated.skip(keep).map((e) => e.key).toList();
}

/// Une sauvegarde est due si la dernière date de plus de 24 h (ou n'existe pas).
bool isBackupDue(DateTime? last, DateTime now,
    {Duration every = const Duration(hours: 24)}) {
  if (last == null) return true;
  return now.difference(last) > every;
}
