import 'package:vixrex/models/store_product.dart';

/// #262: var olan ürünlerde TOPLU alan değişikliği (fiyat/stok/kategori/
/// görünürlük). `bulk_product_upload_service.dart`in aksine bu servis yeni
/// ürün İÇE AKTARMAZ — zaten var olan ürünleri düzenler.
///
/// Kasıtlı olarak SAF (pure): hiçbir Supabase çağrısı yapmaz, yalnızca yeni
/// [Product] listesi hesaplar. Uzağa yazma, çağıranın (product_management_
/// sheet.dart) zaten sahip olduğu `_persist()` yoluyla olur — böylece bu
/// servis controller'a veya RPC'ye bağımlı olmadan test edilebilir.
enum PriceAdjustMode {
  setExact,
  increasePercent,
  decreasePercent,
  increaseAmount,
  decreaseAmount,
}

/// Fiyat ayarlamasının sonucu: bazı ürünlerin fiyat metninden sayısal bir
/// değer ayıklanamayabilir (ör. "Fiyat için mesaj atın") — bunlar
/// SESSİZCE bozulmaz, [skipped] listesinde çağırana bildirilir.
class BulkPriceAdjustResult {
  const BulkPriceAdjustResult({required this.updated, required this.skipped});

  final List<Product> updated;
  final List<Product> skipped;
}

class BulkProductFieldUpdateService {
  const BulkProductFieldUpdateService();

  /// Fiyat metninden ilk sayısal değeri ayıklar — TR ondalık ayracı (virgül)
  /// ve binlik nokta desteklenir. `product_catalog_sync_service.dart`taki
  /// `_parsePriceAmount` ile aynı ayrıştırma kuralı (bilerek birebir aynı —
  /// iki yerde farklı davranan bir sayı ayrıştırıcı, tutarsız yuvarlama/
  /// biçimlendirme riski doğururdu).
  double? parsePriceAmount(String raw) {
    var cleaned = raw.trim().replaceAll(RegExp(r'[^\d,.]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (cleaned.contains(',')) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned);
  }

  /// Yeni tutarı TR biçiminde ("1.234,56 TL") döndürür. Orijinal metindeki
  /// para birimi/etiket korunmaz — toplu işlemde her ürünün farklı bir sonek
  /// taşıyabilmesi (ör. "750 TL", "750TL/adet") güvenle ayrıştırılamaz;
  /// bunun yerine tek, tutarlı bir biçim kullanılır.
  String formatPriceAmount(double amount) {
    final rounded = double.parse(amount.toStringAsFixed(2));
    final wholePart = rounded.truncate();
    final fractionPart = ((rounded - wholePart) * 100).round().abs();
    final wholeStr = wholePart.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    final sign = rounded < 0 ? '-' : '';
    return '$sign$wholeStr,${fractionPart.toString().padLeft(2, '0')} TL';
  }

  /// Seçili ürünlerin fiyatına [mode]e göre [value] uygular. Fiyatı sayısal
  /// olarak ayrıştırılamayan ürünler DEĞİŞTİRİLMEZ, [BulkPriceAdjustResult
  /// .skipped]e eklenir.
  BulkPriceAdjustResult applyPriceAdjustment({
    required List<Product> products,
    required PriceAdjustMode mode,
    required double value,
  }) {
    final updated = <Product>[];
    final skipped = <Product>[];

    for (final product in products) {
      if (mode == PriceAdjustMode.setExact) {
        updated.add(product.copyWith(price: formatPriceAmount(value)));
        continue;
      }

      final current = parsePriceAmount(product.price);
      if (current == null) {
        skipped.add(product);
        continue;
      }

      final next = switch (mode) {
        PriceAdjustMode.increasePercent => current * (1 + value / 100),
        PriceAdjustMode.decreasePercent => current * (1 - value / 100),
        PriceAdjustMode.increaseAmount => current + value,
        PriceAdjustMode.decreaseAmount => current - value,
        PriceAdjustMode.setExact => value,
      };
      // Negatif fiyat anlamsız — 0'a kırpılır, ürün yine de güncellenir
      // (esnaf "%100 indirim" gibi uç bir değer denerse sessizce atlamak
      // yerine 0 TL'ye indirmek daha öngörülebilir).
      updated.add(
        product.copyWith(price: formatPriceAmount(next < 0 ? 0 : next)),
      );
    }

    return BulkPriceAdjustResult(updated: updated, skipped: skipped);
  }

  List<Product> applyStockStatus(List<Product> products, String stockStatus) {
    return products.map((p) => p.copyWith(stockStatus: stockStatus)).toList();
  }

  List<Product> applyCategory(
    List<Product> products,
    ProductCategory category,
  ) {
    return products
        .map(
          (p) => p.copyWith(categoryId: category.id, category: category.name),
        )
        .toList();
  }

  List<Product> applyVisibility(List<Product> products, bool isVisible) {
    return products.map((p) => p.copyWith(isVisible: isVisible)).toList();
  }
}
