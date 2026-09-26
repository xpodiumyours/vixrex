import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/utils/failure.dart';
import 'package:vixrex/models/detected_product.dart';
import 'package:vixrex/models/invoice_product_draft.dart';
import 'package:vixrex/models/ocr_catalog_result.dart';

/// Vixrex'in TEK fatura okuma ucunu (`/api/fatura-oku`) çağırır.
///
/// KASITLI OLARAK cihaz üstü OCR (Google ML Kit) veya yerel fatura satırı
/// ayrıştırıcısı (InvoiceRowParser) KULLANMAZ. Fotoğraf doğrudan sunucuya
/// gider; okuma (Kilo, ücretsiz) ve katalog eşleştirme orada, web'in
/// kullandığı AYNI kodla yapılır.
///
/// 2026-09-26 mimari düzeltmesi: önceden telefon ve web iki ayrı "okuma
/// beyni" kullanıyordu (telefon: 24 dosyalık yerel zincir; web: anahtarsız
/// çalışmayan bir OpenAI ucu). Artık ikisi de bu tek servisten geçer.
class FaturaOkuServisi {
  final http.Client? _httpClient;
  final String? _originOverride;

  const FaturaOkuServisi({http.Client? httpClient, String? originOverride})
    : _httpClient = httpClient,
      _originOverride = originOverride;

  Future<Result<OcrCatalogResult>> oku({
    required List<int> imageBytes,
    required String storeSlug,
    required String editToken,
    String dosyaAdi = 'fatura.jpg',
  }) async {
    if (storeSlug.trim().isEmpty || editToken.trim().isEmpty) {
      return Result.failure(
        Failure('Vitrin henüz yayınlanmamış. Önce vitrinini yayınla.'),
      );
    }

    final ownsClient = _httpClient == null;
    final client = _httpClient ?? http.Client();

    try {
      final endpoint = _buildEndpoint('/api/fatura-oku');
      final istek =
          http.MultipartRequest('POST', endpoint)
            ..fields['slug'] = storeSlug
            ..fields['editToken'] = editToken
            ..files.add(
              http.MultipartFile.fromBytes(
                'dosya',
                imageBytes,
                filename: dosyaAdi,
              ),
            );

      final yanit = await client
          .send(istek)
          .timeout(const Duration(seconds: 45));
      final govdeMetni = await yanit.stream.bytesToString();

      if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
        final hataGovdesi = _govdeCoz(govdeMetni);
        final mesaj = (hataGovdesi['hata'] ?? '').toString();
        return Result.failure(
          Failure(
            mesaj.isNotEmpty ? mesaj : 'Fatura şu an okunamadı. Tekrar dene.',
          ),
        );
      }

      final govde = _govdeCoz(govdeMetni);
      final hamSatirlar = govde['satirlar'];
      if (hamSatirlar is! List || hamSatirlar.isEmpty) {
        return Result.failure(Failure('Bu fotoğrafta ürün satırı bulunamadı.'));
      }

      final urunler = <DetectedProduct>[];
      final taslaklar = <InvoiceProductDraft>[];

      for (var i = 0; i < hamSatirlar.length; i++) {
        final satir = hamSatirlar[i];
        if (satir is! Map) continue;
        final cift = _satirdanCiftUret(satir, i);
        urunler.add(cift.$1);
        taslaklar.add(cift.$2);
      }

      return Result.success(
        OcrCatalogResult(
          rawText: '',
          products: urunler,
          invoiceDrafts: taslaklar,
          confidence:
              urunler.isEmpty
                  ? 0
                  : urunler.map((u) => u.confidence).reduce((a, b) => a + b) /
                      urunler.length,
        ),
      );
    } catch (_) {
      return Result.failure(
        Failure('Fatura şu an okunamadı. İnternet bağlantını kontrol et.'),
      );
    } finally {
      if (ownsClient) client.close();
    }
  }

  (DetectedProduct, InvoiceProductDraft) _satirdanCiftUret(
    Map satir,
    int index,
  ) {
    final now = DateTime.now().toUtc();
    String metin(dynamic v) => (v ?? '').toString().trim();
    num? sayi(dynamic v) => v is num ? v : num.tryParse((v ?? '').toString());

    final model = metin(satir['model']);
    final ad = metin(satir['ad']);
    final barkod = metin(satir['barkod']);
    final varyant = metin(satir['varyant']);
    final beden = metin(satir['beden']);
    final adet = sayi(satir['adet'])?.toInt();
    final alisFiyat = sayi(satir['alisBirimFiyat'])?.toDouble();
    final satirToplam = sayi(satir['satirToplam'])?.toDouble();
    final guven = (sayi(satir['guven']) ?? 0.5).toDouble();

    final katalog = satir['katalog'];
    final katalogVar = katalog is Map;

    final id = 'ocr_invoice_${now.microsecondsSinceEpoch}_$index';

    EvidenceValue<String>? evMetin(
      String deger,
      EvidenceSourceType tur,
      EvidenceStrength guc,
    ) {
      final temiz = deger.trim();
      if (temiz.isEmpty) return null;
      return EvidenceValue<String>(
        value: temiz,
        sourceType: tur,
        sourceReference: id,
        strength: guc,
        verifiedAt: now,
      );
    }

    EvidenceValue<num>? evSayi(num? deger, EvidenceStrength guc) {
      if (deger == null) return null;
      return EvidenceValue<num>(
        value: deger,
        sourceType: EvidenceSourceType.invoice,
        sourceReference: id,
        strength: guc,
        verifiedAt: now,
      );
    }

    // Kanıt gücü: kod ya da barkod GERÇEK üretici kataloğunda bulunduysa
    // "strong" — tahmin değil, doğrulanmış kayıt. Bulunamadıysa faturadaki
    // okuma güvenine göre "partial"/"weak" — hiçbir zaman kendiliğinden
    // "strong" olmaz.
    final urunGucu =
        katalogVar
            ? EvidenceStrength.strong
            : guven >= 0.7
            ? EvidenceStrength.partial
            : EvidenceStrength.weak;
    final tedarikciGucu =
        katalogVar ? EvidenceStrength.strong : EvidenceStrength.weak;

    String resmiAd = ad;
    String marka = '';
    final gorseller = <InvoiceImageCandidate>[];
    RightsStatus izinDurumu = RightsStatus.unknown;

    if (katalogVar) {
      resmiAd =
          metin(katalog['resmiAd']).isNotEmpty ? metin(katalog['resmiAd']) : ad;
      marka = metin(katalog['marka']);
      final izinHam = metin(katalog['izinDurumu']);
      izinDurumu =
          izinHam == 'var'
              ? RightsStatus.verifiedSupplierPermission
              : RightsStatus.unknown;

      final gorselListesi = katalog['gorseller'];
      if (gorselListesi is List) {
        final kaynak = metin(katalog['kaynak']);
        final firma = metin(katalog['firma']);
        for (final g in gorselListesi) {
          gorseller.add(
            InvoiceImageCandidate(
              url: g.toString(),
              sourceType: EvidenceSourceType.officialProductPage,
              sourceReference: kaynak.isNotEmpty ? kaynak : firma,
              strength: EvidenceStrength.strong,
              rightsStatus: izinDurumu,
              selected: true,
            ),
          );
        }
      }
    }

    final urun = DetectedProduct(
      id: id,
      name: resmiAd.isNotEmpty ? resmiAd : (model.isNotEmpty ? model : 'Ürün'),
      brand: marka,
      quantity: adet ?? 1,
      documentQuantity: adet,
      confidence:
          urunGucu == EvidenceStrength.strong
              ? 0.95
              : urunGucu == EvidenceStrength.partial
              ? 0.6
              : 0.3,
      source: 'ocr_invoice',
      barcode: barkod.isNotEmpty ? barkod : null,
      sku: model.isNotEmpty ? model : null,
      variant: varyant.isNotEmpty ? varyant : null,
      size: beden.isNotEmpty ? beden : null,
      purchaseUnitPrice: alisFiyat,
      lineTotal: satirToplam,
    );

    final taslak = InvoiceProductDraft(
      id: id,
      rawSourceLine: [
        if (model.isNotEmpty) model,
        ad,
        if (barkod.isNotEmpty) barkod,
      ].join(' '),
      rawName: evMetin(
        ad,
        EvidenceSourceType.invoice,
        EvidenceStrength.partial,
      ),
      normalizedName:
          katalogVar
              ? evMetin(
                resmiAd,
                EvidenceSourceType.officialProductPage,
                EvidenceStrength.strong,
              )
              : null,
      gtinBarcode: evMetin(
        barkod,
        EvidenceSourceType.invoice,
        EvidenceStrength.partial,
      ),
      modelCode: evMetin(
        model,
        EvidenceSourceType.invoice,
        EvidenceStrength.partial,
      ),
      brand:
          katalogVar
              ? evMetin(
                marka,
                EvidenceSourceType.officialProductPage,
                EvidenceStrength.strong,
              )
              : null,
      variant: evMetin(
        varyant,
        EvidenceSourceType.invoice,
        EvidenceStrength.partial,
      ),
      size: evMetin(
        beden,
        EvidenceSourceType.invoice,
        EvidenceStrength.partial,
      ),
      quantity: evSayi(adet, EvidenceStrength.partial),
      purchaseUnitPrice: evSayi(alisFiyat, EvidenceStrength.partial),
      purchaseLineTotal: evSayi(satirToplam, EvidenceStrength.partial),
      currency: EvidenceValue<String>(
        value: 'TRY',
        sourceType: EvidenceSourceType.invoice,
        sourceReference: id,
        strength: EvidenceStrength.strong,
        verifiedAt: now,
      ),
      canonicalProductId:
          katalogVar
              ? evMetin(
                metin(katalog['firma']),
                EvidenceSourceType.officialProductPage,
                EvidenceStrength.strong,
              )
              : null,
      canonicalProductUrl:
          katalogVar
              ? evMetin(
                metin(katalog['kaynak']),
                EvidenceSourceType.officialProductPage,
                EvidenceStrength.strong,
              )
              : null,
      imageCandidates: gorseller,
      supplierIdentityStrength: tedarikciGucu,
      productIdentityStrength: urunGucu,
      rightsStatus: izinDurumu,
    );

    return (urun, taslak);
  }

  Map<String, dynamic> _govdeCoz(String govdeMetni) {
    try {
      final decoded = jsonDecode(govdeMetni);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Uri _buildEndpoint(String path) {
    final link = PublicSiteConfig.buildPublicLink(
      path,
      configuredOriginOverride: _originOverride,
    );
    return Uri.parse(link);
  }
}
