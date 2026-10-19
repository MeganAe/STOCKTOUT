import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Seule page mentionnant l'auteur.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 12),
            Text('StockTout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            if (_version.isNotEmpty)
              Text('Version $_version',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            const Text(
              'Logiciel de gestion de stock pour commerces, boutiques, depots et PME. '
              'Fonctionne hors-ligne, vos donnees restent sur votre machine.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // ---- Auteur (uniquement ici) ----
            const Text('Auteur : Metoushela Walker'),
            const Text('GitHub : MeganAe/STOCKOUT'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }
}
