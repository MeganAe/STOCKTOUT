import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Tutoriel de premier lancement : 5 ecrans animes.
/// Rejouable depuis Parametres.
class OnboardingPage extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingPage({super.key, required this.onDone});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _ctrl = PageController();
  late final AnimationController _intro;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final target = (_page + delta).clamp(0, 4);
    if (target == _page) {
      if (delta > 0) widget.onDone();
      return;
    }
    _ctrl.animateToPage(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final slides = [
      (Icons.inventory_2_outlined, t.obT1, t.obB1),
      (Icons.storefront_outlined, t.obT2, t.obB2),
      (Icons.point_of_sale_outlined, t.obT3, t.obB3),
      (Icons.notification_important_outlined, t.obT4, t.obB4),
      (Icons.rocket_launch_outlined, t.obT5, t.obB5),
    ];
    final last = _page == slides.length - 1;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surfaceContainerLowest,
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _intro,
            child: Column(
              children: [
                // En-tete : marque + passer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/images/logo.png',
                            width: 26, height: 26),
                      ),
                      const SizedBox(width: 10),
                      Text('StockTout',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurfaceVariant)),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: last ? 0 : 1,
                        child: TextButton(
                          onPressed: last ? null : widget.onDone,
                          child: Text(t.obSkip),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (ctx, i) => _Slide(
                      icon: slides[i].$1,
                      title: slides[i].$2,
                      body: slides[i].$3,
                      index: i,
                      page: _page,
                    ),
                  ),
                ),
                // Pastilles : la pastille active s'etire
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: active ? 26 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: active ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: last
                        ? Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _go(-1),
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: Text(t.obPrev),
                              ),
                              FilledButton.icon(
                                onPressed: widget.onDone,
                                icon: const Icon(Icons.check, size: 18),
                                label: Text(t.obStart),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              if (_page > 0)
                                TextButton.icon(
                                  onPressed: () => _go(-1),
                                  icon: const Icon(Icons.arrow_back, size: 18),
                                  label: Text(t.obPrev),
                                ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => _go(1),
                                icon: const Icon(Icons.arrow_forward, size: 18),
                                label: Text(t.obNext),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final int index;
  final int page;

  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.index,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Animation locale : la page glisse/zoome selon sa distance au centre.
    final delta = (index - page).toDouble();
    final near = delta.abs() < 0.6;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: near ? 1 : 0.35,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              scale: near ? 1 : 0.94,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          scheme.primary.withOpacity(0.16),
                          scheme.primary.withOpacity(0.04),
                        ],
                      ),
                      border: Border.all(
                        color: scheme.primary.withOpacity(0.18),
                      ),
                    ),
                    child: Icon(icon, size: 52, color: scheme.primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
