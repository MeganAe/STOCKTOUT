import 'dart:io';

import 'package:flutter/material.dart';

/// Miniature d'un produit : photo si elle existe, sinon icône.
/// Chargement paresseux et `cacheWidth` pour limiter la mémoire.
class ProductThumb extends StatelessWidget {
  final String? path;
  final double size;
  final IconData fallback;

  const ProductThumb({
    super.key,
    required this.path,
    this.size = 44,
    this.fallback = Icons.inventory_2_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = path;
    Widget child;
    if (p == null || p.isEmpty) {
      child = Icon(fallback, size: size * 0.55, color: scheme.onSurfaceVariant);
    } else {
      child = Image.file(
        File(p),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            Icon(fallback, size: size * 0.55, color: scheme.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
