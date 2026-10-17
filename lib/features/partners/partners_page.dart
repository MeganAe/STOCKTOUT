import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});
  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Map<String, Object?>> _rows = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    _rows = await AppDatabase.instance.db.query('partners', orderBy: 'name ASC');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.partners),
        bottom: TabBar(controller: _tab, tabs: const [
          Tab(text: 'Clients'),
          Tab(text: 'Fournisseurs'),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(t.add),
              onPressed: _add,
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _list('customer'),
          _list('supplier'),
        ],
      ),
    );
  }

  // ---- listes ----

  Widget _list(String kind) {
    final rows = _rows.where((e) => e['kind'] == kind).toList();
    if (rows.isEmpty) return const Center(child: Text('Aucun contact.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
                child: Text('${r['name']}'.isNotEmpty
                    ? '${r['name']}'.substring(0, 1).toUpperCase()
                    : '?')),
            title: Text('${r['name']}'),
            subtitle: Text('${r['phone'] ?? ''} ${r['email'] ?? ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await AppDatabase.instance.db.delete('partners',
                    where: 'id = ?', whereArgs: [r['id']]);
                _load();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _add() async {
    final kind = _tab.index == 0 ? 'customer' : 'supplier';
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kind == 'customer' ? 'Nouveau client' : 'Nouveau fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 12),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Telephone')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await AppDatabase.instance.db.insert('partners', {
        'id': const Uuid().v4(),
        'kind': kind,
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': '',
        'address': '',
        'notes': '',
      });
      _load();
    }
  }
}
