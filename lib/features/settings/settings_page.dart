import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/currency.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/demo_seeder.dart';
import '../onboarding/onboarding_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _langs = [
    ['en', 'English'],
    ['fr', 'Francais'],
    ['es', 'Espanol'],
    ['de', 'Deutsch'],
    ['it', 'Italiano'],
    ['pt', 'Portugues'],
    ['nl', 'Nederlands'],
    ['ru', 'Russkiy'],
    ['zh', 'Zhongwen'],
    ['ja', 'Nihongo'],
    ['ko', 'Hangugeo'],
    ['ar', 'Arabiya'],
    ['hi', 'Hindi'],
    ['tr', 'Turkce'],
    ['pl', 'Polski'],
    ['sv', 'Svenska'],
    ['da', 'Dansk'],
    ['no', 'Norsk'],
    ['fi', 'Suomi'],
    ['el', 'Ellinika'],
    ['cs', 'Cestina'],
    ['ro', 'Romana'],
    ['hu', 'Magyar'],
    ['id', 'Indonesia'],
    ['sw', 'Kiswahili'],
    ['ln', 'Lingala'],
    ['uk', 'Ukrayinska'],
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final currenciesAsync = ref.watch(currenciesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Langue
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.language,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: settings.locale.languageCode,
                    items: _langs
                        .map((e) =>
                            DropdownMenuItem(value: e[0], child: Text(e[1])))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(settingsProvider.notifier)
                            .setLocale(Locale(v));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Theme
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.theme, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Clair'),
                          icon: Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Sombre'),
                          icon: Icon(Icons.dark_mode)),
                      ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('Auto'),
                          icon: Icon(Icons.settings_suggest)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) =>
                        ref.read(settingsProvider.notifier).setTheme(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Devises
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.currency,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add),
                        label: const Text('Devise'),
                        onPressed: () => _addCurrency(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  currenciesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (list) => Column(
                      children: list.map((c) {
                        final isBase = c.code == settings.currency;
                        return ListTile(
                          dense: true,
                          leading: isBase
                              ? const Icon(Icons.star, color: Colors.amber)
                              : const Icon(Icons.monetization_on_outlined),
                          title: Text('${c.code} — ${c.name}'),
                          subtitle: Text(
                              'Symbole: ${c.symbol} · Taux: ${c.rateToBase}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isBase)
                                TextButton(
                                  onPressed: () => ref
                                      .read(settingsProvider.notifier)
                                      .setCurrency(c.code),
                                  child: const Text('Defaut'),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => _editRate(context, ref, c),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Le taux exprime la valeur par rapport a la devise de base. Ex : si la base est USD et 1 USD = 2850 CDF, mettez 2850 sur CDF.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Sauvegarde
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sauvegarde',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Sauvegarder'),
                        onPressed: () => _backup(context),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restore),
                        label: const Text('Restaurer'),
                        onPressed: () => _restore(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Aide
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.tutorial,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.school_outlined),
                        label: Text(t.replayTutorial),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OnboardingPage(
                              onDone: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.science_outlined),
                        label: Text(t.obDemo),
                        onPressed: () async {
                          final n = await DemoSeeder.seedIfEmpty();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(n > 0 ? t.obDemoDone : t.obDemoExists),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addCurrency(BuildContext context, WidgetRef ref) async {
    final code = TextEditingController();
    final symbol = TextEditingController();
    final name = TextEditingController();
    final rate = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: code,
                decoration: const InputDecoration(
                    labelText: 'Code (ex: CDF, NGN, KES)')),
            TextField(
                controller: symbol,
                decoration:
                    const InputDecoration(labelText: 'Symbole (ex: FC)')),
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom')),
            TextField(
                controller: rate,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Taux')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true && code.text.trim().isNotEmpty) {
      await AppDatabase.instance.upsertCurrency(AppCurrency(
        code: code.text.trim().toUpperCase(),
        symbol: symbol.text.trim(),
        name: name.text.trim(),
        rateToBase: double.tryParse(rate.text.replaceAll(',', '.')) ?? 1,
      ));
      ref.invalidate(currenciesProvider);
    }
  }

  Future<void> _editRate(
      BuildContext context, WidgetRef ref, AppCurrency c) async {
    final rate = TextEditingController(text: '${c.rateToBase}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Taux — ${c.code}'),
        content: TextField(
            controller: rate,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Taux')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.upsertCurrency(c.copyWith(
          rateToBase: double.tryParse(rate.text.replaceAll(',', '.')) ?? 1));
      ref.invalidate(currenciesProvider);
    }
  }

  Future<void> _backup(BuildContext context) async {
    final dir = await FilePicker.platform
        .getDirectoryPath(dialogTitle: 'Dossier de sauvegarde');
    if (dir != null) {
      final path = await BackupService().backup(dir);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sauvegarde : $path')));
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res?.files.single.path != null) {
      await BackupService().restore(res!.files.single.path!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Base restauree. Redemarrez l\'application.')),
        );
      }
    }
  }
}
