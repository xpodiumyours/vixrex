import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_clarifier.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_decision_contract.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';

/// Geriye uyum outcome'u. Canonical 5.3 karar sınıfı [VixrexNluPipelineResult.decision].
enum VixrexNluPipelineOutcome {
  handled,
  needsClarification,
  notUnderstood,
  blockedLegal,
  needsSpecialFlow,
}

class VixrexNluPipelineResult {
  /// Canonical decision/action contract.
  final String decision;
  final List<VixrexValidatedAction> actions;

  /// Geriye uyum alanları. Aktif çağıranlar `decision/actions` kontratına
  /// geçirildikçe sadeleştirilebilir.
  final VixrexNluPipelineOutcome outcome;
  final ChatMessage message;
  final String? appliedAnahtar;
  final Object? appliedDeger;
  final List<String>? appliedAnahtarlar;
  final List<Object?>? appliedDegerler;

  const VixrexNluPipelineResult({
    required this.decision,
    this.actions = const <VixrexValidatedAction>[],
    required this.outcome,
    required this.message,
    this.appliedAnahtar,
    this.appliedDeger,
    this.appliedAnahtarlar,
    this.appliedDegerler,
  });
}

/// Mesaj → niyet → değer → hafıza → doğrulama → typed action.
///
/// 5.3 LOCK: Bu sınıf persistence yapmaz, executor çağırmaz ve authoritative
/// write gerçekleşmeden "kaydedildi" başarı semantiği üretmez.
class VixrexNluPipeline {
  VixrexNluPipeline({
    VixrexIntentResolver? intentResolver,
    VixrexValueExtractor? valueExtractor,
    VixrexConversationMemoryPort? memory,
    VixrexClarifier? clarifier,
  }) : _intentResolver = intentResolver ?? const VixrexIntentResolver(),
       _valueExtractor = valueExtractor ?? const VixrexValueExtractor(),
       _memory = memory ?? const VixrexConversationMemory(),
       _clarifier = clarifier ?? const VixrexClarifier();

  final VixrexIntentResolver _intentResolver;
  final VixrexValueExtractor _valueExtractor;
  final VixrexConversationMemoryPort _memory;
  final VixrexClarifier _clarifier;

  static const _evetler = {
    'evet',
    'evet.',
    'onayla',
    'onay',
    'tamam',
    'olur',
    'kaydet',
  };
  static const _hayirlar = {
    'hayir',
    'hayır',
    'iptal',
    'vazgec',
    'vazgeç',
    'hayir.',
    'hayır.',
  };

  String _validatedMessage(int count) =>
      count > 1
          ? 'Değişiklikler doğrulandı; kayıt için hazır.'
          : 'Değişiklik doğrulandı; kayıt için hazır.';

  List<VixrexIntentMatch> _uniqueFieldMatches(String input) {
    final seen = <String>{};
    final unique = <VixrexIntentMatch>[];
    for (final match in _intentResolver.resolveMatches(input)) {
      if (!seen.add(match.alan.anahtar)) continue;
      unique.add(match);
    }
    return unique;
  }

  /// `controller` yalnız eski çağrı imzasını kırmamak için tutulur ve bu
  /// decision katmanında KULLANILMAZ. Mutation 5.8 executor lifecycle'ındadır.
  Future<VixrexNluPipelineResult> handle({
    required String input,
    required StoreEditorController? controller,
    String? scope,
    required Future<({bool ok, String? hata, Object? normalizedDeger})>
    Function(VixrexNiyetAlan alan, String hamDeger)
    onValidate,
    bool Function(VixrexNiyetAlan alan)? needsSpecialFlow,
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return VixrexNluPipelineResult(
        decision: VixrexDecisionKind.notUnderstood,
        outcome: VixrexNluPipelineOutcome.notUnderstood,
        message: ChatMessage.bot(_clarifier.belirsiz()),
      );
    }

    final norm = VixrexNormalizer.normalize(trimmed);

    final pending = await _memory.loadPendingSlot(scope: scope);
    if (pending != null) {
      if (_evetler.contains(norm) || _hayirlar.contains(norm)) {
        if (_evetler.contains(norm)) {
          await _memory.clearPendingSlot(scope: scope);
          return VixrexNluPipelineResult(
            decision: VixrexDecisionKind.needsClarification,
            outcome: VixrexNluPipelineOutcome.needsClarification,
            message: ChatMessage.bot(_clarifier.belirsiz()),
          );
        }

        await _memory.clearPendingSlot(scope: scope);
        return VixrexNluPipelineResult(
          decision: VixrexDecisionKind.needsClarification,
          outcome: VixrexNluPipelineOutcome.needsClarification,
          message: ChatMessage.bot(
            'Tamam, vazgeçtim. Başka nasıl yardımcı olabilirim?',
          ),
        );
      }

      final alanFromPending = vixrexNiyetAlanByAnahtar[pending.anahtar];
      if (alanFromPending != null) {
        final resolved = _intentResolver.resolve(trimmed);
        if (resolved == null) {
          final hamDeger = trimmed;
          if (needsSpecialFlow != null && needsSpecialFlow(alanFromPending)) {
            return VixrexNluPipelineResult(
              decision: VixrexDecisionKind.needsSpecialFlow,
              outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
              message: ChatMessage.bot(_clarifier.sor(alanFromPending)),
              appliedAnahtar: alanFromPending.anahtar,
            );
          }

          final validated = await onValidate(alanFromPending, hamDeger);
          if (!validated.ok) {
            return VixrexNluPipelineResult(
              decision: VixrexDecisionKind.needsClarification,
              outcome: VixrexNluPipelineOutcome.needsClarification,
              message: ChatMessage.bot(
                _clarifier.hata(validated.hata ?? 'Geçersiz değer.'),
              ),
            );
          }

          await _memory.clearPendingSlot(scope: scope);
          final kesinDeger = validated.normalizedDeger ?? hamDeger;
          final action = VixrexValidatedAction(
            fieldKey: alanFromPending.anahtar,
            normalizedValue: kesinDeger,
            matchClass: 'pending_slot',
          );
          return VixrexNluPipelineResult(
            decision: VixrexDecisionKind.validatedAction,
            actions: [action],
            outcome: VixrexNluPipelineOutcome.handled,
            message: ChatMessage.bot(_validatedMessage(1)),
            appliedAnahtar: alanFromPending.anahtar,
            appliedDeger: kesinDeger,
          );
        }
      }
    }

    final matches = _uniqueFieldMatches(trimmed);
    if (matches.isEmpty) {
      return VixrexNluPipelineResult(
        decision: VixrexDecisionKind.notUnderstood,
        outcome: VixrexNluPipelineOutcome.notUnderstood,
        message: ChatMessage.bot(_clarifier.belirsiz()),
      );
    }

    if (matches.length > 1) {
      final basarili = <VixrexNiyetAlan>[];
      final basariliDegerler = <Object?>[];
      final basariliMatches = <VixrexIntentMatch>[];
      final hatalar = <String>[];

      for (final match in matches) {
        final a = match.alan;
        if (needsSpecialFlow != null && needsSpecialFlow(a)) {
          hatalar.add('${a.etiket} için panelden devam et');
          continue;
        }

        final ham = _valueExtractor.extract(trimmed, a);
        if (ham == null || ham.trim().isEmpty) {
          hatalar.add('${a.etiket} için değer bulunamadı');
          continue;
        }

        final v = await onValidate(a, ham);
        if (!v.ok) {
          hatalar.add(v.hata ?? '${a.etiket} geçersiz');
          continue;
        }

        basarili.add(a);
        basariliDegerler.add(v.normalizedDeger ?? ham);
        basariliMatches.add(match);
      }

      if (basarili.isEmpty) {
        return VixrexNluPipelineResult(
          decision: VixrexDecisionKind.needsClarification,
          outcome: VixrexNluPipelineOutcome.needsClarification,
          message: ChatMessage.bot(
            hatalar.isNotEmpty ? hatalar.join('\n') : _clarifier.belirsiz(),
          ),
        );
      }

      await _memory.clearPendingSlot(scope: scope);
      final actions = <VixrexValidatedAction>[
        for (var i = 0; i < basarili.length; i++)
          VixrexValidatedAction(
            fieldKey: basarili[i].anahtar,
            normalizedValue: basariliDegerler[i],
            matchClass: basariliMatches[i].matchClass,
          ),
      ];

      return VixrexNluPipelineResult(
        decision:
            actions.length > 1
                ? VixrexDecisionKind.validatedActionGroup
                : VixrexDecisionKind.validatedAction,
        actions: actions,
        outcome: VixrexNluPipelineOutcome.handled,
        message: ChatMessage.bot(_validatedMessage(actions.length)),
        appliedAnahtar: basarili.first.anahtar,
        appliedDeger: basariliDegerler.first,
        appliedAnahtarlar: basarili.map((e) => e.anahtar).toList(),
        appliedDegerler: basariliDegerler,
      );
    }

    final match = matches.first;
    final alan = match.alan;

    if (needsSpecialFlow != null && needsSpecialFlow(alan)) {
      await _memory.savePendingSlot(
        VixrexPendingSlot(
          anahtar: alan.anahtar,
          etiket: alan.etiket,
          tip: alan.tip,
          sorulduAt: DateTime.now(),
        ),
        scope: scope,
      );
      return VixrexNluPipelineResult(
        decision: VixrexDecisionKind.needsSpecialFlow,
        outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
        message: ChatMessage.bot(_clarifier.sor(alan)),
        appliedAnahtar: alan.anahtar,
      );
    }

    final hamDeger = _valueExtractor.extract(trimmed, alan);
    if (hamDeger == null || hamDeger.trim().isEmpty) {
      await _memory.savePendingSlot(
        VixrexPendingSlot(
          anahtar: alan.anahtar,
          etiket: alan.etiket,
          tip: alan.tip,
          sorulduAt: DateTime.now(),
        ),
        scope: scope,
      );
      return VixrexNluPipelineResult(
        decision: VixrexDecisionKind.needsClarification,
        outcome: VixrexNluPipelineOutcome.needsClarification,
        message: ChatMessage.bot(_clarifier.sor(alan)),
        appliedAnahtar: alan.anahtar,
      );
    }

    final validated = await onValidate(alan, hamDeger);
    if (!validated.ok) {
      return VixrexNluPipelineResult(
        decision: VixrexDecisionKind.needsClarification,
        outcome: VixrexNluPipelineOutcome.needsClarification,
        message: ChatMessage.bot(
          _clarifier.hata(validated.hata ?? 'Geçersiz değer.'),
        ),
        appliedAnahtar: alan.anahtar,
      );
    }

    await _memory.clearPendingSlot(scope: scope);
    final kesinDeger = validated.normalizedDeger ?? hamDeger;
    final action = VixrexValidatedAction(
      fieldKey: alan.anahtar,
      normalizedValue: kesinDeger,
      matchClass: match.matchClass,
    );
    return VixrexNluPipelineResult(
      decision: VixrexDecisionKind.validatedAction,
      actions: [action],
      outcome: VixrexNluPipelineOutcome.handled,
      message: ChatMessage.bot(_validatedMessage(1)),
      appliedAnahtar: alan.anahtar,
      appliedDeger: kesinDeger,
    );
  }
}
