import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sauvegarde / restauration du fichier SQLite.
class BackupService {
  Future<String> get dbPath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'stockpro', 'stockpro.db');
  }

  Future<String> backup(String destDir) async {
    final src = File(await dbPath);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final dest = File(p.join(destDir, 'stockpro-$stamp.db'));
    await dest.writeAsBytes(await src.readAsBytes());
    return dest.path;
  }

  Future<void> restore(String backupFile) async {
    final src = File(backupFile);
    final dest = File(await dbPath);
    await dest.writeAsBytes(await src.readAsBytes());
  }
}
