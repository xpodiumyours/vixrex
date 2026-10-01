import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/utils/failure.dart';

/// Onaylanan fatura satırlarını web ile AYNI sunucu kapısına
/// (`/api/products/batch`) taslak olarak yazar.
///
/// Sunucu satırın kanıt durumunu ve izinli görsellerini işlem kaydından
/// yeniden okur; telefonun gönderdiği "kanıtlı" etiketi tek başına yetmez.
/// Bu servis ürünü ASLA yayınlamaz (`yayinIstegi: false`); yayın ayrı
/// eylemdir ve `FaturaYayinlaServisi` ile yapılır.
class FaturaUrunKaydiServisi {
  final http.Client? _httpClient;
  final String? _originOverride;

  const FaturaUrunKaydiServisi({
    http.Client? httpClient,
    String? originOverride,
  }) : _httpClient = httpClient,
       _originOverride = originOverride;

  Future<Result<FaturaKaydiSonucu>> taslakKaydet({
    required List<FaturaKaydiSatiri> satirlar,
    required String storeSlug,
    required String editToken,
  }) async {
    if (storeSlug.trim().isEmpty || editToken.trim().isEmpty) {
      return Result.failure(
        Failure('Vitrin henüz yayınlanmamış. Önce vitrinini yayınla.'),
      );
    }
    if (satirlar.isEmpty) {
      return Result.failure(Failure('Kaydedilecek ürün seçilmedi.'));
    }

    final ownsClient = _httpClient == null;
    final client = _httpClient ?? http.Client();

    try {
      final endpoint = _buildEndpoint('/api/products/batch');
      final yanit = await client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'slug': storeSlug,
              'editToken': editToken,
              'products': satirlar.map((satir) => satir.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 90));

      final govde = _govdeCoz(yanit.body);
      if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
        final mesaj = (govde['hata'] ?? '').toString();
        return Result.failure(
          Failure(
            mesaj.isNotEmpty ? mesaj : 'Ürünler kaydedilemedi. Tekrar dene.',
          ),
        );
      }

      final kaydedilenler = <KaydedilenSatir>[];
      final hamSatirlar = govde['satirlar'];
      if (hamSatirlar is List) {
        for (final satir in hamSatirlar) {
          if (satir is! Map) continue;
          final id = (satir['id'] ?? '').toString();
          kaydedilenler.add(
            KaydedilenSatir(
              sira: satir['sira'] is num ? (satir['sira'] as num).toInt() : -1,
              ad: (satir['ad'] ?? '').toString(),
              durum: (satir['durum'] ?? '').toString(),
              sebep: (satir['sebep'] ?? '').toString(),
              kayit: (satir['kayit'] ?? '').toString(),
              id: id.isEmpty ? null : id,
            ),
          );
        }
      }

      if (govde['tamam'] != true ||
          kaydedilenler.length != satirlar.length ||
          kaydedilenler.map((satir) => satir.sira).toSet().length !=
              satirlar.length ||
          kaydedilenler.any(
            (satir) =>
                satir.sira < 0 ||
                satir.sira >= satirlar.length ||
                !['taslak', 'yayinda', 'atlandi'].contains(satir.durum) ||
                (satir.durum != 'atlandi' &&
                    (satir.id == null || satir.id!.trim().isEmpty)),
          )) {
        return Result.failure(
          Failure(
            'Sunucu bütün ürünlerin kayıt sonucunu vermedi. Taslağın korunuyor; tekrar dene.',
          ),
        );
      }

      return Result.success(
        FaturaKaydiSonucu(
          yayinda: _tamSayi(govde['yayinda']),
          taslak: _tamSayi(govde['taslak']),
          hatali: _tamSayi(govde['hatali']),
          satirlar: kaydedilenler,
        ),
      );
    } catch (_) {
      return Result.failure(
        Failure('Ürünler kaydedilemedi. İnternet bağlantını kontrol et.'),
      );
    } finally {
      if (ownsClient) client.close();
    }
  }

  int _tamSayi(dynamic deger) => deger is num ? deger.toInt() : 0;

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

/// Sunucuya gönderilen tek fatura satırı. Web'in `/api/products/batch`
/// gövdesiyle aynı alanları taşır.
class FaturaKaydiSatiri {
  final int satirSirasi;
  final String islemKimligi;
  final String ad;
  final String aciklama;
  final String fiyatMetni;
  final String kategoriId;
  final List<String> gorseller;
  final String? gorselKaynagi;
  final String? marka;
  final String? barkod;
  final String? model;
  final String? varyant;
  final String? beden;
  final int? stok;
  final bool stokOnaylandi;
  final String kartDurumu;
  final String disKimlik;
  final double? alisFiyati;
  final bool onayli;

  const FaturaKaydiSatiri({
    required this.satirSirasi,
    required this.islemKimligi,
    required this.ad,
    required this.fiyatMetni,
    required this.kategoriId,
    required this.kartDurumu,
    required this.disKimlik,
    this.aciklama = '',
    this.gorseller = const <String>[],
    this.gorselKaynagi,
    this.marka,
    this.barkod,
    this.model,
    this.varyant,
    this.beden,
    this.stok,
    this.stokOnaylandi = false,
    this.alisFiyati,
    this.onayli = false,
  });

  Map<String, dynamic> toJson() {
    final secenekler = <String, String>{
      if (varyant != null && varyant!.trim().isNotEmpty)
        'color': varyant!.trim(),
      if (beden != null && beden!.trim().isNotEmpty) 'size': beden!.trim(),
    };
    final degisimKodu =
        (model ?? '').trim().isNotEmpty
            ? model!.trim()
            : (barkod ?? '').trim().isNotEmpty
            ? barkod!.trim()
            : '$satirSirasi';

    return {
      'name': ad,
      'description': aciklama,
      'priceText': fiyatMetni,
      'categoryId': kategoriId,
      'imageUrls': gorseller,
      if (gorselKaynagi != null && gorselKaynagi!.trim().isNotEmpty)
        'gorselKaynagi': gorselKaynagi!.trim(),
      if (marka != null && marka!.trim().isNotEmpty) 'brand': marka!.trim(),
      if (barkod != null && barkod!.trim().isNotEmpty)
        'barcode': barkod!.trim(),
      'stockQuantity': stok,
      'sourceType': 'invoice',
      'kartDurumu': kartDurumu,
      'stokOnaylandi': stokOnaylandi,
      if (disKimlik.trim().isNotEmpty) 'externalProductId': disKimlik.trim(),
      'ownerApproved': onayli,
      'yayinIstegi': false,
      if (alisFiyati != null) 'purchasePriceAmount': alisFiyati,
      if ((model ?? '').trim().isNotEmpty)
        'metadata': {
          'identifiers': {'sku': model!.trim()},
        },
      if (secenekler.isNotEmpty)
        'variants': [
          {
            'id': 'v-${degisimKodu.toLowerCase()}',
            'options': secenekler,
            if (stok != null) 'stockQuantity': stok,
          },
        ],
      'islemKimligi': islemKimligi,
      'satirSirasi': satirSirasi,
    };
  }
}

class FaturaKaydiSonucu {
  final int yayinda;
  final int taslak;
  final int hatali;
  final List<KaydedilenSatir> satirlar;

  const FaturaKaydiSonucu({
    required this.yayinda,
    required this.taslak,
    required this.hatali,
    required this.satirlar,
  });

  List<String> get yayinlanabilirTaslakIdleri => satirlar
      .where((satir) => satir.durum == 'taslak' && satir.id != null)
      .map((satir) => satir.id!)
      .toList(growable: false);
}

class KaydedilenSatir {
  final int sira;
  final String ad;
  final String durum;
  final String sebep;
  final String kayit;
  final String? id;

  const KaydedilenSatir({
    required this.sira,
    required this.ad,
    required this.durum,
    this.sebep = '',
    this.kayit = '',
    this.id,
  });
}
