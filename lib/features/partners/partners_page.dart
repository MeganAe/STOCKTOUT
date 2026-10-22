import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../widgets/feature_tour.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});
  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<Map<String, Object?>> _rows = [];
  final kList = GlobalKey();
  final kAction = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final rows =
        await AppDatabase.instance.db.query('partners', orderBy: 'name ASC');
    if (!mounted) return;
    setState(() => _rows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GuidedTour(
      id: 'partners',
      steps: [
        TourStep(target: kAction, title: t.gsAction, body: t.gsActionB),
        TourStep(target: kList, title: t.gsList, body: t.gsListB),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.partners),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: KeyedSubtree(
                key: kAction,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(t.add),
                  onPressed: _add,
                ),
              ),
            ),
          ],
          bottom: TabBar(controller: _tab, tabs: [
            Tab(text: t.customers),
            Tab(text: t.suppliers),
          ]),
        ),
        body: KeyedSubtree(
          key: kList,
          child: TabBarView(
            controller: _tab,
            children: [
              _list('customer'),
              _list('supplier'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(String kind) {
    final t = AppLocalizations.of(context);
    final rows = _rows.where((e) => e['kind'] == kind).toList();
    if (rows.isEmpty) return Center(child: Text(t.noContact));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        final name = '${r['name'] ?? ''}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            title: Text(name),
            subtitle: Text('${r['phone'] ?? ''} ${r['email'] ?? ''}'.trim()),
            trailing: IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await AppDatabase.instance.db
                    .delete('partners', where: 'id = ?', whereArgs: [r['id']]);
                _load();
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _add() async {
    final t = AppLocalizations.of(context);
    final kind = _tab.index == 0 ? 'customer' : 'supplier';
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(kind == 'customer' ? t.newCustomer : t.newSupplier),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: InputDecoration(labelText: t.contactName)),
            const SizedBox(height: 12),
            TextField(
                controller: phone,
                decoration: InputDecoration(labelText: t.phone)),
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
