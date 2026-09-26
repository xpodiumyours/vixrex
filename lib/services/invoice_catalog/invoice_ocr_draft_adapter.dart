import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/invoice_product_draft.dart';

class InvoiceOcrDraftAdapter {
  const InvoiceOcrDraftAdapter();

  List<InvoiceProductDraft> fromProducts(List<DetectedProduct> products) =>
      products.map(_fromProduct).toList(growable: false);

  InvoiceProductDraft _fromProduct(DetectedProduct product) {
    final now = DateTime.now().toUtc();
    final strength =
        product.confidence >= 0.85
            ? EvidenceStrength.strong
            : product.confidence >= 0.60
            ? EvidenceStrength.partial
            : EvidenceStrength.weak;

    EvidenceValue<String>? text(String? value) {
      final clean = value?.trim() ?? '';
      if (clean.isEmpty) return null;
      return EvidenceValue<String>(
        value: clean,
        sourceType: EvidenceSourceType.invoice,
        sourceReference: product.id,
        strength: strength,
        verifiedAt: now,
      );
    }

    EvidenceValue<num>? number(num? value) {
      if (value == null) return null;
      return EvidenceValue<num>(
        value: value,
        sourceType: EvidenceSourceType.invoice,
        sourceReference: product.id,
        strength: strength,
        verifiedAt: now,
      );
    }

    final hasIdentity =
        (product.barcode ?? '').trim().isNotEmpty ||
        (product.sku ?? '').trim().isNotEmpty;

    return InvoiceProductDraft(
      id: product.id,
      rawSourceLine: [
        if ((product.sku ?? '').trim().isNotEmpty) product.sku!.trim(),
        product.name.trim(),
        if ((product.barcode ?? '').trim().isNotEmpty) product.barcode!.trim(),
      ].join(' '),
      rawName: text(product.name),
      gtinBarcode: text(product.barcode),
      modelCode: text(product.sku),
      brand: text(product.brand),
      variant: text(product.variant),
      size: text(product.size),
      quantity: number(product.documentQuantity),
      purchaseUnitPrice: number(product.purchaseUnitPrice),
      purchaseLineTotal: number(product.lineTotal),
      currency: EvidenceValue<String>(
        value: 'TRY',
        sourceType: EvidenceSourceType.invoice,
        sourceReference: product.id,
        strength: EvidenceStrength.strong,
        verifiedAt: now,
      ),
      supplierIdentityStrength: EvidenceStrength.weak,
      productIdentityStrength:
          hasIdentity ? EvidenceStrength.partial : EvidenceStrength.weak,
      rightsStatus: RightsStatus.unknown,
      isVisible: false,
    );
  }
}
