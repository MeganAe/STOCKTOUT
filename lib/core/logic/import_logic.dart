import '../models/product.dart';
import 'product_codes.dart';

/// Champs importables.
enum ImportField {
  name,
  sku,
  barcode,
  category,
  unit,
  buyPrice,
  sellPrice,
  quantity,
  minStock,
}

/// Retire le BOM UTF-8 éventuel.
String stripBom(String s) =>
    s.isNotEmpty && s.codeUnitAt(0) == 0xFEFF ? s.substring(1) : s;

/// Détecte le séparateur (`,`, `;` ou tabulation) d'après la première ligne
/// non vide, en ignorant ce qui est entre guillemets. Défaut : `,`.
String detectDelimiter(String text) {
  final t = stripBom(text);
  final counts = {',': 0, ';': 0, '\t': 0};
  var inQuotes = false;
  var seenContent = false;
  for (var i = 0; i < t.length; i++) {
    final c = t[i];
    if (c == '"') {
      inQuotes = !inQuotes;
      seenContent = true;
      continue;
    }
    if (!inQuotes && (c == '\n' || c == '\r')) {
      if (seenContent) break;
      continue;
    }
    if (c.trim().isNotEmpty) seenContent = true;
    if (!inQuotes && counts.containsKey(c)) counts[c] = counts[c]! + 1;
  }
  var best = ',';
  var bestN = 0;
  // Ordre de priorité en cas d'égalité : ; puis , puis tab.
  for (final k in [';', ',', '\t']) {
    if (counts[k]! > bestN) {
      best = k;
      bestN = counts[k]!;
    }
  }
  return bestN == 0 ? ',' : best;
}

/// Analyse un CSV (guillemets, guillemets doublés, retours à la ligne dans
/// les champs, CRLF/LF). Les lignes entièrement vides sont ignorées.
List<List<String>> parseCsv(String text, {String? delimiter}) {
  final t = stripBom(text);
  final d = delimiter ?? detectDelimiter(t);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var fieldWasQuoted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
    fieldWasQuoted = false;
  }

  void endRow() {
    endField();
    final empty = row.every((c) => c.trim().isEmpty);
    if (!empty) rows.add(row);
    row = <String>[];
  }

  for (var i = 0; i < t.length; i++) {
    final c = t[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < t.length && t[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"' && field.isEmpty && !fieldWasQuoted) {
      inQuotes = true;
      fieldWasQuoted = true;
    } else if (c == d) {
      endField();
    } else if (c == '\n') {
      endRow();
    } else if (c == '\r') {
      if (i + 1 < t.length && t[i + 1] == '\n') i++;
      endRow();
    } else {
      field.write(c);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty || fieldWasQuoted) endRow();
  return rows;
}

/// Lit un nombre saisi à la française ou à l'anglaise :
/// « 12,5 », « 1 250,50 », « 1.250,50 », « 1,250.50 », « $12 ».
/// Retourne null si le texte n'est pas un nombre.
double? parseNumber(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  var neg = false;
  if (s.startsWith('-')) {
    neg = true;
    s = s.substring(1);
  }
  // Retire espaces (y compris insécables) et symboles de devise/lettres.
  s = s.replaceAll(RegExp(r'[\s\u00A0\u202F]'), '');
  s = s.replaceAll(RegExp(r"[^0-9.,]"), '');
  if (s.isEmpty || !RegExp(r'\d').hasMatch(s)) return null;
  final lastDot = s.lastIndexOf('.');
  final lastComma = s.lastIndexOf(',');
  String normalized;
  if (lastDot >= 0 && lastComma >= 0) {
    // Le dernier séparateur est le décimal, l'autre sépare les milliers.
    if (lastComma > lastDot) {
      normalized = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      normalized = s.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    final parts = s.split(',');
    if (parts.length > 2) {
      normalized = s.replaceAll(',', ''); // 1,234,567
    } else if (parts.last.length == 3 && parts.first.isNotEmpty) {
      normalized = s.replaceAll(',', ''); // 1,250 -> 1250
    } else {
      normalized = s.replaceAll(',', '.');
    }
  } else if (lastDot >= 0) {
    final parts = s.split('.');
    if (parts.length > 2) {
      normalized = s.replaceAll('.', ''); // 1.234.567
    } else if (parts.last.length == 3 &&
        parts.first.isNotEmpty &&
        parts.first != '0') {
      normalized = s.replaceAll('.', ''); // 1.250 -> 1250
    } else {
      normalized = s;
    }
  } else {
    normalized = s;
  }
  final v = double.tryParse(normalized);
  if (v == null) return null;
  return neg ? -v : v;
}

String _norm(String h) {
  var s = h.trim().toLowerCase();
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  s = b.toString();
  return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

const _synonyms = <ImportField, List<String>>{
  ImportField.name: [
    'nom',
    'nomduproduit',
    'nomproduit',
    'produit',
    'designation',
    'libelle',
    'name',
    'product',
    'productname',
    'item',
    'article',
    'description',
  ],
  ImportField.sku: [
    'reference',
    'ref',
    'sku',
    'codearticle',
    'codeproduit',
    'productcode',
    'itemcode',
    'code',
  ],
  ImportField.barcode: [
    'codebarres',
    'codebarre',
    'codesbarres',
    'barcode',
    'ean',
    'ean13',
    'gtin',
    'upc',
  ],
  ImportField.category: ['categorie', 'category', 'famille', 'type', 'groupe'],
  ImportField.unit: ['unite', 'unit', 'uom', 'unites'],
  ImportField.buyPrice: [
    'prixdachat',
    'prixachat',
    'pa',
    'buyprice',
    'cost',
    'cout',
    'coutdachat',
    'purchaseprice',
    'buyingprice',
    'pu achat',
  ],
  ImportField.sellPrice: [
    'prixdevente',
    'prixvente',
    'pv',
    'prix',
    'sellprice',
    'price',
    'sellingprice',
    'saleprice',
    'puvente',
  ],
  ImportField.quantity: [
    'quantite',
    'qte',
    'stock',
    'quantity',
    'qty',
    'stockactuel',
    'enstock',
  ],
  ImportField.minStock: [
    'stockmini',
    'stockminimum',
    'stockmin',
    'minstock',
    'seuil',
    'minimum',
    'min',
    'seuilalerte',
    'minimumstock',
  ],
};

/// Association automatique colonne -> champ d'après les en-têtes (fr/en).
/// Chaque colonne n'est utilisée qu'une fois ; un champ non trouvé vaut null.
Map<ImportField, int?> autoMapColumns(List<String> headers) {
  final normalized = headers.map(_norm).toList();
  final used = <int>{};
  final result = <ImportField, int?>{
    for (final f in ImportField.values) f: null
  };
  // Les champs « précis » d'abord pour éviter qu'un « code » soit pris
  // par la référence alors qu'une colonne « code-barres » existe.
  const order = [
    ImportField.barcode,
    ImportField.buyPrice,
    ImportField.sellPrice,
    ImportField.minStock,
    ImportField.quantity,
    ImportField.name,
    ImportField.sku,
    ImportField.category,
    ImportField.unit,
  ];
  for (final f in order) {
    final syn = _synonyms[f]!.map(_norm).toSet();
    for (var i = 0; i < normalized.length; i++) {
      if (used.contains(i)) continue;
      if (syn.contains(normalized[i])) {
        result[f] = i;
        used.add(i);
        break;
      }
    }
  }
  return result;
}

/// Que faire d'un produit déjà existant (même référence ou code-barres).
enum DuplicateMode { update, skip }

/// Motifs d'erreur d'une ligne (traduits par l'écran).
enum ImportErrorCode { missingName, badNumber, negativeNumber, duplicateInFile }

class ImportRowError {
  /// Numéro de ligne dans le fichier (l'en-tête est la ligne 1).
  final int line;
  final ImportErrorCode code;
  final ImportField? field;
  const ImportRowError(this.line, this.code, [this.field]);
}

class ImportPlan {
  final List<Product> toCreate;
  final List<Product> toUpdate;
  final int skipped;
  final List<ImportRowError> errors;
  const ImportPlan(this.toCreate, this.toUpdate, this.skipped, this.errors);
}

/// Prépare l'import sans toucher à la base. [rows] = lignes de données
/// (sans l'en-tête) ; [firstLine] = numéro de fichier de la 1re ligne de
/// données (2 quand il y a un en-tête).
ImportPlan planImport({
  required List<List<String>> rows,
  required Map<ImportField, int?> mapping,
  required Iterable<Product> existing,
  required DuplicateMode mode,
  int firstLine = 2,
  int? seed,
}) {
  final bySku = <String, Product>{};
  final byBarcode = <String, Product>{};
  final usedSkus = <String>{};
  final usedBarcodes = <String>{};
  for (final p in existing) {
    if (p.sku.trim().isNotEmpty) bySku[p.sku.trim().toLowerCase()] = p;
    final b = (p.barcode ?? '').trim();
    if (b.isNotEmpty) byBarcode[b.toLowerCase()] = p;
    usedSkus.add(p.sku.trim().toLowerCase());
    if (b.isNotEmpty) usedBarcodes.add(b.toLowerCase());
  }
  var skuCounter = maxSkuNumber(existing.map((e) => e.sku));
  final baseSeed = seed ?? DateTime.now().millisecondsSinceEpoch;
  var eanOffset = 0;

  String cell(List<String> r, ImportField f) {
    final i = mapping[f];
    if (i == null || i < 0 || i >= r.length) return '';
    return r[i].trim();
  }

  final created = <Product>[];
  final updated = <Product>[];
  final errors = <ImportRowError>[];
  final seenInFile = <String>{};
  final updatedIds = <String>{};
  var skipped = 0;

  for (var idx = 0; idx < rows.length; idx++) {
    final r = rows[idx];
    final line = firstLine + idx;
    final name = cell(r, ImportField.name);
    if (name.isEmpty) {
      errors.add(ImportRowError(line, ImportErrorCode.missingName));
      continue;
    }

    // Nombres : vide = « non fourni », illisible = erreur, négatif = erreur.
    final nums = <ImportField, double?>{};
    ImportRowError? numError;
    for (final f in [
      ImportField.buyPrice,
      ImportField.sellPrice,
      ImportField.quantity,
      ImportField.minStock,
    ]) {
      final raw = cell(r, f);
      if (raw.isEmpty) {
        nums[f] = null;
        continue;
      }
      final v = parseNumber(raw);
      if (v == null) {
        numError = ImportRowError(line, ImportErrorCode.badNumber, f);
        break;
      }
      if (v < 0) {
        numError = ImportRowError(line, ImportErrorCode.negativeNumber, f);
        break;
      }
      nums[f] = v;
    }
    if (numError != null) {
      errors.add(numError);
      continue;
    }

    final sku = cell(r, ImportField.sku);
    final barcode = cell(r, ImportField.barcode);
    final skuKey = sku.toLowerCase();
    final barKey = barcode.toLowerCase();

    // Doublon à l'intérieur du fichier.
    final fileKeys = [
      if (skuKey.isNotEmpty) 's:$skuKey',
      if (barKey.isNotEmpty) 'b:$barKey',
    ];
    if (fileKeys.any(seenInFile.contains)) {
      errors.add(ImportRowError(line, ImportErrorCode.duplicateInFile));
      continue;
    }
    seenInFile.addAll(fileKeys);

    // Doublon avec un produit existant (référence ou code-barres).
    final match = (barKey.isNotEmpty ? byBarcode[barKey] : null) ??
        (skuKey.isNotEmpty ? bySku[skuKey] : null);
    if (match != null) {
      if (mode == DuplicateMode.skip || updatedIds.contains(match.id)) {
        skipped++;
        continue;
      }
      final category = cell(r, ImportField.category);
      final unit = cell(r, ImportField.unit);
      updated.add(match.copyWith(
        name: name,
        category: category.isEmpty ? null : category,
        unit: unit.isEmpty ? null : unit,
        buyPrice: nums[ImportField.buyPrice],
        sellPrice: nums[ImportField.sellPrice],
        quantity: nums[ImportField.quantity],
        minStock: nums[ImportField.minStock],
      ));
      updatedIds.add(match.id);
      continue;
    }

    // Nouveau produit : référence et code-barres générés si absents.
    var finalSku = sku;
    if (finalSku.isEmpty) {
      do {
        skuCounter++;
        finalSku = skuForNumber(skuCounter);
      } while (usedSkus.contains(finalSku.toLowerCase()));
    }
    var finalBarcode = barcode;
    if (finalBarcode.isEmpty) {
      do {
        finalBarcode = generateEan13(baseSeed + eanOffset++);
      } while (usedBarcodes.contains(finalBarcode));
    }
    usedSkus.add(finalSku.toLowerCase());
    usedBarcodes.add(finalBarcode.toLowerCase());

    final buy = nums[ImportField.buyPrice] ?? 0;
    var sell = nums[ImportField.sellPrice];
    // Comme dans le formulaire produit : +30 % si le prix de vente manque.
    sell ??= buy > 0 ? (buy * 1.3 * 100).round() / 100 : 0;
    final category = cell(r, ImportField.category);
    final unit = cell(r, ImportField.unit);
    created.add(Product(
      sku: finalSku,
      name: name,
      barcode: finalBarcode,
      category: category.isEmpty ? null : category,
      unit: unit.isEmpty ? 'pc' : unit,
      buyPrice: buy,
      sellPrice: sell,
      quantity: nums[ImportField.quantity] ?? 0,
      minStock: nums[ImportField.minStock] ?? 5,
    ));
  }
  return ImportPlan(created, updated, skipped, errors);
}

/// Contenu du modèle CSV proposé au téléchargement (BOM + en-têtes + 2 lignes).
String csvTemplate() => '\uFEFF'
    'nom;reference;code-barres;categorie;unite;prix d\'achat;prix de vente;quantite;stock mini\n'
    'Savon de Marseille;P-0001;2001234567890;Hygiène;pc;1,50;2,00;40;5\n'
    'Riz 25 kg;P-0002;;Alimentation;kg;18;22,5;12;3\n';
