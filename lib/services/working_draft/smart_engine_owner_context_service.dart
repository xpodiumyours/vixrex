import 'dart:convert';

import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/services/owner_bootstrap_service.dart';

class FlutterSmartEngineOwnerContext {
  const FlutterSmartEngineOwnerContext({
    required this.ready,
    required this.reason,
    this.draftVersion,
    this.baseLiveVersion,
  });

  const FlutterSmartEngineOwnerContext.notReady(String reason)
    : this(ready: false, reason: reason);

  final bool ready;
  final String reason;
  final int? draftVersion;
  final int? baseLiveVersion;
}

/// Flutter'da gösterilen owner-edit verisi ile authoritative working draft'ın
/// aynı 46-field projection olduğunu kanıtlamadan optimistic-concurrency
/// version'ını kullanmaz.
///
/// Önemli: yalnız "latest draftVersion" çekmek yasaktır; UI eski kalmışsa bu
/// conflict korumasını fiilen baypas ederdi. Bu servis version + görünür veri
/// eşleşmesini tek kapıda doğrular.
class SmartEngineOwnerContextService {
  const SmartEngineOwnerContextService({
    this.bootstrapService = const OwnerBootstrapService(),
  });

  final OwnerBootstrapService bootstrapService;

  Future<Result<FlutterSmartEngineOwnerContext>> resolve({
    required StoreData displayedData,
  }) async {
    final stateResult = await bootstrapService.getirVeCalismaTaslaginiHazirla();
    if (stateResult.isFailure) {
      return Result.failure(stateResult.failure!);
    }

    final state = stateResult.data!;
    if (state.anonimOturum || !state.hasStore) {
      return const Result.success(
        FlutterSmartEngineOwnerContext.notReady('OWNER_AUTHORIZATION_REQUIRED'),
      );
    }
    if (!state.isPublished) {
      return const Result.success(
        FlutterSmartEngineOwnerContext.notReady('OWNER_EDIT_NOT_PUBLISHED'),
      );
    }
    if (!state.hasDraft || state.draftData == null || state.draftVersion < 1) {
      return const Result.success(
        FlutterSmartEngineOwnerContext.notReady('WORKING_DRAFT_NOT_READY'),
      );
    }
    if (state.draftStale) {
      return const Result.success(
        FlutterSmartEngineOwnerContext.notReady('WORKING_DRAFT_STALE'),
      );
    }
    if (!_sameEditableProjection(displayedData, state.draftData!)) {
      return const Result.success(
        FlutterSmartEngineOwnerContext.notReady('DRAFT_PROJECTION_STALE'),
      );
    }

    return Result.success(
      FlutterSmartEngineOwnerContext(
        ready: true,
        reason: 'OK',
        draftVersion: state.draftVersion,
        baseLiveVersion: state.baseLiveVersion,
      ),
    );
  }

  bool _sameEditableProjection(StoreData displayed, StoreData canonical) {
    final displayedJson = displayed.toJson();
    final canonicalJson = canonical.toJson();

    for (final field in vitrinAlanlari) {
      final left = _canonicalJson(displayedJson[field.kolon]);
      final right = _canonicalJson(canonicalJson[field.kolon]);
      if (left != right) return false;
    }
    return true;
  }

  String _canonicalJson(Object? value) => jsonEncode(_sortJson(value));

  Object? _sortJson(Object? value) {
    if (value is Map) {
      final entries =
          value.entries
              .map(
                (entry) =>
                    MapEntry(entry.key.toString(), _sortJson(entry.value)),
              )
              .toList()
            ..sort((a, b) => a.key.compareTo(b.key));
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }
    if (value is List) return value.map(_sortJson).toList();
    return value;
  }
}
