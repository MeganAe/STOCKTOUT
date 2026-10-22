import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/l10n/app_localizations.dart';

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
    final t = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/logo.png',
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 14),
            Text('StockTout',
                style:
                    text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (_version.isNotEmpty)
              Text('${t.version} $_version', style: text.bodySmall),
            const SizedBox(height: 14),
            Text(
              t.aboutBody,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // ---- Auteur (uniquement ici) ----
            Text(t.author, style: text.bodySmall),
            const Text('github.com/MeganAe/STOCKOUT',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.close),
            ),
          ],
        ),
      ),
    );
  }
}
