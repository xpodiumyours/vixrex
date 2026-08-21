import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';
import 'package:vixrex/repositories/business_ownership_repository.dart';
import 'package:vixrex/utils/failure.dart';

class BusinessOwnershipService {
  BusinessOwnershipService({BusinessOwnershipRepository? repository})
    : _repository = repository ?? BusinessOwnershipRepository();

  static const _scope = 'https://www.googleapis.com/auth/business.manage';

  final BusinessOwnershipRepository _repository;

  Future<Result<BusinessOwnershipStatus>> getStatus() async {
    try {
      return Result.success(await _repository.getStatus());
    } catch (error, stackTrace) {
      return Result.failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }

  Future<Result<void>> verify(BusinessOwnershipStatus status) async {
    if (!status.hasPublishedStore) {
      return Result.failure(Failure('Önce vitrininizi yayınlayın.'));
    }
    if (status.isVerified) return const Result.success(null);

    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
      final googleSignIn =
          kIsWeb
              ? GoogleSignIn(clientId: webClientId, scopes: const [_scope])
              : GoogleSignIn(
                clientId: iosClientId.isNotEmpty ? iosClientId : null,
                serverClientId: webClientId.isNotEmpty ? webClientId : null,
                scopes: const [_scope],
              );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return Result.failure(Failure('Google doğrulaması iptal edildi.'));
      }
      final accessToken = (await googleUser.authentication).accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        return Result.failure(
          Failure('Google Business Profile izni alınamadı.'),
        );
      }

      await _repository.verifyWithGoogle(
        storeId: status.storeId!,
        accessToken: accessToken,
      );
      return const Result.success(null);
    } on BusinessOwnershipException catch (error) {
      return Result.failure(Failure(error.message));
    } catch (error, stackTrace) {
      return Result.failure(SupabaseErrorMapper.map(error, stackTrace));
    }
  }
}
