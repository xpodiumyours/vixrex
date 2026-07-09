/// OCR ile tespit edilen fiyat.
class OcrPrice {
  final String rawText;
  final double amount;
  final String? currency;
  final int lineNumber;
  final int blockIndex;
  final double confidence;

  const OcrPrice({
    required this.rawText,
    required this.amount,
    this.currency,
    required this.lineNumber,
    required this.blockIndex,
    this.confidence = 0.5,
  });

  String get formatted => '${amount.toStringAsFixed(2)} ₺';

  OcrPrice copyWith({
    String? rawText,
    double? amount,
    String? currency,
    int? lineNumber,
    int? blockIndex,
    double? confidence,
  }) {
    return OcrPrice(
      rawText: rawText ?? this.rawText,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      lineNumber: lineNumber ?? this.lineNumber,
      blockIndex: blockIndex ?? this.blockIndex,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() => '$formatted (ham: $rawText, conf: $confidence)';
}
