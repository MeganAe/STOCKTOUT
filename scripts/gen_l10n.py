#!/usr/bin/env python3
"""Genere lib/core/l10n/app_localizations.dart + fichiers l10n/*.arb (27 langues)."""
import json, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DART = os.path.join(BASE, "lib/core/l10n/app_localizations.dart")
ARB_DIR = os.path.join(BASE, "l10n")

# key: {lang: text}
T = {
 "dashboard": {"en":"Dashboard","fr":"Tableau de bord","es":"Panel","de":"Übersicht","it":"Cruscotto","pt":"Painel","nl":"Dashboard","ru":"Панель","zh":"仪表盘","ja":"ダッシュボード","ko":"대시보드","ar":"لوحة التحكم","hi":"डैशबोर्ड","tr":"Panel","pl":"Panel","sv":"Översikt","da":"Overblik","no":"Oversikt","fi":"Kojelauta","el":"Πίνακας","cs":"Přehled","ro":"Panou","hu":"Vezérlőpult","id":"Dasbor","sw":"Dashibodi","ln":"Tableau de bord","uk":"Панель"},
 "products": {"en":"Products","fr":"Produits","es":"Productos","de":"Produkte","it":"Prodotti","pt":"Produtos","nl":"Producten","ru":"Товары","zh":"产品","ja":"商品","ko":"상품","ar":"المنتجات","hi":"उत्पाद","tr":"Ürünler","pl":"Produkty","sv":"Produkter","da":"Produkter","no":"Produkter","fi":"Tuotteet","el":"Προϊόντα","cs":"Produkty","ro":"Produse","hu":"Termékek","id":"Produk","sw":"Bidhaa","ln":"Biloko","uk":"Товари"},
 "inventory": {"en":"Inventory","fr":"Inventaire","es":"Inventario","de":"Bestand","it":"Magazzino","pt":"Estoque","nl":"Voorraad","ru":"Склад","zh":"库存","ja":"在庫","ko":"재고","ar":"المخزون","hi":"स्टॉक","tr":"Stok","pl":"Magazyn","sv":"Lager","da":"Lager","no":"Lager","fi":"Varasto","el":"Απόθεμα","cs":"Sklad","ro":"Stoc","hu":"Készlet","id":"Inventaris","sw":"Stoki","ln":"Stock","uk":"Склад"},
 "sales": {"en":"Sales","fr":"Ventes","es":"Ventas","de":"Verkäufe","it":"Vendite","pt":"Vendas","nl":"Verkopen","ru":"Продажи","zh":"销售","ja":"売上","ko":"판매","ar":"المبيعات","hi":"बिक्री","tr":"Satışlar","pl":"Sprzedaż","sv":"Försäljning","da":"Salg","no":"Salg","fi":"Myynti","el":"Πωλήσεις","cs":"Prodeje","ro":"Vânzări","hu":"Eladások","id":"Penjualan","sw":"Mauzo","ln":"Tekete","uk":"Продажі"},
 "purchases": {"en":"Purchases","fr":"Achats","es":"Compras","de":"Einkäufe","it":"Acquisti","pt":"Compras","nl":"Aankopen","ru":"Закупки","zh":"采购","ja":"仕入れ","ko":"구매","ar":"المشتريات","hi":"खरीद","tr":"Alımlar","pl":"Zakupy","sv":"Inköp","da":"Køb","no":"Innkjøp","fi":"Ostot","el":"Αγορές","cs":"Nákupy","ro":"Achiziții","hu":"Beszerzések","id":"Pembelian","sw":"Manunuzi","ln":"Basombi","uk":"Закупівлі"},
 "partners": {"en":"Customers & suppliers","fr":"Clients & fournisseurs","es":"Clientes y proveedores","de":"Kunden & Lieferanten","it":"Clienti e fornitori","pt":"Clientes e fornecedores","nl":"Klanten & leveranciers","ru":"Клиенты и поставщики","zh":"客户与供应商","ja":"顧客と仕入先","ko":"고객 및 공급업체","ar":"العملاء والموردون","hi":"ग्राहक और आपूर्तिकर्ता","tr":"Müşteriler ve tedarikçiler","pl":"Klienci i dostawcy","sv":"Kunder och leverantörer","da":"Kunder og leverandører","no":"Kunder og leverandører","fi":"Asiakkaat ja toimittajat","el":"Πελάτες & προμηθευτές","cs":"Zákazníci a dodavatelé","ro":"Clienți și furnizori","hu":"Vevők és beszállítók","id":"Pelanggan & pemasok","sw":"Wateja na wasambazaji","ln":"Bakeliya mpe bafourniseur","uk":"Клієнти та постачальники"},
 "reports": {"en":"Reports","fr":"Rapports","es":"Informes","de":"Berichte","it":"Report","pt":"Relatórios","nl":"Rapporten","ru":"Отчёты","zh":"报表","ja":"レポート","ko":"보고서","ar":"التقارير","hi":"रिपोर्ट","tr":"Raporlar","pl":"Raporty","sv":"Rapporter","da":"Rapporter","no":"Rapporter","fi":"Raportit","el":"Αναφορές","cs":"Reporty","ro":"Rapoarte","hu":"Jelentések","id":"Laporan","sw":"Ripoti","ln":"Rapports","uk":"Звіти"},
 "automations": {"en":"Automations","fr":"Automatisations","es":"Automatizaciones","de":"Automatisierung","it":"Automazioni","pt":"Automações","nl":"Automatisering","ru":"Автоматизация","zh":"自动化","ja":"自動化","ko":"자동화","ar":"الأتمتة","hi":"स्वचालन","tr":"Otomasyon","pl":"Automatyzacje","sv":"Automationer","da":"Automatisering","no":"Automatisering","fi":"Automaatiot","el":"Αυτοματισμοί","cs":"Automatizace","ro":"Automatizări","hu":"Automatizálás","id":"Otomatisasi","sw":"Kiotomatiki","ln":"Automatisations","uk":"Автоматизації"},
 "settings": {"en":"Settings","fr":"Paramètres","es":"Ajustes","de":"Einstellungen","it":"Impostazioni","pt":"Configurações","nl":"Instellingen","ru":"Настройки","zh":"设置","ja":"設定","ko":"설정","ar":"الإعدادات","hi":"सेटिंग्स","tr":"Ayarlar","pl":"Ustawienia","sv":"Inställningar","da":"Indstillinger","no":"Innstillinger","fi":"Asetukset","el":"Ρυθμίσεις","cs":"Nastavení","ro":"Setări","hu":"Beállítások","id":"Pengaturan","sw":"Mipangilio","ln":"Paramètres","uk":"Налаштування"},
 "about": {"en":"About","fr":"À propos","es":"Acerca de","de":"Über","it":"Info","pt":"Sobre","nl":"Over","ru":"О программе","zh":"关于","ja":"について","ko":"정보","ar":"حول","hi":"बारे में","tr":"Hakkında","pl":"O programie","sv":"Om","da":"Om","no":"Om","fi":"Tietoa","el":"Σχετικά","cs":"O aplikaci","ro":"Despre","hu":"Névjegy","id":"Tentang","sw":"Kuhusu","ln":"Na tina","uk":"Про програму"},
 "search": {"en":"Search…","fr":"Rechercher…","es":"Buscar…","de":"Suchen…","it":"Cerca…","pt":"Pesquisar…","nl":"Zoeken…","ru":"Поиск…","zh":"搜索…","ja":"検索…","ko":"검색…","ar":"بحث…","hi":"खोजें…","tr":"Ara…","pl":"Szukaj…","sv":"Sök…","da":"Søg…","no":"Søk…","fi":"Hae…","el":"Αναζήτηση…","cs":"Hledat…","ro":"Caută…","hu":"Keresés…","id":"Cari…","sw":"Tafuta…","ln":"Luka…","uk":"Пошук…"},
 "add": {"en":"Add","fr":"Ajouter","es":"Añadir","de":"Hinzufügen","it":"Aggiungi","pt":"Adicionar","nl":"Toevoegen","ru":"Добавить","zh":"添加","ja":"追加","ko":"추가","ar":"إضافة","hi":"जोड़ें","tr":"Ekle","pl":"Dodaj","sv":"Lägg till","da":"Tilføj","no":"Legg til","fi":"Lisää","el":"Προσθήκη","cs":"Přidat","ro":"Adaugă","hu":"Hozzáadás","id":"Tambah","sw":"Ongeza","ln":"Bakisa","uk":"Додати"},
 "edit": {"en":"Edit","fr":"Modifier","es":"Editar","de":"Bearbeiten","it":"Modifica","pt":"Editar","nl":"Bewerken","ru":"Изменить","zh":"编辑","ja":"編集","ko":"편집","ar":"تعديل","hi":"संपादित करें","tr":"Düzenle","pl":"Edytuj","sv":"Redigera","da":"Rediger","no":"Rediger","fi":"Muokkaa","el":"Επεξεργασία","cs":"Upravit","ro":"Editează","hu":"Szerkesztés","id":"Ubah","sw":"Hariri","ln":"Bongisa","uk":"Редагувати"},
 "delete": {"en":"Delete","fr":"Supprimer","es":"Eliminar","de":"Löschen","it":"Elimina","pt":"Excluir","nl":"Verwijderen","ru":"Удалить","zh":"删除","ja":"削除","ko":"삭제","ar":"حذف","hi":"हटाएं","tr":"Sil","pl":"Usuń","sv":"Ta bort","da":"Slet","no":"Slett","fi":"Poista","el":"Διαγραφή","cs":"Smazat","ro":"Șterge","hu":"Törlés","id":"Hapus","sw":"Futa","ln":"Longola","uk":"Видалити"},
 "save": {"en":"Save","fr":"Enregistrer","es":"Guardar","de":"Speichern","it":"Salva","pt":"Salvar","nl":"Opslaan","ru":"Сохранить","zh":"保存","ja":"保存","ko":"저장","ar":"حفظ","hi":"सहेजें","tr":"Kaydet","pl":"Zapisz","sv":"Spara","da":"Gem","no":"Lagre","fi":"Tallenna","el":"Αποθήκευση","cs":"Uložit","ro":"Salvează","hu":"Mentés","id":"Simpan","sw":"Hifadhi","ln":"Bomba","uk":"Зберегти"},
 "cancel": {"en":"Cancel","fr":"Annuler","es":"Cancelar","de":"Abbrechen","it":"Annulla","pt":"Cancelar","nl":"Annuleren","ru":"Отмена","zh":"取消","ja":"キャンセル","ko":"취소","ar":"إلغاء","hi":"रद्द करें","tr":"İptal","pl":"Anuluj","sv":"Avbryt","da":"Annuller","no":"Avbryt","fi":"Peruuta","el":"Ακύρωση","cs":"Zrušit","ro":"Anulează","hu":"Mégse","id":"Batal","sw":"Ghairi","ln":"Annuler","uk":"Скасувати"},
 "sku": {"en":"SKU","fr":"Référence","es":"Referencia","de":"Artikel-Nr.","it":"Codice","pt":"Referência","nl":"Artikelcode","ru":"Артикул","zh":"货号","ja":"品番","ko":"품번","ar":"المرجع","hi":"एसकेयू","tr":"Stok kodu","pl":"Indeks","sv":"Artikelnummer","da":"Varenummer","no":"Artikkelnr.","fi":"Tuotekoodi","el":"Κωδικός","cs":"Kód","ro":"Cod","hu":"Cikkszám","id":"SKU","sw":"SKU","ln":"Référence","uk":"Артикул"},
 "productName": {"en":"Name","fr":"Nom","es":"Nombre","de":"Name","it":"Nome","pt":"Nome","nl":"Naam","ru":"Название","zh":"名称","ja":"名前","ko":"이름","ar":"الاسم","hi":"नाम","tr":"Ad","pl":"Nazwa","sv":"Namn","da":"Navn","no":"Navn","fi":"Nimi","el":"Όνομα","cs":"Název","ro":"Nume","hu":"Név","id":"Nama","sw":"Jina","ln":"Nkombo","uk":"Назва"},
 "category": {"en":"Category","fr":"Catégorie","es":"Categoría","de":"Kategorie","it":"Categoria","pt":"Categoria","nl":"Categorie","ru":"Категория","zh":"类别","ja":"カテゴリ","ko":"카테고리","ar":"الفئة","hi":"श्रेणी","tr":"Kategori","pl":"Kategoria","sv":"Kategori","da":"Kategori","no":"Kategori","fi":"Luokka","el":"Κατηγορία","cs":"Kategorie","ro":"Categorie","hu":"Kategória","id":"Kategori","sw":"Kategoria","ln":"Catégorie","uk":"Категорія"},
 "quantity": {"en":"Quantity","fr":"Quantité","es":"Cantidad","de":"Menge","it":"Quantità","pt":"Quantidade","nl":"Aantal","ru":"Количество","zh":"数量","ja":"数量","ko":"수량","ar":"الكمية","hi":"मात्रा","tr":"Miktar","pl":"Ilość","sv":"Antal","da":"Antal","no":"Antall","fi":"Määrä","el":"Ποσότητα","cs":"Množství","ro":"Cantitate","hu":"Mennyiség","id":"Jumlah","sw":"Kiasi","ln":"Motango","uk":"Кількість"},
 "buyPrice": {"en":"Buy price","fr":"Prix d'achat","es":"Precio de compra","de":"Einkaufspreis","it":"Prezzo acquisto","pt":"Preço de compra","nl":"Inkoopprijs","ru":"Цена закупки","zh":"进价","ja":"仕入価格","ko":"매입가","ar":"سعر الشراء","hi":"खरीद मूल्य","tr":"Alış fiyatı","pl":"Cena zakupu","sv":"Inköpspris","da":"Købspris","no":"Innkjøpspris","fi":"Ostohinta","el":"Τιμή αγοράς","cs":"Nákupní cena","ro":"Preț achiziție","hu":"Beszerzési ár","id":"Harga beli","sw":"Bei ya kununua","ln":"Prix d'achat","uk":"Ціна закупівлі"},
 "sellPrice": {"en":"Sell price","fr":"Prix de vente","es":"Precio de venta","de":"Verkaufspreis","it":"Prezzo vendita","pt":"Preço de venda","nl":"Verkoopprijs","ru":"Цена продажи","zh":"售价","ja":"販売価格","ko":"판매가","ar":"سعر البيع","hi":"बिक्री मूल्य","tr":"Satış fiyatı","pl":"Cena sprzedaży","sv":"Försäljningspris","da":"Salgspris","no":"Salgspris","fi":"Myyntihinta","el":"Τιμή πώλησης","cs":"Prodejní cena","ro":"Preț vânzare","hu":"Eladási ár","id":"Harga jual","sw":"Bei ya kuuza","ln":"Prix de vente","uk":"Ціна продажу"},
 "minStock": {"en":"Min. stock","fr":"Stock mini","es":"Stock mínimo","de":"Mindestbestand","it":"Scorta minima","pt":"Estoque mín.","nl":"Min. voorraad","ru":"Мин. остаток","zh":"最低库存","ja":"最小在庫","ko":"최소 재고","ar":"الحد الأدنى","hi":"न्यूनतम स्टॉक","tr":"Min. stok","pl":"Stan min.","sv":"Minimilager","da":"Min. lager","no":"Min. lager","fi":"Minimivarasto","el":"Ελάχ. απόθεμα","cs":"Min. zásoba","ro":"Stoc min.","hu":"Min. készlet","id":"Stok min.","sw":"Stoki ya chini","ln":"Stock mini","uk":"Мін. запас"},
 "total": {"en":"Total","fr":"Total","es":"Total","de":"Gesamt","it":"Totale","pt":"Total","nl":"Totaal","ru":"Итого","zh":"合计","ja":"合計","ko":"합계","ar":"المجموع","hi":"कुल","tr":"Toplam","pl":"Razem","sv":"Totalt","da":"I alt","no":"Totalt","fi":"Yhteensä","el":"Σύνολο","cs":"Celkem","ro":"Total","hu":"Összesen","id":"Total","sw":"Jumla","ln":"Total","uk":"Разом"},
 "stockValue": {"en":"Stock value","fr":"Valeur du stock","es":"Valor del stock","de":"Bestandswert","it":"Valore magazzino","pt":"Valor do estoque","nl":"Voorraadwaarde","ru":"Стоимость склада","zh":"库存价值","ja":"在庫金額","ko":"재고 금액","ar":"قيمة المخزون","hi":"स्टॉक मूल्य","tr":"Stok değeri","pl":"Wartość magazynu","sv":"Lagervärde","da":"Lagerværdi","no":"Lagerverdi","fi":"Varaston arvo","el":"Αξία αποθέματος","cs":"Hodnota skladu","ro":"Valoarea stocului","hu":"Készletérték","id":"Nilai stok","sw":"Thamani ya stoki","ln":"Valeur ya stock","uk":"Вартість складу"},
 "lowStock": {"en":"Low stock","fr":"Stock bas","es":"Stock bajo","de":"Niedriger Bestand","it":"Scorte basse","pt":"Estoque baixo","nl":"Lage voorraad","ru":"Мало на складе","zh":"库存不足","ja":"在庫少","ko":"재고 부족","ar":"مخزون منخفض","hi":"कम स्टॉक","tr":"Düşük stok","pl":"Niski stan","sv":"Lågt lager","da":"Lav lager","no":"Lavt lager","fi":"Vähissä","el":"Χαμηλό απόθεμα","cs":"Nízká zásoba","ro":"Stoc scăzut","hu":"Alacsony készlet","id":"Stok menipis","sw":"Stoki haba","ln":"Stock muke","uk":"Малий запас"},
 "outOfStock": {"en":"Out of stock","fr":"Rupture","es":"Agotado","de":"Ausverkauft","it":"Esaurito","pt":"Esgotado","nl":"Niet op voorraad","ru":"Нет в наличии","zh":"缺货","ja":"在庫切れ","ko":"품절","ar":"نفد المخزون","hi":"स्टॉक खत्म","tr":"Tükendi","pl":"Brak towaru","sv":"Slut i lager","da":"Udsolgt","no":"Utsolgt","fi":"Loppu","el":"Εξαντλήθηκε","cs":"Vyprodáno","ro":"Stoc epuizat","hu":"Elfogyott","id":"Habis","sw":"Imeisha","ln":"Esili","uk":"Немає в наявності"},
 "newSale": {"en":"New sale","fr":"Nouvelle vente","es":"Nueva venta","de":"Neuer Verkauf","it":"Nuova vendita","pt":"Nova venda","nl":"Nieuwe verkoop","ru":"Новая продажа","zh":"新建销售","ja":"新規売上","ko":"새 판매","ar":"بيع جديد","hi":"नई बिक्री","tr":"Yeni satış","pl":"Nowa sprzedaż","sv":"Ny försäljning","da":"Nyt salg","no":"Nytt salg","fi":"Uusi myynti","el":"Νέα πώληση","cs":"Nový prodej","ro":"Vânzare nouă","hu":"Új eladás","id":"Penjualan baru","sw":"Mauzo mapya","ln":"Tekete ya sika","uk":"Новий продаж"},
 "newProduct": {"en":"New product","fr":"Nouveau produit","es":"Nuevo producto","de":"Neues Produkt","it":"Nuovo prodotto","pt":"Novo produto","nl":"Nieuw product","ru":"Новый товар","zh":"新建产品","ja":"新規商品","ko":"새 상품","ar":"منتج جديد","hi":"नया उत्पाद","tr":"Yeni ürün","pl":"Nowy produkt","sv":"Ny produkt","da":"Nyt produkt","no":"Nytt produkt","fi":"Uusi tuote","el":"Νέο προϊόν","cs":"Nový produkt","ro":"Produs nou","hu":"Új termék","id":"Produk baru","sw":"Bidhaa mpya","ln":"Produit ya sika","uk":"Новий товар"},
 "language": {"en":"Language","fr":"Langue","es":"Idioma","de":"Sprache","it":"Lingua","pt":"Idioma","nl":"Taal","ru":"Язык","zh":"语言","ja":"言語","ko":"언어","ar":"اللغة","hi":"भाषा","tr":"Dil","pl":"Język","sv":"Språk","da":"Sprog","no":"Språk","fi":"Kieli","el":"Γλώσσα","cs":"Jazyk","ro":"Limbă","hu":"Nyelv","id":"Bahasa","sw":"Lugha","ln":"Monoko","uk":"Мова"},
 "currency": {"en":"Currency","fr":"Devise","es":"Moneda","de":"Währung","it":"Valuta","pt":"Moeda","nl":"Valuta","ru":"Валюта","zh":"货币","ja":"通貨","ko":"통화","ar":"العملة","hi":"मुद्रा","tr":"Para birimi","pl":"Waluta","sv":"Valuta","da":"Valuta","no":"Valuta","fi":"Valuutta","el":"Νόμισμα","cs":"Měna","ro":"Monedă","hu":"Pénznem","id":"Mata uang","sw":"Sarafu","ln":"Mbongo","uk":"Валюта"},
 "theme": {"en":"Theme","fr":"Thème","es":"Tema","de":"Design","it":"Tema","pt":"Tema","nl":"Thema","ru":"Тема","zh":"主题","ja":"テーマ","ko":"테마","ar":"المظهر","hi":"थीम","tr":"Tema","pl":"Motyw","sv":"Tema","da":"Tema","no":"Tema","fi":"Teema","el":"Θέμα","cs":"Motiv","ro":"Temă","hu":"Téma","id":"Tema","sw":"Mandhari","ln":"Thème","uk":"Тема"},
 "close": {"en":"Close","fr":"Fermer","es":"Cerrar","de":"Schließen","it":"Chiudi","pt":"Fechar","nl":"Sluiten","ru":"Закрыть","zh":"关闭","ja":"閉じる","ko":"닫기","ar":"إغلاق","hi":"बंद करें","tr":"Kapat","pl":"Zamknij","sv":"Stäng","da":"Luk","no":"Lukk","fi":"Sulje","el":"Κλείσιμο","cs":"Zavřít","ro":"Închide","hu":"Bezárás","id":"Tutup","sw":"Funga","ln":"Kanga","uk":"Закрити"},
}

LANGS = ["en","fr","es","de","it","pt","nl","ru","zh","ja","ko","ar","hi","tr","pl","sv","da","no","fi","el","cs","ro","hu","id","sw","ln","uk"]

os.makedirs(ARB_DIR, exist_ok=True)
for lang in LANGS:
    data = {"@@locale": lang}
    for key, vals in T.items():
        data[key] = vals.get(lang, vals["en"])
    with open(os.path.join(ARB_DIR, f"app_{lang}.arb"), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# Dart file
lines = []
lines.append("import 'package:flutter/material.dart';")
lines.append("")
lines.append("/// Traductions embarquees (27 langues). Repli automatique sur l'anglais.")
lines.append("class AppLocalizations {")
lines.append("  final Locale locale;")
lines.append("  const AppLocalizations(this.locale);")
lines.append("")
lines.append("  static const supportedLocales = [")
for lang in LANGS:
    lines.append(f"    Locale('{lang}'),")
lines.append("  ];")
lines.append("")
lines.append("  static AppLocalizations of(BuildContext context) =>")
lines.append("      Localizations.of<AppLocalizations>(context, AppLocalizations) ??")
lines.append("          const AppLocalizations(Locale('en'));")
lines.append("")
lines.append("  static const _v = <String, Map<String, String>>{")
for key, vals in T.items():
    def dq(s):
        s = s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
        return f"'{s}'"
    inner = ", ".join(f"'{l}': {dq(vals.get(l, vals['en']))}" for l in LANGS)
    lines.append(f"    '{key}': {{{inner}}},")
lines.append("  };")
lines.append("")
lines.append("  String _t(String key) =>")
lines.append("      _v[key]?[locale.languageCode] ?? _v[key]?['en'] ?? key;")
lines.append("")
for key in T.keys():
    lines.append(f"  String get {key} => _t('{key}');")
lines.append("}")
lines.append("")
lines.append("class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {")
lines.append("  const AppLocalizationsDelegate();")
lines.append("  @override")
lines.append("  bool isSupported(Locale locale) =>")
lines.append(f"      {LANGS}.contains(locale.languageCode);")
lines.append("  @override")
lines.append("  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);")
lines.append("  @override")
lines.append("  bool shouldReload(AppLocalizationsDelegate old) => false;")
lines.append("}")
lines.append("")

with open(OUT_DART, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print(f"OK: {OUT_DART} + {len(LANGS)} arb")
