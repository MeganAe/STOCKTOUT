import 'package:uuid/uuid.dart';

/// Declencheurs disponibles pour les automatisations.
enum AutoTrigger {
  stockLow('stock_low'),
  outOfStock('out_of_stock'),
  saleCreated('sale_created'),
  productExpiry('product_expiry'),
  dailyReport('daily_report'),
  scheduled('scheduled');

  final String value;
  const AutoTrigger(this.value);

  static AutoTrigger from(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => AutoTrigger.stockLow);
}

/// Actions disponibles.
enum AutoAction {
  notify('notify'),
  createPurchaseDraft('create_purchase_draft'),
  adjustPrice('adjust_price'),
  exportCsv('export_csv'),
  printReport('print_report'),
  webhook('webhook');

  final String value;
  const AutoAction(this.value);

  static AutoAction from(String v) =>
      values.firstWhere((e) => e.value == v, orElse: () => AutoAction.notify);
}

class AutomationRule {
  final String id;
  final String name;
  final String? description;
  final AutoTrigger trigger;
  final List<AutoAction> actions;
  final Map<String, Object?> params;
  final bool enabled;

  AutomationRule({
    String? id,
    required this.name,
    this.description,
    required this.trigger,
    this.actions = const [AutoAction.notify],
    this.params = const {},
    this.enabled = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'trigger': trigger.value,
        'actions': actions.map((e) => e.value).join(','),
        'enabled': enabled ? 1 : 0,
      };

  factory AutomationRule.fromMap(Map<String, Object?> m) {
    final raw = (m['actions'] as String? ?? 'notify').split(',');
    return AutomationRule(
      id: m['id'] as String,
      name: m['name'] as String? ?? '',
      description: m['description'] as String?,
      trigger: AutoTrigger.from(m['trigger'] as String? ?? 'stock_low'),
      actions: raw.map(AutoAction.from).toList(),
      enabled: (m['enabled'] as num?)?.toInt() == 1,
    );
  }

  /// Regles proposees a la premiere ouverture.
  static List<AutomationRule> presets() => [
        AutomationRule(
          name: 'Alerte stock bas',
          description: 'Notifie quand un produit passe sous le seuil.',
          trigger: AutoTrigger.stockLow,
          actions: const [AutoAction.notify],
        ),
        AutomationRule(
          name: 'Brouillon commande auto',
          description: 'Cree un brouillon de commande en rupture.',
          trigger: AutoTrigger.outOfStock,
          actions: const [AutoAction.createPurchaseDraft, AutoAction.notify],
        ),
        AutomationRule(
          name: 'Rapport quotidien 18h',
          description: 'Exporte les ventes du jour en CSV.',
          trigger: AutoTrigger.dailyReport,
          actions: const [AutoAction.exportCsv],
        ),
      ];
}
