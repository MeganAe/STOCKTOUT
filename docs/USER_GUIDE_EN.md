# User guide — StockPro

## Getting started

1. Open the app.
2. Go to **Settings**: pick your language and currency.
3. Add products in **Products** > **New product**.
4. Sell in **Sales** (point of sale).

## Products

- **SKU**: your internal code. Auto-generated if empty.
- **Buy / sell price**: used for margin and stock value.
- **Min. stock**: alert threshold. Below it, the product is flagged.
- **In / out** (swap icon): fix stock without a sale.

## Sales (POS)

1. Click products to add them to the cart.
2. Choose the payment method.
3. **Checkout**. Stock is decreased automatically.

## Purchases

1. **Purchases** > **New purchase**: product, quantity, supplier.
2. On delivery: **Receive**. Stock goes up automatically.
3. Stockouts can create draft orders (see Automations).

## Inventory

Product list on the left, movement history on the right.
Every in/out/adjustment is logged with date and reason.

## Reports

- **CSV export**: opens in Excel.
- **PDF / Print**: stock statement.
- **Value by category**: where your money sits.

## Automations

Built-in rules:

- Alert when a product drops below threshold.
- Draft order on stockout.
- Daily sales export.

Create your own: trigger (low stock, sale, report...) + actions
(notify, draft order, export...). See [AUTOMATIONS.md](AUTOMATIONS.md).

## Currencies

USD, EUR, CDF, XAF, XOF included. Update rates in
**Settings** > **Currency**, add your own. See [CURRENCIES.md](CURRENCIES.md).

## Backup

**Settings** > **Backup**: pick a folder (USB stick, drive...).
**Restore**: pick a saved `.db` file, restart the app.
Back up at least weekly.

## FAQ

**Offline?** Yes, everything is local.

**Where is my data?** In `<Documents>/stockpro/stockpro.db`.

**New computer?** Back up, install the app, restore the file.

**Multi-user?** Not yet. One person at a time per machine.
