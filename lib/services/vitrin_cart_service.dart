import 'package:flutter/foundation.dart';

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
}

class VitrinCartService extends ChangeNotifier {
  VitrinCartService._();
  static final VitrinCartService instance = VitrinCartService._();

  final Map<String, VitrinCartItem> _items = {};

  List<VitrinCartItem> get items => _items.values.toList(growable: false);

  int totalQuantity() =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  void add(VitrinCartItem item) {
    final key = '${item.productSlug}::${item.variantKey}';
    final existing = _items[key];
    if (existing == null) {
      _items[key] = item;
    } else {
      final next = existing.quantity + item.quantity;
      final capped =
          (item.maxQuantity != null && next > item.maxQuantity!)
              ? item.maxQuantity!
              : next;
      _items[key] = existing.copyWith(quantity: capped.clamp(1, 10));
    }
    notifyListeners();
  }

  void setQuantity(String productSlug, String variantKey, int quantity) {
    final key = '$productSlug::$variantKey';
    final existing = _items[key];
    if (existing == null) return;
    if (quantity <= 0) {
      _items.remove(key);
    } else {
      final capped = quantity.clamp(1, 10);
      _items[key] = existing.copyWith(quantity: capped);
    }
    notifyListeners();
  }

  void remove(String productSlug, String variantKey) {
    _items.remove('$productSlug::$variantKey');
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
    final buffer = StringBuffer();
    buffer.writeln('Sipariş no: #VX-${storeSlug.toUpperCase()}');
    buffer.writeln('Mağaza: $storeName');
    buffer.writeln('---');
    for (final item in _items.values) {
      buffer.writeln(
        '${item.productName} x${item.quantity} - ${item.priceText}',
      );
      if (item.variantText.isNotEmpty) {
        buffer.writeln('  Seçenek: ${item.variantText}');
      }
    }
    final total = _items.values.fold<double>(
      0,
      (sum, item) => sum + ((item.priceAmount ?? 0) * item.quantity),
    );
    buffer.writeln('Toplam: ${total.toStringAsFixed(2)}');
    buffer.writeln('Fiyat/stok/teslimat işletme teyidinden sonra kesinleşir.');
    return buffer.toString();
  }
}
