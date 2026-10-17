import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/automation.dart';
import '../../core/providers/app_providers.dart';

/// Regles automatiques : stock bas, ruptures, rapports planifies...
class AutomationPage extends ConsumerWidget {
  const AutomationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final autoAsync = ref.watch(automationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.automations),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle regle'),
              onPressed: () => _edit(context, ref, null),
            ),
          ),
        ],
      ),
      body: autoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rules) {
          if (rules.isEmpty) return const Center(child: Text('Aucune regle.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (ctx, i) {
              final r = rules[i];
              return Card(
                child: SwitchListTile(
                  value: r.enabled,
                  onChanged: (v) async {
                    await AppDatabase.instance.upsertAutomation(
                      AutomationRule(
                        id: r.id,
                        name: r.name,
                        description: r.description,
                        trigger: r.trigger,
                        actions: r.actions,
                        enabled: v,
                      ),
                    );
                    ref.invalidate(automationsProvider);
                  },
                  title: Text(r.name),
                  subtitle: Text(
                      '${r.trigger.value} → ${r.actions.map((e) => e.value).join(', ')}\n${r.description ?? ''}'),
                  isThreeLine: true,
                  secondary: const Icon(Icons.bolt),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, AutomationRule? rule) async {
    final name = TextEditingController(text: rule?.name ?? '');
    AutoTrigger trigger = rule?.trigger ?? AutoTrigger.stockLow;
    final selected = <AutoAction>{
      ...(rule?.actions ?? [AutoAction.notify])
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Regle automatique'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Nom de la regle')),
                const SizedBox(height: 12),
                DropdownButtonFormField<AutoTrigger>(
                  value: trigger,
                  items: AutoTrigger.values
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => trigger = v!),
                  decoration: const InputDecoration(labelText: 'Declencheur'),
                ),
                const SizedBox(height: 12),
                ...AutoAction.values.map((a) => CheckboxListTile(
                      dense: true,
                      value: selected.contains(a),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          selected.add(a);
                        } else {
                          selected.remove(a);
                        }
                      }),
                      title: Text(a.value),
                    )),
              ],
            ),
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
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty && selected.isNotEmpty) {
      await AppDatabase.instance.upsertAutomation(AutomationRule(
        id: rule?.id,
        name: name.text.trim(),
        trigger: trigger,
        actions: selected.toList(),
        enabled: rule?.enabled ?? true,
      ));
      ref.invalidate(automationsProvider);
    }
  }
}
