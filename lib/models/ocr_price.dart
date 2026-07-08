/// OCR ile tespit edilen fiyat.
class OcrPrice {
  final String rawText;
  final double amount;
  final String? currency;
  final int lineNumber;
  final int blockIndex;

  const OcrPrice({
    required this.rawText,
    required this.amount,
    this.currency,
    required this.lineNumber,
    required this.blockIndex,
  });

  String get formatted => '${amount.toStringAsFixed(2)} ₺';

  @override
  String toString() => '$formatted (ham: $rawText)';
}
