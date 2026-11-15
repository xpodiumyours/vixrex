import 'package:flutter/foundation.dart';

String _cleanText(Object? value, [int max = 180]) {
  final raw =
      (value ?? '')
          .toString()
          .replaceAll(RegExp(r'[\u0000-\u001F\u007F\u2028\u2029]+'), ' ')
          .trim();
  if (raw.length <= max) return raw;
  return raw.substring(0, max);
}

int? _normalizeMaxQuantity(Object? value) {
  if (value == null || value == '') return null;
  final parsed =
      (value is num) ? value.toDouble() : double.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite) return null;
  return parsed.round().clamp(0, 999);
}

double? _normalizePriceAmount(Object? value) {
  if (value == null) return null;
  final parsed =
      (value is num) ? value.toDouble() : double.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite || parsed <= 0) return null;
  return parsed;
}

int _clampQuantity(int value, int? maxQuantity) {
  var normalized = value < 1 ? 1 : value;
  if (normalized > 999) normalized = 999;
  if (maxQuantity != null && maxQuantity > 0 && normalized > maxQuantity) {
    normalized = maxQuantity;
  }
  if (maxQuantity == 0) return 0;
  return normalized < 1 ? 1 : normalized;
}

class VitrinCartItem {
  const VitrinCartItem({
    required this.productSlug,
    required this.productName,
    required this.variantKey,
    required this.variantText,
    required this.priceText,
    required this.priceAmount,
    required this.imageUrl,
    required this.maxQuantity,
    required this.quantity,
  });

  final String productSlug;
  final String productName;
  final String variantKey;
  final String variantText;
  final String priceText;
  final double? priceAmount;
  final String imageUrl;
  final int? maxQuantity;
  final int quantity;

  VitrinCartItem copyWith({int? quantity}) => VitrinCartItem(
    productSlug: productSlug,
    productName: productName,
    variantKey: variantKey,
    variantText: variantText,
    priceText: priceText,
    priceAmount: priceAmount,
    imageUrl: imageUrl,
    maxQuantity: maxQuantity,
    quantity: quantity ?? this.quantity,
  );

  VitrinCartItem normalized() => VitrinCartItem(
    productSlug: _cleanText(productSlug, 120),
    productName: _cleanText(productName, 180),
    variantKey: _cleanText(variantKey, 180),
    variantText: _cleanText(variantText, 180),
    priceText: _cleanText(priceText, 80),
    priceAmount: _normalizePriceAmount(priceAmount),
    imageUrl: imageUrl.trim().isEmpty ? '' : _cleanText(imageUrl, 500),
    maxQuantity: _normalizeMaxQuantity(maxQuantity),
    quantity: _clampQuantity(quantity, _normalizeMaxQuantity(maxQuantity)),
  );
}

class VitrinCartService extends ChangeNotifier {
  VitrinCartService._();
  static final VitrinCartService instance = VitrinCartService._();

  final Map<String, Map<String, VitrinCartItem>> _itemsByStore = {};
  String _activeStoreSlug = '';

  Map<String, VitrinCartItem> _itemsFor(String storeSlug) {
    final key = _cleanText(storeSlug, 120);
    return _itemsByStore.putIfAbsent(key, () => {});
  }

  Map<String, VitrinCartItem> get _items => _itemsFor(_activeStoreSlug);

  void setActiveStore(String storeSlug) {
    final normalized = _cleanText(storeSlug, 120);
    if (normalized.isEmpty || normalized == _activeStoreSlug) return;
    _activeStoreSlug = normalized;
    notifyListeners();
  }

  List<VitrinCartItem> get items => _items.values.toList(growable: false);

  int totalQuantity() =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  void add(VitrinCartItem item) {
    final normalized = item.normalized();
    if (normalized.maxQuantity == 0) return;
    if (normalized.productSlug.isEmpty || normalized.productName.isEmpty) {
      return;
    }
    final key = '${normalized.productSlug}::${normalized.variantKey}';
    final existing = _items[key];
    if (existing == null) {
      _items[key] = normalized;
    } else {
      final next = existing.quantity + normalized.quantity;
      final capped =
          (normalized.maxQuantity != null && next > normalized.maxQuantity!)
              ? normalized.maxQuantity!
              : next;
      _items[key] = existing.copyWith(
        quantity: _clampQuantity(capped, normalized.maxQuantity),
      );
    }
    notifyListeners();
  }

  void setQuantity(String productSlug, String variantKey, int quantity) {
    final key =
        '${_cleanText(productSlug, 120)}::${_cleanText(variantKey, 180)}';
    final existing = _items[key];
    if (existing == null) return;
    if (quantity <= 0 || existing.maxQuantity == 0) {
      _items.remove(key);
      notifyListeners();
      return;
    }
    _items[key] = existing.copyWith(
      quantity: _clampQuantity(quantity, existing.maxQuantity),
    );
    notifyListeners();
  }

  void remove(String productSlug, String variantKey) {
    _items.remove(
      '${_cleanText(productSlug, 120)}::${_cleanText(variantKey, 180)}',
    );
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  String buildWhatsAppText({
    required String storeName,
    required String storeSlug,
  }) {
    final orderItems = _itemsFor(storeSlug).values;
    final cleanStore = _cleanText(storeName, 120);
    final codeSource =
        _cleanText(
          storeSlug,
          120,
        ).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final shortCode =
        codeSource.length >= 4
            ? codeSource.substring(0, 4)
            : DateTime.now().millisecondsSinceEpoch
                .toRadixString(36)
                .toUpperCase()
                .padLeft(4, '0')
                .substring(0, 4);
    final lines =
        orderItems.map((item) {
          final ad = _cleanText(item.productName, 180);
          final variants = _cleanText(item.variantText, 180);
          final fiyat = _cleanText(item.priceText, 80);
          final variant = variants.isNotEmpty ? ' - $variants' : '';
          final price = fiyat.isNotEmpty ? ' - $fiyat' : '';
          return '- ${item.quantity} x $ad$variant$price';
        }).toList();
    final totalQty = orderItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    double? totalAmount;
    var unpricedCount = 0;
    for (final item in orderItems) {
      final amount = item.priceAmount;
      if (amount == null) {
        unpricedCount++;
        continue;
      }
      totalAmount = (totalAmount ?? 0) + amount * item.quantity;
    }
    final buffer = StringBuffer();
    buffer.writeln('Siparis no: #VX-$shortCode');
    buffer.writeln(
      'Merhaba, $cleanStore vitrininizden siparis vermek istiyorum:',
    );
    buffer.writeln();
    for (final line in lines) {
      buffer.writeln(line);
    }
    buffer.writeln();
    buffer.writeln('Toplam urun adedi: $totalQty');
    if (totalAmount != null) {
      buffer.writeln(
        'Toplam tutar: ${totalAmount.toStringAsFixed(2)} TL${unpricedCount > 0 ? ' (+ $unpricedCount urun icin fiyat sorulacak)' : ''}',
      );
    } else if (unpricedCount > 0) {
      buffer.writeln(
        'Toplam tutar: ($unpricedCount urun icin fiyat sorulacak)',
      );
    }
    buffer.writeln('Uygunluk ve teslimat bilgisini paylasabilir misiniz?');
    buffer.writeln();
    buffer.writeln(
      '!! Bu siparis ozeti vitrinden otomatik derlenmistir. Fiyat, stok ve teslimat isletme teyidinden sonra kesinlesir.',
    );
    return buffer.toString();
  }
}
