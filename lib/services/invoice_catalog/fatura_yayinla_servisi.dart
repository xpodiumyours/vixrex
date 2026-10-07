import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/utils/failure.dart';

/// Fatura taslaklarının AYRI Yayınla ucunu (`/api/fatura-yayinla`) çağırır.
///
/// Web'deki sonuç ekranıyla AYNI kapı: taslak sunucuda tekrar okunur,
/// kapılar (fiyat, fotoğraf, faturadaki adet, kanıt durumu) yeniden
/// doğrulanır. Kapı kapalıysa ürün taslak kalır; telefondan "oldu" diye
/// gösterilmez.
///
/// Kimlik doğrulama `/api/fatura-oku` ile aynı desendir: store slug +
/// edit_token. Çerez yoktur; telefon kendi jetonuyla gelir.
class FaturaYayinlaServisi {
  final http.Client? _httpClient;
  final String? _originOverride;

  const FaturaYayinlaServisi({http.Client? httpClient, String? originOverride})
    : _httpClient = httpClient,
      _originOverride = originOverride;

  Future<Result<FaturaYayinlaSonucu>> yayinla({
    required List<String> productIds,
    required String storeSlug,
    required String editToken,
  }) async {
    if (storeSlug.trim().isEmpty || editToken.trim().isEmpty) {
      return Result.failure(
        Failure('Vitrin henüz yayınlanmamış. Önce vitrinini yayınla.'),
      );
    }
    final temizIdler =
        productIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    if (temizIdler.isEmpty) {
      return Result.failure(Failure('Yayınlanacak ürün seçilmedi.'));
    }

    final ownsClient = _httpClient == null;
    final client = _httpClient ?? http.Client();

    try {
      final endpoint = _buildEndpoint('/api/fatura-yayinla');
      final yanit = await client
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'slug': storeSlug,
              'editToken': editToken,
              'productIds': temizIdler,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final govde = _govdeCoz(yanit.body);
      if (yanit.statusCode < 200 || yanit.statusCode >= 300) {
        final mesaj = (govde['hata'] ?? '').toString();
        return Result.failure(
          Failure(
            mesaj.isNotEmpty ? mesaj : 'Ürünler yayınlanamadı. Tekrar dene.',
          ),
        );
      }

      final satirlar = <YayinlananSatir>[];
      final hamSatirlar = govde['satirlar'];
      if (hamSatirlar is List) {
        for (final satir in hamSatirlar) {
          if (satir is! Map) continue;
          satirlar.add(
            YayinlananSatir(
              id: (satir['id'] ?? '').toString(),
              yayinda: satir['durum'] == 'yayinda',
              sebep: (satir['sebep'] ?? '').toString(),
            ),
          );
        }
      }

      if (govde['tamam'] != true ||
          satirlar.length != temizIdler.toSet().length ||
          satirlar.map((satir) => satir.id).toSet().length != satirlar.length ||
          satirlar.any((satir) => !temizIdler.contains(satir.id))) {
        return Result.failure(
          Failure(
            'Sunucu bütün ürünlerin yayın sonucunu vermedi. Tekrar dene.',
          ),
        );
      }

      return Result.success(
        FaturaYayinlaSonucu(
          yayinda:
              (govde['yayinda'] is num) ? (govde['yayinda'] as num).toInt() : 0,
          taslak:
              (govde['taslak'] is num) ? (govde['taslak'] as num).toInt() : 0,
          satirlar: satirlar,
          tuketiciDogrulandi: govde['tuketiciDogrulamasi'] == 'tamam',
        ),
      );
    } catch (_) {
      return Result.failure(
        Failure('Ürünler yayınlanamadı. İnternet bağlantını kontrol et.'),
      );
    } finally {
      if (ownsClient) client.close();
    }
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

/// Yayın isteğinin özeti: kaçı vitrine çıktı, kaçı hangi sebeple taslak kaldı.
class FaturaYayinlaSonucu {
  final int yayinda;
  final int taslak;
  final List<YayinlananSatir> satirlar;
  final bool tuketiciDogrulandi;

  const FaturaYayinlaSonucu({
    required this.yayinda,
    required this.taslak,
    required this.satirlar,
    this.tuketiciDogrulandi = false,
  });
}

class YayinlananSatir {
  final String id;
  final bool yayinda;
  final String sebep;

  const YayinlananSatir({
    required this.id,
    required this.yayinda,
    this.sebep = '',
  });
}
