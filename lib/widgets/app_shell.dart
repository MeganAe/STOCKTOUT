import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/about/about_page.dart';
import '../features/automation/automation_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/inventory/inventory_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/partners/partners_page.dart';
import '../features/products/products_page.dart';
import '../features/purchases/purchases_page.dart';
import '../features/reports/reports_page.dart';
import '../features/sales/sales_page.dart';
import '../features/settings/settings_page.dart';
import 'side_menu.dart';
import 'title_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _onboardingDone = p.getBool('onboarding_done') ?? false);
      }
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
                Expanded(child: pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
