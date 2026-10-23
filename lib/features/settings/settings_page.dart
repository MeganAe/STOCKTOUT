import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/extra_strings.dart';
import '../../core/models/currency.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/backup_service.dart';
import '../../widgets/feature_tour.dart';
import '../onboarding/onboarding_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final kLang = GlobalKey();
  final kMoney = GlobalKey();
  final kBackup = GlobalKey();

  /// Nom de chaque langue, ecrit dans sa propre langue.
  static const _langs = [
    ['en', 'English'],
    ['fr', 'Français'],
    ['es', 'Español'],
    ['de', 'Deutsch'],
    ['it', 'Italiano'],
    ['pt', 'Português'],
    ['nl', 'Nederlands'],
    ['ru', 'Русский'],
    ['zh', '中文'],
    ['ja', '日本語'],
    ['ko', '한국어'],
    ['ar', 'العربية'],
    ['hi', 'हिन्दी'],
    ['tr', 'Türkçe'],
    ['pl', 'Polski'],
    ['sv', 'Svenska'],
    ['da', 'Dansk'],
    ['no', 'Norsk'],
    ['fi', 'Suomi'],
    ['el', 'Ελληνικά'],
    ['cs', 'Čeština'],
    ['ro', 'Română'],
    ['hu', 'Magyar'],
    ['id', 'Bahasa Indonesia'],
    ['sw', 'Kiswahili'],
    ['ln', 'Lingála'],
    ['uk', 'Українська'],
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final currenciesAsync = ref.watch(currenciesProvider);
    final text = Theme.of(context).textTheme;

    return GuidedTour(
      id: 'settings',
      steps: [
        TourStep(target: kLang, title: t.language, body: t.gsSettingsB),
        TourStep(target: kMoney, title: t.currency, body: t.gsTotalsB),
        TourStep(target: kBackup, title: t.backup, body: t.gsSettingsB),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(t.settings)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ---- Langue ----
            KeyedSubtree(
              key: kLang,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.language, style: text.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: settings.locale.languageCode,
                        isExpanded: true,
                        items: _langs
                            .map((e) => DropdownMenuItem(
                                value: e[0], child: Text(e[1])))
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
            ),
            const SizedBox(height: 12),
            // ---- Theme ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.theme, style: text.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(t.light),
                            icon: const Icon(Icons.light_mode)),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(t.dark),
                            icon: const Icon(Icons.dark_mode)),
                        ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(t.auto),
                            icon: const Icon(Icons.settings_suggest)),
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
            // ---- Devises ----
            KeyedSubtree(
              key: kMoney,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(t.currency, style: text.titleMedium),
                          ),
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.add),
                            label: Text(t.addCurrency),
                            onPressed: () => _addCurrency(context),
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
                              contentPadding: EdgeInsets.zero,
                              leading: isBase
                                  ? const Icon(Icons.star, color: Colors.amber)
                                  : const Icon(Icons.monetization_on_outlined),
                              title: Text('${c.code} — ${c.name}'),
                              subtitle: Text(
                                  '${c.symbol} · ${t.rate}: ${c.rateToBase}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isBase)
                                    TextButton(
                                      onPressed: () =>
                                          _changeDefault(context, list, c),
                                      child: Text(t.defaultCurrency),
                                    ),
                                  IconButton(
                                    tooltip: t.edit,
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () => _editRate(context, c),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(t.currencyHelp, style: text.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ---- Sauvegarde ----
            KeyedSubtree(
              key: kBackup,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.backup, style: text.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.save_alt),
                            label: Text(t.backupBtn),
                            onPressed: () => _backup(context),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restore),
                            label: Text(t.restoreBtn),
                            onPressed: () => _restore(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ---- Aide ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.tutorial, style: text.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.school_outlined),
                          label: Text(t.replayTutorial),
                          onPressed: () {
                            TourSession.resetAll();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OnboardingPage(
                                  onDone: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: TourSession.enabled,
                      onChanged: (v) async {
                        setState(() => TourSession.enabled = v);
                        if (v) TourSession.resetAll();
                        final p = await SharedPreferences.getInstance();
                        await p.setBool('tips_enabled', v);
                      },
                      title: Text(t.showTips),
                      subtitle: Text(t.guideTitle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCurrency(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final code = TextEditingController();
    final symbol = TextEditingController();
    final name = TextEditingController();
    final rate = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.newCurrency),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: t.codeHint)),
              const SizedBox(height: 12),
              TextField(
                  controller: symbol,
                  decoration: InputDecoration(labelText: t.symbolHint)),
              const SizedBox(height: 12),
              TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: t.contactName)),
              const SizedBox(height: 12),
              TextField(
                  controller: rate,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: t.rate, helperText: t.rateHint)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
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

  Future<void> _editRate(BuildContext context, AppCurrency c) async {
    final t = AppLocalizations.of(context);
    final rate = TextEditingController(text: '${c.rateToBase}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.code} — ${t.rate}'),
        content: TextField(
            controller: rate,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: t.rate, helperText: t.rateHint)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.upsertCurrency(c.copyWith(
          rateToBase: double.tryParse(rate.text.replaceAll(',', '.')) ?? 1));
      ref.invalidate(currenciesProvider);
    }
  }

  /// Changement de devise par defaut : propose de convertir les prix
  /// enregistres selon les taux, au lieu de ne changer que le libelle.
  Future<void> _changeDefault(
    BuildContext context,
    List<AppCurrency> all,
    AppCurrency to,
  ) async {
    final t = AppLocalizations.of(context);
    final current = ref.read(settingsProvider).currency;
    AppCurrency? from;
    for (final c in all) {
      if (c.code == current) from = c;
    }
    final factor = (from == null || from.rateToBase == 0)
        ? 1.0
        : to.rateToBase / from.rateToBase;
    final canConvert = (factor - 1).abs() > 1e-9;
    String fmt(double v) => v >= 1
        ? v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)
        : v.toStringAsFixed(6);

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.currencyChangeTitle),
        content: Text(canConvert
            ? t.currencyChangeBody
            : '${t.currencyChangeBody}\n\n${t.setRateFirst}'),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          if (canConvert)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'convert'),
              child: Text('${t.convertPrices} (×${fmt(factor)})'),
            ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: Text(t.keepPrices),
          ),
          if (!canConvert)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'rate'),
              child: Text('${t.edit} — ${t.rate}'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'rate') {
      await _editRate(context, to);
      return;
    }
    if (choice == 'convert') {
      await AppDatabase.instance.convertProductPrices(factor, to.decimals);
      ref.invalidate(productsProvider);
    }
    await ref.read(settingsProvider.notifier).setCurrency(to.code);
    if (choice == 'convert' && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.pricesConverted)));
    }
  }

  Future<void> _backup(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final dir =
        await FilePicker.platform.getDirectoryPath(dialogTitle: t.backupDir);
    if (dir != null) {
      final path = await BackupService().backup(dir);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.backupSaved(path))));
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final res = await FilePicker.platform.pickFiles(type: FileType.any);
    if (res?.files.single.path != null) {
      await BackupService().restore(res!.files.single.path!);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t.restoreDone)));
      }
    }
  }
}
