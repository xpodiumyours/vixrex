import 'package:vixrex/config/vitrin_alanlari.g.dart';
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
  final ChatMessage message; // asistanın cevabı
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

  /// Ana giriş – sohbetten çağrılır.
  /// `scope` = ChatbotService._historyKeyFor ile aynı (publicLink base64 veya local).
  /// `onValidate` = Next.js tarafındaki validateField’a eşdeğer Dart doğrulama (tip/min/max/tr_mobil/url).
  ///   Faz 1’de Flutter için: basit tip kontrolü, tam doğrulama `controller.updateField` içinde zaten var.
  Future<VixrexNluPipelineResult> handle({
    required String input,
    required StoreEditorController? controller,
    String? scope,
    required Future<({bool ok, String? hata, Object? normalizedDeger})>
    Function(VixrexNiyetAlan alan, String hamDeger)
    onValidate,
    bool Function(VixrexNiyetAlan alan)?
    needsSpecialFlow, // il/ilce/kategori listeden seç, gorsel yükle vb.
  }) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.notUnderstood,
        message: ChatMessage.bot(_clarifier.belirsiz()),
      );
    }

    final norm = VixrexNormalizer.normalize(trimmed);

    // 0) Evet/hayır – bekleyen slot varsa onayla/iptal et.
    final pending = await _memory.loadPendingSlot(scope: scope);
    if (pending != null) {
      if (_evetler.contains(norm) || _hayirlar.contains(norm)) {
        // Evet/hayır tek başına eski bir soruya cevap değilse yutma.
        // Pending varsa evet/hayır’ı ona bağla.
        if (_evetler.contains(norm)) {
          // Evet → pending’teki değeri tekrar doğrula ve uygula (deger pending’te tutulmadığı için
          // Faz 1’de pending sadece anahtar tutar – değer bir önceki turda yoktu, bu yüzden
          // "evet" tek başına yetmez, tekrar değer istenmeli). Basit: pending’i temizle ve
          // netleştirme sorusunu tekrar sor.
          // Faz 1 dar: pending sadece "hangi alan" beklerken, evet/hayır anlamlı değil – belirsiz dön.
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
      // Pending varken yeni mesajda alan bulunamazsa → pending’teki alana değer olarak dene.
      final alanFromPending = vixrexNiyetAlanByAnahtar[pending.anahtar];
      if (alanFromPending != null) {
        final resolved = _intentResolver.resolve(trimmed);
        if (resolved == null) {
          // Yeni alan yok → ham mesajı pending alanın değeri say.
          final hamDeger = trimmed;
          // Özel akış gerektiriyorsa (il/ilce) → needsSpecialFlow
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
          // Controller yoksa (Next.js tarafı) – sadece doğrula, uygulama çağıran tarafta.
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

    // 1) Alan bul – Faz 3 çok-alanlı: birden fazla alan varsa hepsini dene.
    final tumAlanlar = _intentResolver.resolveAll(trimmed);
    if (tumAlanlar.isEmpty) {
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.notUnderstood,
        message: ChatMessage.bot(_clarifier.belirsiz()),
      );
    }
    // Çok-alanlı: 2+ alan ve her biri için değer varsa toplu işle (Faz 3).
    if (tumAlanlar.length > 1) {
      final basarili = <VixrexNiyetAlan>[];
      final basariliDegerler = <Object>[];
      final hatalar = <String>[];
      for (final a in tumAlanlar) {
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

    // 1b) Yasal alanlar bu borudan yasak – mevcut legal akışa yönlendir.
    // Sözlükte yasal alanlar yok, bu dal Faz 1’de ölü – fakat emniyet için kontrol.
    const yasakAlanlar = {
      'isletmeAdi': false,
    }; // placeholder, gerçek yasak sözlükte yok

    // 2) Özel akış gerektiren alanlar (il/ilce → listeden seç, gorsel → yükle)
    if (needsSpecialFlow != null && needsSpecialFlow(alan)) {
      // Değer varsa bile özel akış – serbest metinle il/ilçe yazımı Faz 1’de desteklenmiyor.
      // Pending’e al ve yönlendir.
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

    // 3) Değer ayıkla.
    final hamDeger = _valueExtractor.extract(trimmed, alan);
    if (hamDeger == null || hamDeger.trim().isEmpty) {
      // Değer yok → netleştirme sor.
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

    // 4) Doğrulama – çağıranın validateField’ı (Flutter/Next.js aynı kural).
    final validated = await onValidate(alan, hamDeger);
    if (!validated.ok) {
      // Doğrulama hatası → hata mesajı + pending’i koru (tekrar deneme için).
      // Faz 1’de deneme sayısını artırmıyoruz, sadece aynı soruyu tekrar sormuyoruz – hatayı göster.
      return VixrexNluPipelineResult(
        outcome: VixrexNluPipelineOutcome.needsClarification,
        message: ChatMessage.bot(
          _clarifier.hata(validated.hata ?? 'Geçersiz değer.'),
        ),
        appliedAnahtar: alan.anahtar,
      );
    }

    // 5) İşlem – mevcut Vixrex işlemi.
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
    } else {
      // Next.js tarafı – controller yok, doğrulama sonrası çağıran `update_working_draft_field`’i çağıracak.
      // Burada sadece boru sonucunu dönüyoruz.
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
