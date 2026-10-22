import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/automation.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/feature_tour.dart';

/// Regles automatiques : stock bas, ruptures, rapports planifies...
class AutomationPage extends ConsumerStatefulWidget {
  const AutomationPage({super.key});
  @override
  ConsumerState<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends ConsumerState<AutomationPage> {
  final kAction = GlobalKey();
  final kList = GlobalKey();

  String _triggerLabel(AppLocalizations t, AutoTrigger v) {
    switch (v) {
      case AutoTrigger.stockLow:
        return t.trgStockLow;
      case AutoTrigger.outOfStock:
        return t.trgOutOfStock;
      case AutoTrigger.saleCreated:
        return t.trgSale;
      case AutoTrigger.productExpiry:
        return t.trgExpiry;
      case AutoTrigger.dailyReport:
        return t.trgDaily;
      case AutoTrigger.scheduled:
        return t.trgScheduled;
    }
  }

  String _actionLabel(AppLocalizations t, AutoAction a) {
    switch (a) {
      case AutoAction.notify:
        return t.actNotify;
      case AutoAction.createPurchaseDraft:
        return t.actDraft;
      case AutoAction.adjustPrice:
        return t.actPrice;
      case AutoAction.exportCsv:
        return t.actExport;
      case AutoAction.printReport:
        return t.actPrint;
      case AutoAction.webhook:
        return t.actWebhook;
    }
  }

  /// Les noms des regles predefinies sont stockes en clair ; on les
  /// re-traduit a l'affichage quand elles n'ont pas ete renommees.
  String _ruleName(AppLocalizations t, AutomationRule r) {
    switch (r.name) {
      case 'preset_low':
        return t.presetLowName;
      case 'preset_draft':
        return t.presetDraftName;
      case 'preset_report':
        return t.presetReportName;
      default:
        return r.name;
    }
  }

  String? _ruleDesc(AppLocalizations t, AutomationRule r) {
    switch (r.trigger) {
      case AutoTrigger.stockLow:
        return t.presetLowDesc;
      case AutoTrigger.outOfStock:
        return t.presetDraftDesc;
      case AutoTrigger.dailyReport:
        return t.presetReportDesc;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final autoAsync = ref.watch(automationsProvider);

    return GuidedTour(
      id: 'automations',
      steps: [
        TourStep(target: kAction, title: t.gsAction, body: t.gsActionB),
        TourStep(target: kList, title: t.automations, body: t.gsListB),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.automations),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: KeyedSubtree(
                key: kAction,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(t.newRule),
                  onPressed: () => _edit(context, null),
                ),
              ),
            ),
          ],
        ),
        body: autoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (rules) {
            if (rules.isEmpty) return Center(child: Text(t.noRules));
            return KeyedSubtree(
              key: kList,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rules.length,
                itemBuilder: (ctx, i) {
                  final r = rules[i];
                  final desc = r.description ?? _ruleDesc(t, r);
                  final actions =
                      r.actions.map((a) => _actionLabel(t, a)).join(' · ');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
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
                      title: Text(_ruleName(t, r)),
                      subtitle: Text(
                        '${_triggerLabel(t, r.trigger)} → $actions'
                        '${desc != null ? '\n$desc' : ''}',
                      ),
                      isThreeLine: desc != null,
                      secondary: const Icon(Icons.bolt),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, AutomationRule? rule) async {
    final t = AppLocalizations.of(context);
    final name = TextEditingController(text: rule?.name ?? '');
    AutoTrigger trigger = rule?.trigger ?? AutoTrigger.stockLow;
    final selected = <AutoAction>{
      ...(rule?.actions ?? [AutoAction.notify])
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(t.ruleDialog),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: t.ruleName)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AutoTrigger>(
                    value: trigger,
                    items: AutoTrigger.values
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(_triggerLabel(t, e))))
                        .toList(),
                    onChanged: (v) => setState(() => trigger = v!),
                    decoration: InputDecoration(labelText: t.trigger),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(t.actions,
                        style: Theme.of(context).textTheme.titleSmall),
                  ),
                  ...AutoAction.values.map((a) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(a),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            selected.add(a);
                          } else {
                            selected.remove(a);
                          }
                        }),
                        title: Text(_actionLabel(t, a)),
                      )),
                ],
              ),
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
      ),
    );

    if (ok == true && name.text.trim().isNotEmpty && selected.isNotEmpty) {
      await AppDatabase.instance.upsertAutomation(AutomationRule(
        id: rule?.id,
        name: name.text.trim(),
        description: rule?.description,
        trigger: trigger,
        actions: selected.toList(),
        enabled: rule?.enabled ?? true,
      ));
      ref.invalidate(automationsProvider);
    }
  }
}
