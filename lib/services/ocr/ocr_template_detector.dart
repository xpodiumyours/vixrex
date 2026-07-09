/// Fatura/belge şablonu tespit edici.
///
/// Ham OCR metninden fatura tipini tespit eder.
class OcrTemplateDetector {
  const OcrTemplateDetector();

  /// Fatura tipini tespit et.
  InvoiceTemplate detectTemplate(String rawText) {
    final lower = rawText.toLowerCase();

    // Market/shopping center
    if (lower.contains('migros')) return InvoiceTemplate.migros;
    if (lower.contains('carrefour')) return InvoiceTemplate.carrefourSA;
    if (lower.contains('bim') || lower.contains('bİM')) return InvoiceTemplate.bim;
    if (lower.contains('a101')) return InvoiceTemplate.a101;
    if (lower.contains('şok') || lower.contains('sok')) return InvoiceTemplate.sok;
    if (lower.contains('market') || lower.contains('bakkal')) return InvoiceTemplate.market;

    // Tekstil/toptan
    if (lower.contains('satış teklif') || lower.contains('irsaliye')) return InvoiceTemplate.textileWholesale;
    if (lower.contains('fatura') && (lower.contains('stok') || lower.contains('model'))) return InvoiceTemplate.textileWholesale;

    // Elektronik
    if (lower.contains('teknoloji') || lower.contains('elektronik') || lower.contains('bilgisayar')) return InvoiceTemplate.electronics;

    // Restoran/kafe
    if (lower.contains('adisyon') || lower.contains('hesap') || lower.contains('garson')) return InvoiceTemplate.restaurant;

    return InvoiceTemplate.generic;
  }

  /// Şablona özel parsing stratejisi döndür.
  ParsingStrategy getStrategy(InvoiceTemplate template) {
    switch (template) {
      case InvoiceTemplate.migros:
      case InvoiceTemplate.carrefourSA:
      case InvoiceTemplate.bim:
      case InvoiceTemplate.a101:
      case InvoiceTemplate.sok:
        return ParsingStrategy(
          hasSeparator: true,
          hasUnitPrice: true,
          hasQuantity: true,
          priceFormat: 'decimal', // 27.50
        );

      case InvoiceTemplate.textileWholesale:
        return ParsingStrategy(
          hasSeparator: true,
          hasUnitPrice: true,
          hasQuantity: true,
          priceFormat: 'full', // 75.0000 TL
        );

      case InvoiceTemplate.electronics:
        return ParsingStrategy(
          hasSeparator: false,
          hasUnitPrice: true,
          hasQuantity: true,
          priceFormat: 'thousands', // 12,999.00
        );

      case InvoiceTemplate.restaurant:
        return ParsingStrategy(
          hasSeparator: false,
          hasUnitPrice: true,
          hasQuantity: false,
          priceFormat: 'decimal',
        );

      case InvoiceTemplate.market:
      case InvoiceTemplate.generic:
        return ParsingStrategy(
          hasSeparator: true,
          hasUnitPrice: false,
          hasQuantity: false,
          priceFormat: 'decimal',
        );
    }
  }
}

/// Fatura tipi.
enum InvoiceTemplate {
  migros,
  carrefourSA,
  bim,
  a101,
  sok,
  market,
  textileWholesale,
  electronics,
  restaurant,
  generic,
}

/// Parsing stratejisi.
class ParsingStrategy {
  final bool hasSeparator;
  final bool hasUnitPrice;
  final bool hasQuantity;
  final String priceFormat;

  const ParsingStrategy({
    required this.hasSeparator,
    required this.hasUnitPrice,
    required this.hasQuantity,
    required this.priceFormat,
  });
}
