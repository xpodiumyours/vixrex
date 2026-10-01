import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/utils/failure.dart';

class FaturaIslemServisi {
  final http.Client? httpClient;
  final String? originOverride;
  const FaturaIslemServisi({this.httpClient, this.originOverride});

  Future<Result<Map<String, dynamic>>> listele({
    required String slug,
    required String editToken,
  }) => _istek('GET', '/api/fatura-islem', slug, editToken);

  Future<Result<Map<String, dynamic>>> yukle({
    required String slug,
    required String editToken,
    required String islemKimligi,
  }) => _istek('GET', '/api/fatura-islem', slug, editToken, {
    'islemKimligi': islemKimligi,
  });

  Future<Result<Map<String, dynamic>>> urundenBul({
    required String slug,
    required String editToken,
    required String urunId,
  }) => _istek('GET', '/api/fatura-islem', slug, editToken, {'urunId': urunId});

  Future<Result<Map<String, dynamic>>> kaydet({
    required String slug,
    required String editToken,
    required String islemKimligi,
    required List<Map<String, dynamic>> satirlar,
  }) => _istek('PUT', '/api/fatura-islem', slug, editToken, {
    'islemKimligi': islemKimligi,
    'satirlar': satirlar,
  });

  Future<Result<Map<String, dynamic>>> duzelt({
    required String slug,
    required String editToken,
    required String islemKimligi,
    required int satirSirasi,
    required String ad,
    required String model,
    required String barkod,
    required String marka,
  }) => _istek('POST', '/api/fatura-satir-duzelt', slug, editToken, {
    'islemKimligi': islemKimligi,
    'satirSirasi': satirSirasi,
    'ad': ad,
    'model': model,
    'barkod': barkod,
    'marka': marka,
  });

  Future<Result<Map<String, dynamic>>> _istek(
    String method,
    String path,
    String slug,
    String editToken, [
    Map<String, dynamic> alanlar = const {},
  ]) async {
    if (slug.trim().isEmpty || editToken.trim().isEmpty) {
      return Result.failure(Failure('Vitrin oturumu bulunamadı.'));
    }
    final client = httpClient ?? http.Client();
    try {
      var uri = Uri.parse(
        PublicSiteConfig.buildPublicLink(
          path,
          configuredOriginOverride: originOverride,
        ),
      );
      final body = {'slug': slug, ...alanlar};
      if (method == 'GET') {
        uri = uri.replace(
          queryParameters: body.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
      final request = http.Request(method, uri)
        ..headers.addAll({
          'content-type': 'application/json; charset=utf-8',
          'x-vixrex-edit-token': editToken,
        });
      if (method != 'GET') request.body = jsonEncode(body);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 90));
      final decoded = jsonDecode(await response.stream.bytesToString());
      if (decoded is! Map) {
        return Result.failure(Failure('Sunucu yanıtı okunamadı.'));
      }
      final data = Map<String, dynamic>.from(decoded);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data['tamam'] != true) {
        return Result.failure(
          Failure((data['hata'] ?? 'Fatura işlemi tamamlanamadı.').toString()),
        );
      }
      return Result.success(data);
    } catch (_) {
      return Result.failure(
        Failure(
          'Fatura işlemi tamamlanamadı. Bağlantını kontrol edip tekrar dene.',
        ),
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }
}
