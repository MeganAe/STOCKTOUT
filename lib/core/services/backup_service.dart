import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database.dart';
import '../logic/backup_logic.dart';
import 'backup_archive.dart';

/// Une sauvegarde présente sur le téléphone.
class BackupInfo {
  final File file;
  final DateTime date;
  final int size;
  const BackupInfo(this.file, this.date, this.size);
}

/// Sauvegarde automatique quotidienne, manuelle, restauration.
/// Fichiers : <documents>/stocktout/backups/stocktout-backup-AAAAMMJJ-HHMMSS.zip
class BackupService {
  BackupService([AppDatabase? db]) : db = db ?? AppDatabase.instance;
  final AppDatabase db;

  static const keepCount = 7;
  static const settingAuto = 'auto_backup';

  /// Évite deux sauvegardes simultanées (démarrage + retour au 1er plan).
  static bool _busy = false;

  Future<Directory> backupsDir() async {
    final d = Directory(p.join((await db.dataDir()).path, 'backups'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<bool> autoEnabled() async =>
      (await db.getSetting(settingAuto)) != '0'; // activée par défaut

  Future<void> setAutoEnabled(bool v) =>
      db.setSetting(settingAuto, v ? '1' : '0');

  /// Sauvegardes existantes, de la plus récente à la plus ancienne.
  Future<List<BackupInfo>> list() async {
    final dir = await backupsDir();
    final out = <BackupInfo>[];
    await for (final e in dir.list()) {
      if (e is! File) continue;
      final d = parseBackupDate(p.basename(e.path));
      if (d == null) continue;
      out.add(BackupInfo(e, d, await e.length()));
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Future<BackupInfo?> latest() async {
    final l = await list();
    return l.isEmpty ? null : l.first;
  }

  /// Crée une sauvegarde zip (base + photos) puis ne garde que les 7 plus
  /// récentes. Retourne le fichier créé.
  Future<File> createBackup() async {
    final dir = await backupsDir();
    final tmp = File(p.join(dir.path, '.snapshot.tmp.db'));
    final out = File(p.join(dir.path, backupFileName(DateTime.now())));
    try {
      await db.snapshotTo(tmp.path); // VACUUM INTO : copie cohérente
      await BackupArchive.write(
        dbSnapshot: tmp,
        imagesDir: await db.imagesDir(),
        out: out,
      );
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
    await rotate();
    return out;
  }

  /// Supprime les anciennes sauvegardes (garde les [keepCount] plus récentes).
  Future<void> rotate() async {
    final dir = await backupsDir();
    final names = <String>[
      await for (final e in dir.list())
        if (e is File) p.basename(e.path),
    ];
    for (final n in backupsToDelete(names, keep: keepCount)) {
      try {
        await File(p.join(dir.path, n)).delete();
      } catch (_) {}
    }
  }

  /// Sauvegarde automatique si activée et si la dernière date de plus de 24 h.
  /// Ne lève jamais d'exception (ne doit pas gêner le démarrage).
  Future<bool> autoBackupIfDue() async {
    if (_busy) return false;
    _busy = true;
    try {
      if (!await autoEnabled()) return false;
      final last = await latest();
      if (!isBackupDue(last?.date, DateTime.now())) return false;
      await createBackup();
      return true;
    } catch (_) {
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Restaure depuis un fichier choisi : `.zip` (nouveau format) ou `.db`
  /// brut (ancien format). REMPLACE toutes les données actuelles.
  /// Une copie de sécurité « avant restauration » est créée d'abord.
  /// Lève [FormatException] si le fichier n'est pas une sauvegarde valide.
  Future<void> restoreFrom(String path) async {
    final src = File(path);
    final dir = await backupsDir();
    final work = Directory(
        p.join(dir.path, '.restore-${DateTime.now().millisecondsSinceEpoch}'));
    await work.create(recursive: true);
    try {
      File newDb;
      Directory? newImages;
      if (await BackupArchive.isZipFile(src)) {
        await BackupArchive.extract(zip: src, dest: work);
        newDb = File(p.join(work.path, BackupArchive.dbEntry));
        final imgs = Directory(p.join(work.path, 'product_images'));
        if (await imgs.exists()) newImages = imgs;
      } else if (await BackupArchive.isSqliteFile(src)) {
        newDb = src;
      } else {
        throw const FormatException('not a backup');
      }
      await _assertValidDatabase(newDb.path);

      // Filet de sécurité : copie de l'état actuel avant d'écraser.
      await _writePreRestoreCopy(dir);

      await db.close();
      final target = await db.dbFilePath();
      for (final suffix in ['-wal', '-shm', '-journal']) {
        final f = File('$target$suffix');
        if (await f.exists()) await f.delete();
      }
      await newDb.copy(target);

      final imgDir = await db.imagesDir();
      await for (final e in imgDir.list()) {
        if (e is File) await e.delete();
      }
      if (newImages != null) {
        await for (final e in newImages.list()) {
          if (e is File) await e.copy(p.join(imgDir.path, p.basename(e.path)));
        }
      }
      // Réouverture : une base v1 est migrée automatiquement vers la v2.
      await db.init();
    } finally {
      if (await work.exists()) await work.delete(recursive: true);
    }
  }

  Future<void> _assertValidDatabase(String path) async {
    Database? probe;
    try {
      probe = await databaseFactory.openDatabase(path,
          options: OpenDatabaseOptions(readOnly: true));
      final r = await probe.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='products'");
      if (r.isEmpty) throw const FormatException('not a StockTout database');
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('unreadable database');
    } finally {
      await probe?.close();
    }
  }

  Future<void> _writePreRestoreCopy(Directory dir) async {
    try {
      final tmp = File(p.join(dir.path, '.pre.tmp.db'));
      await db.snapshotTo(tmp.path);
      final out = File(p.join(dir.path, 'stocktout-avant-restauration.zip'));
      await BackupArchive.write(
          dbSnapshot: tmp, imagesDir: await db.imagesDir(), out: out);
      await tmp.delete();
    } catch (_) {
      // Pas bloquant : la restauration reste possible.
    }
  }
}
