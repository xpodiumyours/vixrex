import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/models/invoice_product_draft.dart';

/// Fatura satırlarını GERÇEK üretici kataloğuyla eşleştirir.
///
/// [InvoiceDraftTraceResolver] (product_database üzerinden bulanık ad
/// eşleştirmesi) ile KARIŞTIRILMASIN: o yerel, zayıf bir sözlüktür ve kanıtı
/// hiçbir zaman "strong" seviyesine çıkaramaz. Bu sınıf, Vixrex'in tek gerçek
/// üretici havuzuna (public_web/src/lib/ureticiKatalog.ts,
/// `/api/fatura-eslestir`) bağlanır — telefon, tarayıcı veya Başak hangi
/// kaynaktan satır üretirse üretsin AYNI eşleştirme sonucunu alır.
///
/// Ağ hatasında satırı OLDUĞU GİBİ bırakır (zayıf kalır) — asla tahminle
/// "strong" işaretlemez. Çevrimdışıyken esnaf yine de satırları görür,
/// yalnız otomatik onaya giremezler.
class CatalogInvoiceTraceResolver {
  final String storeSlug;
  final String editToken;
  final http.Client? _httpClient;
  final String? _originOverride;

  const CatalogInvoiceTraceResolver({
    required this.storeSlug,
    required this.editToken,
    http.Client? httpClient,
    String? originOverride,
  }) : _httpClient = httpClient,
       _originOverride = originOverride;

  Future<List<InvoiceProductDraft>> resolve(
    List<InvoiceProductDraft> drafts,
  ) async {
    if (drafts.isEmpty) return drafts;
    if (storeSlug.trim().isEmpty || editToken.trim().isEmpty) return drafts;

    final satirlar = drafts
        .map(
          (draft) => {
            'model': draft.modelCode?.value ?? draft.supplierSku?.value ?? '',
            'barkod': draft.gtinBarcode?.value ?? '',
            'ad': draft.rawName?.value ?? '',
            'varyant': draft.variant?.value ?? '',
            'beden': draft.size?.value ?? '',
            'adet': draft.quantity?.value,
            'alisBirimFiyat': draft.purchaseUnitPrice?.value,
            'satirToplam': draft.purchaseLineTotal?.value,
            'guven':
                draft.productIdentityStrength == EvidenceStrength.strong
                    ? 0.9
                    : draft.productIdentityStrength == EvidenceStrength.partial
                    ? 0.6
                    : 0.3,
          },
        )
        .toList(growable: false);

    final ownsClient = _httpClient == null;
    final client = _httpClient ?? http.Client();

    try {
      final endpoint = _buildEndpoint('/api/fatura-eslestir');
      final response = await client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'slug': storeSlug,
              'editToken': editToken,
              'satirlar': satirlar,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return drafts; // sunucu reddetti — satırlar zayıf haliyle kalır
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['satirlar'] is! List) return drafts;

      final eslesenler = List<Map>.from(decoded['satirlar'] as List);
      if (eslesenler.length != drafts.length) return drafts;

      return List<InvoiceProductDraft>.generate(
        drafts.length,
        (i) => _uygula(drafts[i], eslesenler[i]),
      );
    } catch (_) {
      return drafts; // ağ/format hatası — tahmin etme, olduğu gibi bırak
    } finally {
      if (ownsClient) client.close();
    }
  }

  InvoiceProductDraft _uygula(InvoiceProductDraft draft, Map ham) {
    final katalog = ham['katalog'];
    if (katalog is! Map) return draft; // eşleşme yok — kanıt zayıf kalır

    final now = DateTime.now().toUtc();
    final kaynak = (katalog['kaynak'] ?? '').toString();
    final firma = (katalog['firma'] ?? '').toString();
    final izinDurumu = (katalog['izinDurumu'] ?? 'yok').toString();

    EvidenceValue<String>? metin(String? deger, EvidenceSourceType tur) {
      final temiz = deger?.trim() ?? '';
      if (temiz.isEmpty) return null;
      return EvidenceValue<String>(
        value: temiz,
        sourceType: tur,
        sourceReference: kaynak.isNotEmpty ? kaynak : firma,
        strength: EvidenceStrength.strong,
        verifiedAt: now,
      );
    }

    final gorseller =
        (katalog['gorseller'] is List)
            ? List<String>.from(
              (katalog['gorseller'] as List).map((g) => g.toString()),
            )
            : const <String>[];

    final rightsStatus = switch (izinDurumu) {
      'var' => RightsStatus.verifiedSupplierPermission,
      _ => RightsStatus.unknown, // "bekliyor" / "yok" — görsel kullanılamaz
    };

    return draft.copyWith(
      normalizedName: metin(
        katalog['resmiAd']?.toString(),
        EvidenceSourceType.officialProductPage,
      ),
      brand: metin(
        katalog['marka']?.toString(),
        EvidenceSourceType.officialProductPage,
      ),
      canonicalProductId: metin(firma, EvidenceSourceType.officialProductPage),
      canonicalProductUrl: metin(
        kaynak,
        EvidenceSourceType.officialProductPage,
      ),
      // Gerçek üretici kataloğunda bulundu: hem ürün hem tedarikçi kimliği
      // artık tahmin değil, doğrulanmış kayıt.
      productIdentityStrength: EvidenceStrength.strong,
      supplierIdentityStrength: EvidenceStrength.strong,
      rightsStatus: rightsStatus,
      imageCandidates: [
        for (final url in gorseller)
          InvoiceImageCandidate(
            url: url,
            sourceType: EvidenceSourceType.officialProductPage,
            sourceReference: kaynak.isNotEmpty ? kaynak : firma,
            strength: EvidenceStrength.strong,
            rightsStatus: rightsStatus,
            selected: true,
          ),
      ],
    );
  }

  Uri _buildEndpoint(String path) {
    final link = PublicSiteConfig.buildPublicLink(
      path,
      configuredOriginOverride: _originOverride,
    );
    return Uri.parse(link);
  }
}
