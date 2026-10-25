import 'package:flutter/material.dart';
import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/v5_strings.dart';
import '../../core/logic/debts.dart';
import '../../core/models/sale.dart';
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
            onTap: () => _editDialog(existing: r),
            trailing: IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(r),
            ),
          ),
        );
      },
    );
  }

  Future<void> _add() => _editDialog();

  /// Création ou modification d'un contact (nom, téléphone, e-mail,
  /// adresse, notes).
  Future<void> _editDialog({Map<String, Object?>? existing}) async {
    final t = AppLocalizations.of(context);
    final kind = existing?['kind'] as String? ??
        (_tab.index == 0 ? 'customer' : 'supplier');
    String v(String k) => '${existing?[k] ?? ''}';
    final name = TextEditingController(text: v('name'));
    final phone = TextEditingController(text: v('phone'));
    final email = TextEditingController(text: v('email'));
    final address = TextEditingController(text: v('address'));
    final notes = TextEditingController(text: v('notes'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null
            ? t.edit
            : (kind == 'customer' ? t.newCustomer : t.newSupplier)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: t.contactName)),
              const SizedBox(height: 12),
              TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t.phone)),
              const SizedBox(height: 12),
              TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.emailLabel)),
              const SizedBox(height: 12),
              TextField(
                  controller: address,
                  decoration: InputDecoration(labelText: t.addressLabel)),
              const SizedBox(height: 12),
              TextField(
                  controller: notes,
                  decoration: InputDecoration(labelText: t.noteOptional)),
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
    if (ok != true || name.text.trim().isEmpty) return;
    final id = existing?['id'] as String?;
    if (id == null) {
      final row = await AppDatabase.instance
          .createPartner(kind, name.text, phone: phone.text);
      await AppDatabase.instance.updatePartner(row['id'] as String, {
        'email': email.text.trim(),
        'address': address.text.trim(),
        'notes': notes.text.trim(),
      });
    } else {
      await AppDatabase.instance.updatePartner(id, {
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'address': address.text.trim(),
        'notes': notes.text.trim(),
      });
    }
    _load();
  }

  /// Confirmation avant suppression. Prévient si le contact a des ventes
  /// ou achats liés (ils restent dans l'historique) et surtout s'il a
  /// encore une dette : elle reste due et visible dans l'écran Dettes.
  Future<void> _confirmDelete(Map<String, Object?> r) async {
    final t = AppLocalizations.of(context);
    final id = '${r['id']}';
    final kind = '${r['kind']}';
    final name = '${r['name'] ?? ''}';
    final links = await AppDatabase.instance.partnerLinkCount(id, kind);
    var hasDebt = false;
    if (kind == 'customer') {
      final sales = (await AppDatabase.instance.allSales())
          .map(Sale.fromRow)
          .where((s) => s.customerId == id)
          .toList();
      final pay = await AppDatabase.instance.allPayments();
      hasDebt = computeDebts(sales, pay, const {}, 'USD').isNotEmpty;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(hasDebt ? Icons.warning_amber_rounded : Icons.delete_outline,
            color: hasDebt ? Colors.orange : null),
        title: Text(t.deleteContactTitle(name)),
        content: Text([
          t.deleteContactAsk,
          if (links > 0) t.deleteContactLinks(links),
          if (hasDebt) t.deleteContactDebt,
        ].join('\n\n')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.db
        .delete('partners', where: 'id = ?', whereArgs: [id]);
    _load();
  }
}
