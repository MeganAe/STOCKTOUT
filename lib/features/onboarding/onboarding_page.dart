import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/services/demo_seeder.dart';

/// Tutoriel de premier lancement : 5 ecrans + donnees d'exemple.
/// Rejouable depuis Parametres.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final slides = [
      (Icons.inventory_2, Colors.blue, t.obT1, t.obB1),
      (Icons.store, Colors.amber.shade700, t.obT2, t.obB2),
      (Icons.point_of_sale, Colors.green, t.obT3, t.obB3),
      (Icons.warning_amber, Colors.orange, t.obT4, t.obB4),
      (Icons.rocket_launch, Colors.purple, t.obT5, t.obB5),
    ];
    final last = _page == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: last
                    ? const SizedBox(height: 40)
                    : TextButton(
                        onPressed: widget.onDone, child: Text(t.obSkip)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _Slide(
                  icon: slides[i].$1,
                  color: slides[i].$2,
                  title: slides[i].$3,
                  body: slides[i].$4,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: last
                  ? Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.science_outlined),
                          label: Text(t.obDemo),
                          onPressed: _loadDemo,
                        ),
                        FilledButton(
                          onPressed: widget.onDone,
                          child: Text(t.obStart),
                        ),
                      ],
                    )
                  : FilledButton(
                      onPressed: () => _ctrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: Text(t.obNext),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDemo() async {
    final n = await DemoSeeder.seedIfEmpty();
    if (!mounted) return;
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(n > 0 ? t.obDemoDone : t.obDemoExists)),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _Slide({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
