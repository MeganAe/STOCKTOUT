import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/v5_strings.dart';

/// Menu lateral pliable : ouvert = icones + textes, ferme = icones seules.
/// L'etat est memorise entre les lancements.
class SideMenu extends StatefulWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAbout;

  const SideMenu({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onAbout,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  bool _collapsed = false;

  static const _icons = [
    Icons.dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.warehouse_outlined,
    Icons.point_of_sale_outlined,
    Icons.shopping_cart_outlined,
    Icons.groups_outlined,
    Icons.bar_chart_outlined,
    Icons.bolt_outlined,
    Icons.settings_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.receipt_long_outlined,
  ];

  static const _iconsSel = [
    Icons.dashboard,
    Icons.inventory_2,
    Icons.warehouse,
    Icons.point_of_sale,
    Icons.shopping_cart,
    Icons.groups,
    Icons.bar_chart,
    Icons.bolt,
    Icons.settings,
    Icons.account_balance_wallet,
    Icons.receipt_long,
  ];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _collapsed = p.getBool('menu_collapsed') ?? false);
      }
    });
  }

  Future<void> _toggle() async {
    setState(() => _collapsed = !_collapsed);
    final p = await SharedPreferences.getInstance();
    await p.setBool('menu_collapsed', _collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final labels = [
      t.dashboard,
      t.products,
      t.inventory,
      t.sales,
      t.purchases,
      t.partners,
      t.reports,
      t.automations,
      t.settings,
      t.debts,
      t.expenses,
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _collapsed ? 72 : 232,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          if (_collapsed)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggle,
                child: Tooltip(
                  message: t.menuExpand,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 36,
                      height: 36,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'StockTout',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: t.menuCollapse,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _toggle,
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: labels.length,
              itemBuilder: (ctx, i) {
                final sel = i == widget.selected;
                final item = Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.onSelect(i),
                    child: Container(
                      height: 44,
                      padding:
                          EdgeInsets.symmetric(horizontal: _collapsed ? 0 : 12),
                      decoration: sel
                          ? BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      child: Row(
                        mainAxisAlignment: _collapsed
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          Icon(
                            sel ? _iconsSel[i] : _icons[i],
                            color: sel
                                ? scheme.onSecondaryContainer
                                : scheme.onSurfaceVariant,
                          ),
                          if (!_collapsed) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: sel
                                      ? scheme.onSecondaryContainer
                                      : scheme.onSurface,
                                  fontWeight:
                                      sel ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
                return _collapsed
                    ? Tooltip(message: labels[i], child: item)
                    : item;
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _collapsed
                ? IconButton(
                    tooltip: t.about,
                    icon: const Icon(Icons.info_outline),
                    onPressed: widget.onAbout,
                  )
                : SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: widget.onAbout,
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: Text(t.about),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
