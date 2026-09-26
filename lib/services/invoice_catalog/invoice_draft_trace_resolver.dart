import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/services/excel/product_database.dart';

class InvoiceDraftTraceResolver {
  final ProductDatabase _database;

  const InvoiceDraftTraceResolver({ProductDatabase? database})
    : _database = database ?? const ProductDatabase();

  Future<List<InvoiceProductDraft>> resolve(
    List<InvoiceProductDraft> drafts,
  ) async {
    final output = <InvoiceProductDraft>[];
    for (final draft in drafts) {
      final query = [
        draft.modelCode?.value?.trim() ?? '',
        draft.gtinBarcode?.value?.trim() ?? '',
        draft.rawName?.value?.trim() ?? '',
      ].where((value) => value.isNotEmpty).join(' ');

      if (query.isEmpty) {
        output.add(draft);
        continue;
      }

      try {
        final result = await _database.findBestMatch(query);
        final match = result.isSuccess ? result.data : null;
        if (match == null) {
          output.add(draft);
          continue;
        }

        final now = DateTime.now().toUtc();
        final ref = 'product_database:${match.id}';
        EvidenceValue<String>? ev(String value) {
          final clean = value.trim();
          if (clean.isEmpty) return null;
          return EvidenceValue<String>(
            value: clean,
            sourceType: EvidenceSourceType.vixrexProductDatabase,
            sourceReference: ref,
            strength: EvidenceStrength.partial,
            verifiedAt: now,
          );
        }

        output.add(
          draft.copyWith(
            normalizedName: ev(match.urunAdi),
            brand: ev(match.marka),
            canonicalProductId: ev(match.id),
            productIdentityStrength: EvidenceStrength.partial,
          ),
        );
      } catch (_) {
        output.add(draft);
      }
    }
    return output;
  }
}
