import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_clarifier.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_intent_resolver.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_value_extractor.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_executor.dart';

/// Faz 1 boru sonucu.
enum VixrexNluPipelineOutcome {
  handled,
  needsClarification,
  notUnderstood,
  blockedLegal,
  needsSpecialFlow,
}

class VixrexNluPipelineResult {
  final VixrexNluPipelineOutcome outcome;
  final ChatMessage message;
  final String? appliedAnahtar;
  final Object? appliedDeger;
  final List<String>? appliedAnahtarlar;
  final List<Object>? appliedDegerler;

  const VixrexNluPipelineResult({
    required this.outcome,
    required this.message,
    this.appliedAnahtar,
    this.appliedDeger,
    this.appliedAnahtarlar,
    this.appliedDegerler,
  });
}

/// Mesaj → niyet → 46 alan → değer → hafıza → doğrulama → mevcut işlem → kayıt → sonuç
/// AI yok, feature-flag ile eski ChatbotService davranışı korunabilir.
class VixrexNluPipeline {
  VixrexNluPipeline({
    VixrexIntentResolver? intentResolver,
    VixrexValueExtractor? valueExtractor,
    VixrexConversationMemoryPort? memory,
    VixrexClarifier? clarifier,
    VixrexExecutor? executor,
  }) : _intentResolver = intentResolver ?? const VixrexIntentResolver(),
       _valueExtractor = valueExtractor ?? const VixrexValueExtractor(),
       _memory = memory ?? const VixrexConversationMemory(),
       _clarifier = clarifier ?? const VixrexClarifier(),
       _executor = executor ?? const VixrexExecutor();

  final VixrexIntentResolver _intentResolver;
  final VixrexValueExtractor _valueExtractor;
  final VixrexConversationMemoryPort _memory;
  final VixrexClarifier _clarifier;
  final VixrexExecutor _executor;

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

  /// Aç/kapat alanlarında değer çoğu zaman ayrı bir metin değil komut
  /// fiilidir: "puanı göster", "yol tarifini gizle". Next.js pipeline ile
  /// aynı deterministik dönüşüm; validator yine gerçek boolean'a normalize eder.
  String? _extractPipelineValue(String input, VixrexNiyetAlan alan) {
    if (alan.tip == 'acikKapali') {
      final tokens = VixrexNormalizer.normalize(input)
          .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
          .trim()
          .split(RegExp(r'\s+'))
          .where((e) => e.isNotEmpty)
          .toSet();
      const negatif = {
        'kapat',
        'kapali',
        'gizle',
        'pasif',
        'hayir',
        'off',
        'false',
        '0',
      };
      const pozitif = {
        'ac',
        'acik',
        'goster',
        'aktif',
        'evet',
        'on',
        'true',
        '1',
      };
      if (tokens.any(negatif.contains)) return 'false';
      if (tokens.any(pozitif.contains)) return 'true';
      return null;
    }
    return _valueExtractor.extract(input, alan);
  }

  /// Ana giriş – sohbetten çağrılır.
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
            outcome: VixrexNluPipelineOutcome.needsClarification,
            message: ChatMessage.bot(_clarifier.belirsiz()),
          );
        } else {
          await _memory.clearPendingSlot(scope: scope);
          return VixrexNluPipelineResult(
            outcome: VixrexNluPipelineOutcome.needsClarification,
            message: ChatMessage.bot(
              'Tamam, vazgeçtim. Başka nasıl yardımcı olabilirim?',
            ),
          );
        }
      }

      final alanFromPending = vixrexNiyetAlanByAnahtar[pending.anahtar];
      if (alanFromPending != null) {
        final resolved = _intentResolver.resolve(trimmed);
        if (resolved == null) {
          final hamDeger =
              alanFromPending.tip == 'acikKapali'
                  ? _extractPipelineValue(trimmed, alanFromPending)
                  : trimmed;
          if (hamDeger == null || hamDeger.trim().isEmpty) {
            return VixrexNluPipelineResult(
              outcome: VixrexNluPipelineOutcome.needsClarification,
              message: ChatMessage.bot(_clarifier.sor(alanFromPending)),
              appliedAnahtar: alanFromPending.anahtar,
            );
          }
          if (needsSpecialFlow != null && needsSpecialFlow(alanFromPending)) {
            return VixrexNluPipelineResult(
              outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
              message: ChatMessage.bot(_clarifier.sor(alanFromPending)),
              appliedAnahtar: alanFromPending.anahtar,
            );
          }
          final validated = await onValidate(alanFromPending, hamDeger);
          if (!validated.ok) {
            return VixrexNluPipelineResult(
              outcome: VixrexNluPipelineOutcome.needsClarification,
              message: ChatMessage.bot(
                _clarifier.hata(validated.hata ?? 'Geçersiz değer.'),
              ),
            );
          }
          if (controller != null) {
            final ok = _executor.execute(
              controller: controller,
              alan: alanFromPending,
              deger: validated.normalizedDeger ?? hamDeger,
            );
            if (!ok) {
              return VixrexNluPipelineResult(
                outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
                message: ChatMessage.bot(_clarifier.sor(alanFromPending)),
                appliedAnahtar: alanFromPending.anahtar,
              );
            }
            await controller.saveLocally();
          }
          await _memory.clearPendingSlot(scope: scope);
          return VixrexNluPipelineResult(
            outcome: VixrexNluPipelineOutcome.handled,
            message: ChatMessage.bot(
              _clarifier.basari(
                alanFromPending,
                (validated.normalizedDeger ?? hamDeger).toString(),
              ),
            ),
            appliedAnahtar: alanFromPending.anahtar,
            appliedDeger: validated.normalizedDeger ?? hamDeger,
          );
        }
      }
    }

    final tumAlanlar = _intentResolver.resolveAll(trimmed);
    if (tumAlanlar.isEmpty) {
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.notUnderstood,
        message: ChatMessage.bot(_clarifier.belirsiz()),
      );
    }

    if (tumAlanlar.length > 1) {
      final basarili = <VixrexNiyetAlan>[];
      final basariliDegerler = <Object>[];
      final hatalar = <String>[];
      for (final a in tumAlanlar) {
        if (needsSpecialFlow != null && needsSpecialFlow(a)) {
          hatalar.add('${a.etiket} için panelden devam et');
          continue;
        }
        final ham = _extractPipelineValue(trimmed, a);
        if (ham == null || ham.trim().isEmpty) {
          hatalar.add('${a.etiket} için değer bulunamadı');
          continue;
        }
        final v = await onValidate(a, ham);
        if (!v.ok) {
          hatalar.add(v.hata ?? '${a.etiket} geçersiz');
          continue;
        }
        if (controller != null) {
          final ok = _executor.execute(
            controller: controller,
            alan: a,
            deger: v.normalizedDeger ?? ham,
          );
          if (!ok) {
            hatalar.add('${a.etiket} için özel akış gerekli');
            continue;
          }
        }
        basarili.add(a);
        basariliDegerler.add(v.normalizedDeger ?? ham);
      }
      if (basarili.isEmpty) {
        return VixrexNluPipelineResult(
          outcome: VixrexNluPipelineOutcome.needsClarification,
          message: ChatMessage.bot(
            hatalar.isNotEmpty ? hatalar.join('\n') : _clarifier.belirsiz(),
          ),
        );
      }
      if (controller != null) await controller.saveLocally();
      await _memory.clearPendingSlot(scope: scope);
      final metin = basarili
          .asMap()
          .entries
          .map(
            (e) =>
                _clarifier.basari(e.value, basariliDegerler[e.key].toString()),
          )
          .join('\n');
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.handled,
        message: ChatMessage.bot(metin),
        appliedAnahtar: basarili.first.anahtar,
        appliedDeger: basariliDegerler.first,
        appliedAnahtarlar: basarili.map((e) => e.anahtar).toList(),
        appliedDegerler: basariliDegerler,
      );
    }
    final alan = tumAlanlar.first;

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
        outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
        message: ChatMessage.bot(_clarifier.sor(alan)),
        appliedAnahtar: alan.anahtar,
      );
    }

    final hamDeger = _extractPipelineValue(trimmed, alan);
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
        outcome: VixrexNluPipelineOutcome.needsClarification,
        message: ChatMessage.bot(_clarifier.sor(alan)),
        appliedAnahtar: alan.anahtar,
      );
    }

    final validated = await onValidate(alan, hamDeger);
    if (!validated.ok) {
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.needsClarification,
        message: ChatMessage.bot(
          _clarifier.hata(validated.hata ?? 'Geçersiz değer.'),
        ),
        appliedAnahtar: alan.anahtar,
      );
    }

    if (controller != null) {
      final ok = _executor.execute(
        controller: controller,
        alan: alan,
        deger: validated.normalizedDeger ?? hamDeger,
      );
      if (!ok) {
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
          outcome: VixrexNluPipelineOutcome.needsSpecialFlow,
          message: ChatMessage.bot(_clarifier.sor(alan)),
          appliedAnahtar: alan.anahtar,
        );
      }
      await controller.saveLocally();
    }

    await _memory.clearPendingSlot(scope: scope);
    return VixrexNluPipelineResult(
      outcome: VixrexNluPipelineOutcome.handled,
      message: ChatMessage.bot(
        _clarifier.basari(
          alan,
          (validated.normalizedDeger ?? hamDeger).toString(),
        ),
      ),
      appliedAnahtar: alan.anahtar,
      appliedDeger: validated.normalizedDeger ?? hamDeger,
    );
  }
}
