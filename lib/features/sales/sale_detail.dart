import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/database.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/extra_strings.dart';
import '../../core/models/sale.dart';
import '../../core/models/stock_movement.dart';
import '../../core/providers/app_providers.dart';

/// Libelle traduit d'un moyen de paiement (code stable en base).
String paymentLabel(AppLocalizations t, String? code) {
  switch (code) {
    case 'cash':
      return t.cash;
    case 'mobile':
      return t.mobileMoney;
    case 'card':
      return t.card;
    case 'transfer':
      return t.transfer;
    case 'credit':
      return t.credit;
    default:
      return code ?? '';
  }
}

String _qty(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

String receiptText(AppLocalizations t, Sale s) {
  final b = StringBuffer()
    ..writeln('${t.receipt} ${s.number}')
    ..writeln('${s.date.toIso8601String().split('T').first}');
  if ((s.customerName ?? '').isNotEmpty) b.writeln(s.customerName);
  b.writeln('------------------------');
  for (final l in s.lines) {
    b.writeln('${l.productName}');
    final disc = l.discount > 0 ? ' (-${l.discount.toStringAsFixed(2)})' : '';
    b.writeln(
        '  ${_qty(l.quantity)} x ${l.unitPrice.toStringAsFixed(2)}$disc = ${l.total.toStringAsFixed(2)}');
  }
  b.writeln('------------------------');
  if (s.discount > 0) {
    b.writeln('${t.subtotal}: ${s.subTotal.toStringAsFixed(2)}');
    b.writeln('${t.discount}: -${s.discount.toStringAsFixed(2)}');
  }
  b.writeln('${t.total}: ${s.total.toStringAsFixed(2)} ${s.currency}');
  b.writeln('${t.payment}: ${paymentLabel(t, s.paymentMethod)}');
  return b.toString();
}

/// Detail d'une vente : lignes, remise, total, recu et annulation.
Future<void> showSaleDetail(
  BuildContext context,
  WidgetRef ref,
  Map<String, Object?> row,
) {
  final sale = Sale.fromRow(row);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final t = AppLocalizations.of(ctx);
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.receipt_long),
                const SizedBox(width: 8),
                Expanded(child: Text(sale.number, style: text.titleLarge)),
                Text(sale.date.toIso8601String().split('T').first,
                    style: text.bodySmall),
              ]),
              if ((sale.customerName ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(sale.customerName!, style: text.bodyMedium),
                ),
              const Divider(height: 24),
              for (final l in sale.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${_qty(l.quantity)} × ${l.unitPrice.toStringAsFixed(2)}'
                            '${l.discount > 0 ? '  −${l.discount.toStringAsFixed(2)}' : ''}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(l.total.toStringAsFixed(2)),
                  ]),
                ),
              const Divider(height: 24),
              if (sale.discount > 0) ...[
                _row(t.subtotal, sale.subTotal.toStringAsFixed(2)),
                _row(t.discount, '−${sale.discount.toStringAsFixed(2)}'),
              ],
              _row(t.payment, paymentLabel(t, sale.paymentMethod)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.total, style: text.titleLarge),
                  Text('${sale.total.toStringAsFixed(2)} ${sale.currency}',
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.share),
                    label: Text(t.shareReceipt),
                    onPressed: () =>
                        Share.share(receiptText(t, sale), subject: sale.number),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: t.cancelSale,
                  icon: const Icon(Icons.undo),
                  onPressed: () => _cancel(ctx, ref, sale),
                ),
              ]),
            ],
          ),
        ),
      );
    },
  );
}

Widget _row(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a), Text(b)],
      ),
    );

Future<void> _cancel(BuildContext ctx, WidgetRef ref, Sale sale) async {
  final t = AppLocalizations.of(ctx);
  final ok = await showDialog<bool>(
    context: ctx,
    builder: (dctx) => AlertDialog(
      title: Text(t.cancelSale),
      content: Text(t.cancelSaleAsk),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dctx, false), child: Text(t.no)),
        FilledButton(
            onPressed: () => Navigator.pop(dctx, true), child: Text(t.yes)),
      ],
    ),
  );
  if (ok != true) return;

  // Remet chaque article en stock puis supprime la vente.
  for (final l in sale.lines) {
    await AppDatabase.instance.addMovement(StockMovement(
      productId: l.productId,
      type: MovementType.return_,
      quantity: l.quantity,
      unitPrice: l.unitPrice,
      reference: sale.number,
      reason: t.cancelSale,
    ));
  }
  await AppDatabase.instance.deleteSale(sale.id);
  ref.invalidate(productsProvider);
  ref.invalidate(salesProvider);
  if (ctx.mounted) {
    Navigator.of(ctx).pop();
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(t.saleCancelled)));
  }
}
