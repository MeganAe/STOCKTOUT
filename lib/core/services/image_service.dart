import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';

/// Photos des produits : compression (800 px max, qualité 80) et copie dans
/// <documents>/stocktout/product_images/<id>.jpg
///
/// Le choix d'une photo écrit d'abord un fichier TEMPORAIRE
/// (`<id>.pending.jpg`) ; il n'est promu en `<id>.jpg` qu'à l'enregistrement
/// du produit. Annuler le formulaire ne modifie donc jamais la photo.
class ImageService {
  static const maxSide = 800.0;
  static const quality = 80;

  /// Chemin final de la photo d'un produit.
  static String pathFor(String imagesDir, String productId) =>
      p.join(imagesDir, '$productId.jpg');

  static String pendingPathFor(String imagesDir, String productId) =>
      p.join(imagesDir, '$productId.pending.jpg');

  /// Ouvre la caméra ou la galerie ; la plateforme redimensionne et
  /// compresse (800 px max, qualité 80). Retourne le chemin du fichier
  /// temporaire, ou null si l'utilisateur annule. Lève une exception si la
  /// permission est refusée (gérée par l'écran).
  static Future<String?> pickPending(
      ImageSource source, String productId) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
    );
    if (picked == null) return null;
    final dir = await AppDatabase.instance.imagesDir();
    final dest = pendingPathFor(dir.path, productId);
    await File(picked.path).copy(dest);
    return dest;
  }

  /// Promeut la photo temporaire en `<id>.jpg` (remplace l'ancienne) et
  /// retourne le chemin final.
  static Future<String> commit(String pendingPath, String productId) async {
    final dir = await AppDatabase.instance.imagesDir();
    final dest = pathFor(dir.path, productId);
    final f = File(pendingPath);
    if (await File(dest).exists()) await File(dest).delete();
    await f.rename(dest);
    // Le cache d'images de Flutter est indexé par chemin : on le vide pour
    // afficher la nouvelle photo.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    return dest;
  }

  /// Supprime un fichier image (ignore les erreurs / l'absence).
  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
