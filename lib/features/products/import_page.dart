import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/import_logic.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/lock_gate.dart';

/// Import de produits depuis un CSV ou un Excel (.xlsx) :
/// fichier -> association des colonnes -> aperçu -> import par lots.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  String? _fileName;
  List<String> _headers = [];
  List<List<String>> _rows = [];
  Map<ImportField, int?> _mapping = {};
  DuplicateMode _mode = DuplicateMode.update;
  ImportPlan? _plan;
  bool _importing = false;
  double _progress = 0;
  String? _error;
  bool _done = false;

  Future<void> _pick() async {
    final t = AppLocalizations.of(context);
    try {
      final res = await LockGuard.external(() => FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['csv', 'xlsx'],
            withData: false,
          ));
      final path = res?.files.single.path;
      if (path == null) return;
      final table = await _readTable(path);
      if (table.isEmpty) {
        setState(() => _error = t.importEmptyFile);
        return;
      }
      setState(() {
        _fileName = p.basename(path);
        _headers = table.first.map((e) => e.trim()).toList();
        _rows = table.skip(1).toList();
        _mapping = autoMapColumns(_headers);
        _plan = null;
        _error = null;
        _done = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = t.importReadError);
    }
  }

  /// Texte d'une cellule Excel. Un nombre à exactement 3 décimales
  /// (« 1234.567 ») serait lu comme un séparateur de milliers : on ajoute
  /// un zéro (« 1234.5670 », même valeur) pour lever l'ambiguïté.
  static String _cellText(CellValue? v) {
    if (v == null) return '';
    final s = v.toString();
    if (v is DoubleCellValue && RegExp(r'^-?\d+\.\d{3}$').hasMatch(s)) {
      return '${s}0';
    }
    return s;
  }

  /// Lit le fichier en tableau de chaînes (première ligne = en-têtes).
  Future<List<List<String>>> _readTable(String path) async {
    final bytes = await File(path).readAsBytes();
    if (path.toLowerCase().endsWith('.xlsx')) {
      final book = Excel.decodeBytes(bytes);
      if (book.tables.isEmpty) return [];
      final sheet = book.tables.values.first;
      final out = <List<String>>[];
      for (final row in sheet.rows) {
        final cells = [
          for (final c in row) _cellText(c?.value),
        ];
        if (cells.every((c) => c.trim().isEmpty)) continue;
        out.add(cells);
      }
      return out;
    }
    // CSV : UTF-8 (avec ou sans BOM), sinon repli Latin-1 (vieux Excel).
    String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      text = latin1.decode(bytes);
    }
    return parseCsv(text);
  }

  Future<void> _preview() async {
    final existing = await AppDatabase.instance.allProducts();
    final plan = planImport(
      rows: _rows,
      mapping: _mapping,
      existing: existing,
      mode: _mode,
    );
    if (mounted) setState(() => _plan = plan);
  }

  Future<void> _run() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() {
      _importing = true;
      _progress = 0;
    });
    try {
      await AppDatabase.instance.applyImport(plan, onProgress: (d, total) {
        if (mounted) setState(() => _progress = total == 0 ? 1 : d / total);
      });
      ref.invalidate(productsProvider);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _shareTemplate() async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'stocktout_modele_import.csv'));
    await file.writeAsString(csvTemplate());
    await LockGuard.external(() => Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: 'stocktout_modele_import.csv'));
  }

  String _errorText(AppLocalizations t, ImportRowError e) {
    final base = switch (e.code) {
      ImportErrorCode.missingName => t.importErrMissingName,
      ImportErrorCode.badNumber => t.importErrBadNumber,
      ImportErrorCode.negativeNumber => t.importErrNegative,
      ImportErrorCode.duplicateInFile => t.importErrDuplicate,
    };
    final f = e.field == null ? '' : ' (${_fieldLabel(t, e.field!)})';
    return '${t.importLine(e.line)} : $base$f';
  }

  String _fieldLabel(AppLocalizations t, ImportField f) => switch (f) {
        ImportField.name => t.productName,
        ImportField.sku => t.sku,
        ImportField.barcode => t.barcode,
        ImportField.category => t.category,
        ImportField.unit => t.unitHint,
        ImportField.buyPrice => t.buyPrice,
        ImportField.sellPrice => t.sellPrice,
        ImportField.quantity => t.quantity,
        ImportField.minStock => t.minStock,
      };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plan = _plan;
    return Scaffold(
      appBar: AppBar(title: Text(t.importProducts)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.importStep1,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(t.importHelp),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: Text(t.chooseFile),
                        onPressed: _importing ? null : _pick,
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.download_outlined),
                        label: Text(t.downloadTemplate),
                        onPressed: _shareTemplate,
                      ),
                    ],
                  ),
                  if (_fileName != null) ...[
                    const SizedBox(height: 8),
                    Text('$_fileName · ${t.rowsCount(_rows.length)}'),
                  ],
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_headers.isNotEmpty && !_done) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.importStep2,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final f in ImportField.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: DropdownButtonFormField<int?>(
                          value: _mapping[f],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText:
                                '${_fieldLabel(t, f)}${f == ImportField.name ? ' *' : ''}',
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                                value: null, child: Text(t.notImported)),
                            for (var i = 0; i < _headers.length; i++)
                              DropdownMenuItem<int?>(
                                value: i,
                                child: Text(
                                    _headers[i].isEmpty
                                        ? '(${i + 1})'
                                        : _headers[i],
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) => setState(() {
                            _mapping = {..._mapping, f: v};
                            _plan = null;
                          }),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(t.ifExists,
                        style: Theme.of(context).textTheme.titleSmall),
                    RadioListTile<DuplicateMode>(
                      contentPadding: EdgeInsets.zero,
                      value: DuplicateMode.update,
                      groupValue: _mode,
                      title: Text(t.dupUpdate),
                      onChanged: (v) => setState(() {
                        _mode = v!;
                        _plan = null;
                      }),
                    ),
                    RadioListTile<DuplicateMode>(
                      contentPadding: EdgeInsets.zero,
                      value: DuplicateMode.skip,
                      groupValue: _mode,
                      title: Text(t.dupSkip),
                      onChanged: (v) => setState(() {
                        _mode = v!;
                        _plan = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(t.preview),
                      onPressed:
                          (_mapping[ImportField.name] == null || _importing)
                              ? null
                              : _preview,
                    ),
                    if (_mapping[ImportField.name] == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(t.importNeedName,
                            style: const TextStyle(color: Colors.orange)),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (plan != null && !_done) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.importStep3,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(t.importSummary(
                        plan.toCreate.length,
                        plan.toUpdate.length,
                        plan.skipped,
                        plan.errors.length)),
                    if (plan.errors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final e in plan.errors.take(30))
                        Text('• ${_errorText(t, e)}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13)),
                      if (plan.errors.length > 30)
                        Text(t.andMore(plan.errors.length - 30)),
                    ],
                    const SizedBox(height: 12),
                    if (_importing)
                      LinearProgressIndicator(value: _progress)
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(t.importNow),
                        onPressed:
                            (plan.toCreate.isEmpty && plan.toUpdate.isEmpty)
                                ? null
                                : _run,
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (_done && plan != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(t.importDone,
                          style: Theme.of(context).textTheme.titleMedium),
                    ]),
                    const SizedBox(height: 8),
                    Text(t.importSummary(
                        plan.toCreate.length,
                        plan.toUpdate.length,
                        plan.skipped,
                        plan.errors.length)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.close),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
