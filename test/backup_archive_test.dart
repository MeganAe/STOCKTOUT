import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:stocktout/core/services/backup_archive.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('stocktout_bk_');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('aller-retour : base + photos restaurées à l\'identique', () async {
    final db = File(p.join(tmp.path, 'snap.db'));
    // Faux fichier SQLite (en-tête réel + contenu).
    final content = [...'SQLite format 3\u0000'.codeUnits, 1, 2, 3, 250, 251];
    await db.writeAsBytes(content);
    final imgs = Directory(p.join(tmp.path, 'imgs'))..createSync();
    File(p.join(imgs.path, 'a.jpg')).writeAsBytesSync([9, 8, 7]);
    File(p.join(imgs.path, 'b.jpg')).writeAsBytesSync([1, 1]);

    final zip = File(p.join(tmp.path, 'out', 'b.zip'));
    await BackupArchive.write(dbSnapshot: db, imagesDir: imgs, out: zip);
    expect(await zip.exists(), isTrue);
    expect(await BackupArchive.isZipFile(zip), isTrue);
    expect(await BackupArchive.isSqliteFile(zip), isFalse);
    expect(await BackupArchive.isSqliteFile(db), isTrue);

    final dest = Directory(p.join(tmp.path, 'restore'));
    await BackupArchive.extract(zip: zip, dest: dest);
    expect(File(p.join(dest.path, 'stocktout.db')).readAsBytesSync(), content);
    expect(File(p.join(dest.path, 'product_images', 'a.jpg')).readAsBytesSync(),
        [9, 8, 7]);
    expect(File(p.join(dest.path, 'product_images', 'b.jpg')).readAsBytesSync(),
        [1, 1]);
  });

  test('sans dossier photos', () async {
    final db = File(p.join(tmp.path, 'snap.db'))..writeAsBytesSync([1, 2, 3]);
    final zip = File(p.join(tmp.path, 'b.zip'));
    await BackupArchive.write(dbSnapshot: db, out: zip);
    final dest = Directory(p.join(tmp.path, 'r'));
    await BackupArchive.extract(zip: zip, dest: dest);
    expect(File(p.join(dest.path, 'stocktout.db')).existsSync(), isTrue);
    expect(
        Directory(p.join(dest.path, 'product_images')).existsSync(), isFalse);
  });

  test('une archive sans base est refusée', () async {
    final db = File(p.join(tmp.path, 'x.txt'))..writeAsBytesSync([1]);
    final zip = File(p.join(tmp.path, 'bad.zip'));
    // Archive valide mais sans stocktout.db : on la fabrique à la main.
    await BackupArchive.write(dbSnapshot: db, out: zip);
    final bytes = zip.readAsBytesSync();
    // Corrompt le nom de l'entrée « stocktout.db » -> « stocktout.dX ».
    final s = String.fromCharCodes(bytes);
    final fixed = s.replaceAll('stocktout.db', 'stocktout.dX');
    File(zip.path).writeAsBytesSync(fixed.codeUnits);
    var failed = false;
    try {
      await BackupArchive.extract(
          zip: zip, dest: Directory(p.join(tmp.path, 'r2')));
    } on FormatException {
      failed = true;
    }
    expect(failed, isTrue);
  });
}
