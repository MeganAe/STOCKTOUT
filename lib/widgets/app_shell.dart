import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/v5_strings.dart';
import '../features/about/about_page.dart';
import '../features/automation/automation_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/debts/debts_page.dart';
import '../features/expenses/expenses_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/partners/partners_page.dart';
import '../features/products/products_page.dart';
import '../features/purchases/purchases_page.dart';
import '../features/reports/reports_page.dart';
import '../features/sales/sales_page.dart';
import '../features/settings/settings_page.dart';
import 'feature_tour.dart';
import 'side_menu.dart';
import 'title_bar.dart';

bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool? _onboardingDone;

  /// Pages dans l'ordre du menu.
  static const _pages = [
    DashboardPage(),
    ProductsPage(),
    InventoryPage(),
    SalesPage(),
    PurchasesPage(),
    PartnersPage(),
    ReportsPage(),
    AutomationPage(),
    SettingsPage(),
    DebtsPage(),
    ExpensesPage(),
  ];

  /// Index des 4 onglets principaux sur mobile.
  static const _tabs = [0, 1, 3, 2];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      TourSession.enabled = p.getBool('tips_enabled') ?? true;
      setState(() => _onboardingDone = p.getBool('onboarding_done') ?? false);
    });
  }

  Future<void> _finishOnboarding() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  void _openAbout() => showDialog(
        context: context,
        builder: (_) => const Dialog(child: AboutPage()),
      );

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_onboardingDone!) {
      return OnboardingPage(onDone: _finishOnboarding);
    }
    if (!isDesktop) return _mobileShell();
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(),
          Expanded(
            child: Row(
              children: [
                SideMenu(
                  selected: _index,
                  onSelect: (i) => setState(() => _index = i),
                  onAbout: _openAbout,
                ),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileShell() {
    final t = AppLocalizations.of(context);
    final inTabs = _tabs.contains(_index);
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: inTabs ? _tabs.indexOf(_index) : 4,
        onDestinationSelected: (i) {
          if (i == 4) {
            _openMore();
            return;
          }
          setState(() => _index = _tabs[i]);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: t.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: t.products,
          ),
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale_outlined),
            selectedIcon: const Icon(Icons.point_of_sale),
            label: t.sales,
          ),
          NavigationDestination(
            icon: const Icon(Icons.warehouse_outlined),
            selectedIcon: const Icon(Icons.warehouse),
            label: t.inventory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps),
            label: t.more,
          ),
        ],
      ),
    );
  }

  void _openMore() {
    final t = AppLocalizations.of(context);
    final items = [
      (4, Icons.shopping_cart_outlined, t.purchases),
      (5, Icons.groups_outlined, t.partners),
      (6, Icons.bar_chart_outlined, t.reports),
      (7, Icons.bolt_outlined, t.automations),
      (8, Icons.settings_outlined, t.settings),
      (9, Icons.account_balance_wallet_outlined, t.debts),
      (10, Icons.receipt_long_outlined, t.expenses),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...items.map((e) => ListTile(
                  leading: Icon(e.$2),
                  title: Text(e.$3),
                  selected: _index == e.$1,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _index = e.$1);
                  },
                )),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(t.about),
              onTap: () {
                Navigator.pop(ctx);
                _openAbout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
