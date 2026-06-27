import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vitrinx/config/public_site_config.dart';
import 'package:vitrinx/models/store_data.dart';

class InstagramConnectionStatus {
  final bool connected;
  final String status;
  final String? username;
  final String? accountType;
  final DateTime? expiresAt;

  const InstagramConnectionStatus({
    required this.connected,
    required this.status,
    this.username,
    this.accountType,
    this.expiresAt,
  });

  factory InstagramConnectionStatus.fromJson(Map<String, dynamic> json) {
    return InstagramConnectionStatus(
      connected: json['connected'] == true,
      status: (json['status'] ?? 'not_connected').toString(),
      username: _nullableString(json['username']),
      accountType: _nullableString(json['accountType']),
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()),
    );
  }
}

class InstagramMediaItem {
  final String id;
  final String caption;
  final String imageUrl;
  final String permalink;
  final DateTime? timestamp;

  const InstagramMediaItem({
    required this.id,
    required this.caption,
    required this.imageUrl,
    required this.permalink,
    this.timestamp,
  });

  factory InstagramMediaItem.fromJson(Map<String, dynamic> json) {
    return InstagramMediaItem(
      id: (json['id'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      imageUrl: (json['media_url'] ?? json['thumbnail_url'] ?? '').toString(),
      permalink: (json['permalink'] ?? '').toString(),
      timestamp: DateTime.tryParse((json['timestamp'] ?? '').toString()),
    );
  }
}

class InstagramSyncException implements Exception {
  final String code;
  final int? statusCode;

  const InstagramSyncException(this.code, {this.statusCode});

  String get userMessage {
    if (code.contains('TOKEN_EXPIRED')) {
      return 'Instagram bağlantısının süresi dolmuş. Yeniden bağlayın.';
    }
    if (code.contains('NOT_CONNECTED')) {
      return 'Önce Instagram hesabınızı bağlayın.';
    }
    if (code.contains('AUTH')) {
      return 'Vitrin yetkisi doğrulanamadı.';
    }
    if (code.contains('TOO_LARGE')) {
      return 'Fotoğraf 6 MB sınırını aşıyor.';
    }
    if (code.contains('TYPE_UNSUPPORTED')) {
      return 'Şimdilik yalnızca Instagram fotoğrafları aktarılabilir.';
    }
    if (code.contains('ORIGIN_NOT_ALLOWED')) {
      return 'Instagram bağlantısı bu uygulama adresinde kullanılamıyor.';
    }
    return 'Instagram işlemi tamamlanamadı. Lütfen tekrar deneyin.';
  }

  @override
  String toString() => code;
}

class InstagramSyncService {
  final http.Client? _httpClient;
  final String? _originOverride;

  const InstagramSyncService({http.Client? httpClient, String? originOverride})
    : _httpClient = httpClient,
      _originOverride = originOverride;

  Future<InstagramConnectionStatus> getStatus({
    required String storeSlug,
    required String editToken,
  }) async {
    final json = await _post('/api/instagram/status', {
      'storeSlug': storeSlug,
      'editToken': editToken,
    });
    return InstagramConnectionStatus.fromJson(json);
  }

  Future<Uri> createAuthorizationUrl({
    required String storeSlug,
    required String editToken,
  }) async {
    final json = await _post('/api/instagram/connect', {
      'storeSlug': storeSlug,
      'editToken': editToken,
      'returnTo': '/instagram/baglanti-tamamlandi',
    });
    final uri = Uri.tryParse((json['authorizationUrl'] ?? '').toString());
    if (uri == null || uri.scheme != 'https') {
      throw const InstagramSyncException('INSTAGRAM_AUTH_URL_INVALID');
    }
    return uri;
  }

  Future<List<InstagramMediaItem>> listMedia({
    required String storeSlug,
    required String editToken,
  }) async {
    final json = await _post('/api/instagram/media', {
      'storeSlug': storeSlug,
      'editToken': editToken,
    });
    final items = json['media'];
    if (items is! List) return const [];

    return items
        .whereType<Map>()
        .map(
          (item) =>
              InstagramMediaItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty && item.imageUrl.isNotEmpty)
        .toList();
  }

  Future<Product> importProduct({
    required String storeSlug,
    required String editToken,
    required String mediaId,
    String price = '',
    String category = '',
  }) async {
    final json = await _post('/api/instagram/import', {
      'storeSlug': storeSlug,
      'editToken': editToken,
      'mediaId': mediaId,
      'price': price.trim(),
      'category': category.trim(),
    });
    final product = json['product'];
    if (product is! Map) {
      throw const InstagramSyncException('INSTAGRAM_PRODUCT_INVALID');
    }
    return Product.fromJson(Map<String, dynamic>.from(product));
  }

  Future<void> disconnect({
    required String storeSlug,
    required String editToken,
  }) async {
    await _post('/api/instagram/disconnect', {
      'storeSlug': storeSlug,
      'editToken': editToken,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final endpoint = _buildEndpoint(path);
    final ownsClient = _httpClient == null;
    final client = _httpClient ?? http.Client();

    try {
      final response = await client
          .post(
            endpoint,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);
      final json =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw InstagramSyncException(
          (json['message'] ?? 'INSTAGRAM_REQUEST_FAILED').toString(),
          statusCode: response.statusCode,
        );
      }
      return json;
    } on FormatException {
      throw const InstagramSyncException('INSTAGRAM_RESPONSE_INVALID');
    } finally {
      if (ownsClient) client.close();
    }
  }

  Uri _buildEndpoint(String path) {
    final link = PublicSiteConfig.buildPublicLink(
      path,
      configuredOriginOverride: _originOverride,
    );
    final uri = Uri.tryParse(link);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw const InstagramSyncException('PUBLIC_SITE_URL_INVALID');
    }
    return uri;
  }
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
