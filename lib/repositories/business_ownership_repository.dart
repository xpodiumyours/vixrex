import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessOwnershipStatus {
  const BusinessOwnershipStatus({
    this.storeId,
    this.storeName,
    required this.isVerified,
  });

  final String? storeId;
  final String? storeName;
  final bool isVerified;

  bool get hasPublishedStore => storeId != null;
}

class BusinessOwnershipException implements Exception {
  const BusinessOwnershipException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// İşletme sahiplik doğrulamasının tek Supabase erişim sınırı.
class BusinessOwnershipRepository {
  BusinessOwnershipRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<BusinessOwnershipStatus> getStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const BusinessOwnershipStatus(isVerified: false);
    }

    final rows = await _client
        .from('stores')
        .select('id,name,business_verified_at')
        .eq('user_id', user.id)
        .eq('is_published', true)
        .order('created_at')
        .limit(1);

    if (rows.isEmpty) {
      return const BusinessOwnershipStatus(isVerified: false);
    }

    final store = rows.first;
    return BusinessOwnershipStatus(
      storeId: store['id'] as String,
      storeName: store['name'] as String?,
      isVerified: store['business_verified_at'] != null,
    );
  }

  Future<void> verifyWithGoogle({
    required String storeId,
    required String accessToken,
  }) async {
    final response = await _client.functions.invoke(
      'verify-business-ownership',
      body: {'storeId': storeId, 'accessToken': accessToken},
    );
    if (response.status >= 200 && response.status < 300) return;

    final data = response.data;
    final message =
        data is Map && data['error'] is String
            ? data['error'] as String
            : 'İşletme doğrulanamadı. Lütfen tekrar deneyin.';
    throw BusinessOwnershipException(message);
  }
}
