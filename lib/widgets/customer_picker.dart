import 'package:flutter/material.dart';

import '../core/database/database.dart';
import '../core/l10n/app_localizations.dart';
import '../core/l10n/v5_strings.dart';

/// Client choisi dans la liste des partenaires.
class CustomerChoice {
  final String id;
  final String name;
  const CustomerChoice(this.id, this.name);
}

/// Feuille de sélection d'un client : recherche par nom/téléphone et
/// création rapide. Retourne null si l'utilisateur ferme la feuille.
Future<CustomerChoice?> pickCustomer(BuildContext context) =>
    pickPartner(context, kind: 'customer');

/// Même feuille pour les fournisseurs : [kind] = 'customer' ou 'supplier'
/// (valeurs de la colonne `partners.kind`).
Future<CustomerChoice?> pickPartner(BuildContext context,
    {String kind = 'customer'}) {
  return showModalBottomSheet<CustomerChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CustomerSheet(kind: kind),
  );
}

class _CustomerSheet extends StatefulWidget {
  final String kind;
  const _CustomerSheet({required this.kind});

  @override
  State<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends State<_CustomerSheet> {
  final _q = TextEditingController();
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows =
        await AppDatabase.instance.partnersOfKind(widget.kind, query: _q.text);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _create() async {
    final t = AppLocalizations.of(context);
    final name = TextEditingController(text: _q.text.trim());
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.kind == 'supplier' ? t.newSupplier : t.newCustomer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: t.contactName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.phoneOptional),
            ),
          ],
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
    final n = name.text.trim();
    if (ok != true || n.isEmpty) return;
    final row = await AppDatabase.instance
        .createPartner(widget.kind, n, phone: phone.text);
    if (!mounted) return;
    Navigator.pop(context, CustomerChoice(row['id'] as String, n));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _q,
                decoration: InputDecoration(
                  hintText: widget.kind == 'supplier'
                      ? t.searchSupplier
                      : t.searchCustomer,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (_) => _load(),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_add_alt_1)),
              title: Text(
                  widget.kind == 'supplier' ? t.newSupplier : t.newCustomer),
              onTap: _create,
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                      ? Center(
                          child: Text(widget.kind == 'supplier'
                              ? t.noContact
                              : t.noCustomerFound))
                      : ListView.builder(
                          itemCount: _rows.length,
                          itemBuilder: (_, i) {
                            final r = _rows[i];
                            final name = '${r['name']}';
                            final phone = '${r['phone'] ?? ''}';
                            return ListTile(
                              leading: CircleAvatar(
                                  child: Text(name.isEmpty
                                      ? '?'
                                      : name[0].toUpperCase())),
                              title: Text(name),
                              subtitle: phone.isEmpty ? null : Text(phone),
                              onTap: () => Navigator.pop(
                                  context, CustomerChoice('${r['id']}', name)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
