import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers/app_providers.dart';
import '../features/about/about_page.dart';
import '../features/automation/automation_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/partners/partners_page.dart';
import '../features/products/products_page.dart';
import '../features/purchases/purchases_page.dart';
import '../features/reports/reports_page.dart';
import '../features/sales/sales_page.dart';
import '../features/settings/settings_page.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final pages = [
      const DashboardPage(),
      const ProductsPage(),
      const InventoryPage(),
      const SalesPage(),
      const PurchasesPage(),
      const PartnersPage(),
      const ReportsPage(),
      const AutomationPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            minWidth: 86,
            destinations: [
              NavigationRailDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: Text(t.dashboard)),
              NavigationRailDestination(
                  icon: const Icon(Icons.inventory_2_outlined),
                  selectedIcon: const Icon(Icons.inventory_2),
                  label: Text(t.products)),
              NavigationRailDestination(
                  icon: const Icon(Icons.warehouse_outlined),
                  selectedIcon: const Icon(Icons.warehouse),
                  label: Text(t.inventory)),
              NavigationRailDestination(
                  icon: const Icon(Icons.point_of_sale_outlined),
                  selectedIcon: const Icon(Icons.point_of_sale),
                  label: Text(t.sales)),
              NavigationRailDestination(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  selectedIcon: const Icon(Icons.shopping_cart),
                  label: Text(t.purchases)),
              NavigationRailDestination(
                  icon: const Icon(Icons.groups_outlined),
                  selectedIcon: const Icon(Icons.groups),
                  label: Text(t.partners, textAlign: TextAlign.center)),
              NavigationRailDestination(
                  icon: const Icon(Icons.bar_chart_outlined),
                  selectedIcon: const Icon(Icons.bar_chart),
                  label: Text(t.reports)),
              NavigationRailDestination(
                  icon: const Icon(Icons.bolt_outlined),
                  selectedIcon: const Icon(Icons.bolt),
                  label: Text(t.automations, textAlign: TextAlign.center)),
              NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: Text(t.settings)),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton(
                    tooltip: t.about,
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const Dialog(child: AboutPage()),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}
