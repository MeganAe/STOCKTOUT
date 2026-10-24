import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Lecture / écriture des fichiers de sauvegarde `.zip` :
///   stocktout.db            (copie cohérente de la base)
///   product_images/<id>.jpg (photos des produits)
/// Aucune dépendance Flutter : testable seule.
class BackupArchive {
  static const dbEntry = 'stocktout.db';
  static const imagesPrefix = 'product_images/';

  /// En-tête d'un fichier SQLite 3.
  static const _sqliteMagic = 'SQLite format 3';

  /// Crée [out] à partir d'une copie de base déjà cohérente ([dbSnapshot])
  /// et du dossier de photos (facultatif).
  static Future<void> write({
    required File dbSnapshot,
    Directory? imagesDir,
    required File out,
  }) async {
    final archive = Archive();
    final dbBytes = await dbSnapshot.readAsBytes();
    archive.addFile(ArchiveFile(dbEntry, dbBytes.length, dbBytes));
    if (imagesDir != null && await imagesDir.exists()) {
      await for (final e in imagesDir.list()) {
        if (e is! File) continue;
        final bytes = await e.readAsBytes();
        archive.addFile(ArchiveFile(
            '$imagesPrefix${p.basename(e.path)}', bytes.length, bytes));
      }
    }
    final data = ZipEncoder().encode(archive);
    if (data == null) throw const FormatException('zip');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(data, flush: true);
  }

  /// Vrai si le fichier commence par l'en-tête SQLite (ancien format
  /// `.db` brut de la version précédente).
  static Future<bool> isSqliteFile(File f) async {
    if (!await f.exists()) return false;
    final raf = await f.open();
    try {
      final head = await raf.read(_sqliteMagic.length);
      return String.fromCharCodes(head) == _sqliteMagic;
    } finally {
      await raf.close();
    }
  }

  /// Vrai si le fichier est une archive zip (signature « PK »).
  static Future<bool> isZipFile(File f) async {
    if (!await f.exists()) return false;
    final raf = await f.open();
    try {
      final head = await raf.read(2);
      return head.length == 2 && head[0] == 0x50 && head[1] == 0x4B;
    } finally {
      await raf.close();
    }
  }

  /// Extrait [zip] dans [dest] : `dest/stocktout.db` et `dest/product_images/`.
  /// Refuse les chemins dangereux (`..`, absolus) et les archives sans base.
  /// Lève [FormatException] si l'archive n'est pas une sauvegarde valide.
  static Future<void> extract(
      {required File zip, required Directory dest}) async {
    final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    var hasDb = false;
    await dest.create(recursive: true);
    for (final f in archive) {
      if (!f.isFile) continue;
      final name = f.name.replaceAll('\\', '/');
      final isDb = name == dbEntry;
      final isImg = name.startsWith(imagesPrefix) &&
          !name.substring(imagesPrefix.length).contains('/');
      if (!isDb && !isImg) continue; // ignore tout le reste
      if (name.contains('..') || name.startsWith('/')) {
        throw const FormatException('unsafe path');
      }
      final target = File(p.join(dest.path, name));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(f.content as List<int>, flush: true);
      if (isDb) hasDb = true;
    }
    if (!hasDb) throw const FormatException('no database in archive');
  }
}
