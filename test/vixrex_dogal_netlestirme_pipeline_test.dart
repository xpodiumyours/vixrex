import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_canonical_draft_writer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';

class _FakeMemory implements VixrexConversationMemoryPort {
  _FakeMemory(this.slot);

  VixrexPendingSlot? slot;
  int clearCount = 0;

  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async => slot;

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {
    this.slot = slot;
  }

  @override
  Future<void> clearPendingSlot({String? scope}) async {
    clearCount += 1;
    slot = null;
  }
}

class _FakeWriter extends VixrexCanonicalDraftWriter {
  _FakeWriter();

  int writeCount = 0;
  List<Object?>? lastValues;

  @override
  Future<VixrexCanonicalWriteResult> write({
    required List<VixrexNiyetAlan> alanlar,
    required List<Object?> degerler,
  }) async {
    writeCount += 1;
    lastValues = degerler;
    return const VixrexCanonicalWriteResult(
      VixrexCanonicalWriteState.written,
      commandId: '00000000-0000-4000-8000-000000000001',
    );
  }
}

VixrexPendingSlot _slot(
  String anahtar,
  String etiket,
  String tip, {
  String? eylem,
}) {
  return VixrexPendingSlot(
    anahtar: anahtar,
    etiket: etiket,
    tip: tip,
    sorulduAt: DateTime(2026, 9, 10),
    eylem: eylem,
  );
}

Future<({bool ok, String? hata, Object? normalizedDeger})> _validate(
  VixrexNiyetAlan alan,
  String hamDeger,
) async {
  if (hamDeger.isEmpty) {
    return (ok: true, hata: null, normalizedDeger: null);
  }
  if (alan.tip == 'acikKapali') {
    if (hamDeger == 'true') {
      return (ok: true, hata: null, normalizedDeger: true);
    }
    if (hamDeger == 'false') {
      return (ok: true, hata: null, normalizedDeger: false);
    }
  }
  return (ok: true, hata: null, normalizedDeger: hamDeger);
}

void main() {
  group('Vixrex doğal netleştirme gerçek Flutter pipeline', () {
    test('bağlam yok ve cümle anlaşılmıyorsa teknik alan adı sormaz', () async {
      final memory = _FakeMemory(null);
      final writer = _FakeWriter();
      final pipeline = VixrexNluPipeline(
        memory: memory,
        canonicalWriter: writer,
      );

      final sonuc = await pipeline.handle(
        input: 'bunu farklı yap',
        controller: null,
        onValidate: _validate,
      );

      expect(sonuc.outcome, VixrexNluPipelineOutcome.notUnderstood);
      expect(sonuc.message.text, 'Vitrininde neyi farklı görmek istersin?');
      expect(sonuc.message.text.toLowerCase(), isNot(contains('hangi alan')));
      expect(writer.writeCount, 0);
    });

    test("bağlam yokken 'telefonu değiştirme' yazma isteği sayılmaz", () async {
      final memory = _FakeMemory(null);
      final writer = _FakeWriter();
      final pipeline = VixrexNluPipeline(
        memory: memory,
        canonicalWriter: writer,
      );

      final sonuc = await pipeline.handle(
        input: 'telefonu değiştirme',
        controller: null,
        onValidate: _validate,
      );

      expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
      expect(sonuc.message.text, contains('değişiklik yapmıyorum'));
      expect(writer.writeCount, 0);
    });

    test(
      "telefon beklenirken 'değiştirme' işlemi iptal eder ve bekleyen soruyu temizler",
      () async {
        final memory = _FakeMemory(_slot('telefon', 'Telefon', 'telefon'));
        final writer = _FakeWriter();
        final pipeline = VixrexNluPipeline(
          memory: memory,
          canonicalWriter: writer,
        );

        final sonuc = await pipeline.handle(
          input: 'değiştirme',
          controller: null,
          onValidate: _validate,
        );

        expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
        expect(sonuc.message.text, contains('bu değişikliği yapmıyorum'));
        expect(memory.clearCount, 1);
        expect(memory.slot, isNull);
        expect(writer.writeCount, 0);
      },
    );

    test(
      "telefon beklenirken 'evet' telefon değeri diye yazılmaz ve bağlam silinmez",
      () async {
        final memory = _FakeMemory(_slot('telefon', 'Telefon', 'telefon'));
        final writer = _FakeWriter();
        final pipeline = VixrexNluPipeline(
          memory: memory,
          canonicalWriter: writer,
        );

        final sonuc = await pipeline.handle(
          input: 'evet',
          controller: null,
          onValidate: _validate,
        );

        expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
        expect(sonuc.appliedAnahtar, 'telefon');
        expect(sonuc.message.text, 'Telefon için ne yazayım?');
        expect(memory.clearCount, 0);
        expect(writer.writeCount, 0);
      },
    );

    test(
      "aç/kapa sorusunda 'evet' önceki soruyla true olarak çözülür",
      () async {
        final memory = _FakeMemory(
          _slot('puanGoster', 'Değerlendirme Puanını Göster', 'acikKapali'),
        );
        final writer = _FakeWriter();
        final pipeline = VixrexNluPipeline(
          memory: memory,
          canonicalWriter: writer,
        );

        final sonuc = await pipeline.handle(
          input: 'evet',
          controller: null,
          onValidate: _validate,
        );

        expect(sonuc.outcome, VixrexNluPipelineOutcome.handled);
        expect(sonuc.appliedAnahtar, 'puanGoster');
        expect(sonuc.appliedDeger, true);
        expect(memory.clearCount, 1);
        expect(writer.writeCount, 1);
      },
    );

    test("'onu kaldır' kaldırma onayı bağlamını hafızada korur", () async {
      final memory = _FakeMemory(_slot('telefon', 'Telefon', 'telefon'));
      final writer = _FakeWriter();
      final pipeline = VixrexNluPipeline(
        memory: memory,
        canonicalWriter: writer,
      );

      final sonuc = await pipeline.handle(
        input: 'onu kaldır',
        controller: null,
        onValidate: _validate,
      );

      expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
      expect(sonuc.message.text, 'Telefon bilgisini kaldırmamı mı istiyorsun?');
      expect(memory.slot?.eylem, 'kaldir');
      expect(writer.writeCount, 0);
    });

    test(
      "kaldırma onayı beklenirken 'evet' gerçek temizleme değerine dönüşür",
      () async {
        final memory = _FakeMemory(
          _slot('telefon', 'Telefon', 'telefon', eylem: 'kaldir'),
        );
        final writer = _FakeWriter();
        final pipeline = VixrexNluPipeline(
          memory: memory,
          canonicalWriter: writer,
        );

        final sonuc = await pipeline.handle(
          input: 'evet',
          controller: null,
          onValidate: _validate,
        );

        expect(sonuc.outcome, VixrexNluPipelineOutcome.handled);
        expect(sonuc.appliedAnahtar, 'telefon');
        expect(sonuc.appliedDeger, isNull);
        expect(sonuc.message.text, 'Telefon bilgisini kaldırdım.');
        expect(writer.lastValues, [null]);
        expect(memory.clearCount, 1);
      },
    );

    test('yalnız kapanış saati tam çalışma saati diye kaydedilmez', () async {
      final memory = _FakeMemory(
        _slot('calismaSaatleri', 'Çalışma Saatleri', 'metin'),
      );
      final writer = _FakeWriter();
      final pipeline = VixrexNluPipeline(
        memory: memory,
        canonicalWriter: writer,
      );

      final sonuc = await pipeline.handle(
        input: 'akşam yedi',
        controller: null,
        onValidate: _validate,
      );

      expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
      expect(sonuc.message.text, contains('kaçta açıp kaçta kapandığınızı'));
      expect(memory.clearCount, 0);
      expect(writer.writeCount, 0);
    });

    test('yalnız ilçe tam açık adres diye kaydedilmez', () async {
      final memory = _FakeMemory(_slot('adres', 'Açık Adres', 'uzunMetin'));
      final writer = _FakeWriter();
      final pipeline = VixrexNluPipeline(
        memory: memory,
        canonicalWriter: writer,
      );

      final sonuc = await pipeline.handle(
        input: 'Bağcılar',
        controller: null,
        onValidate: _validate,
      );

      expect(sonuc.outcome, VixrexNluPipelineOutcome.needsClarification);
      expect(
        sonuc.message.text,
        'Açık adresi biraz daha ayrıntılı yazar mısın?',
      );
      expect(memory.clearCount, 0);
      expect(writer.writeCount, 0);
    });
  });
}
