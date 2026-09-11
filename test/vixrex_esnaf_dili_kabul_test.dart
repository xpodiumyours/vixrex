import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_canonical_draft_writer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';

class _FakeMemory implements VixrexConversationMemoryPort {
  VixrexPendingSlot? slot;

  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async => slot;

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {
    this.slot = slot;
  }

  @override
  Future<void> clearPendingSlot({String? scope}) async {
    slot = null;
  }
}

class _FakeWriter extends VixrexCanonicalDraftWriter {
  int writeCount = 0;
  List<Object?>? lastValues;

  @override
  Future<VixrexCanonicalWriteResult> write({
    required List<VixrexNiyetAlan> alanlar,
    required List<Object?> degerler,
  }) async {
    writeCount += 1;
    lastValues = List<Object?>.from(degerler);
    return const VixrexCanonicalWriteResult(
      VixrexCanonicalWriteState.written,
      commandId: '00000000-0000-4000-8000-000000000046',
    );
  }
}

Future<({bool ok, String? hata, Object? normalizedDeger})> _validate(
  VixrexNiyetAlan alan,
  String hamDeger,
) async {
  return VixrexFieldValidator.validate(alan, hamDeger);
}

void main() {
  final raw =
      jsonDecode(File('shared/vixrex_esnaf_dili_kabul.json').readAsStringSync())
          as Map<String, dynamic>;
  final senaryolar =
      (raw['senaryolar'] as List<dynamic>).cast<Map<String, dynamic>>();

  group('Araştırma temelli esnaf dili — Flutter gerçek pipeline', () {
    test('ortak kabul kümesi 46 alanın tamamını kapsar', () {
      expect(senaryolar.length, 46);
      expect(senaryolar.map((s) => s['anahtar']).toSet().length, 46);
    });

    for (final s in senaryolar) {
      test('${s['anahtar']}: ${s['cumle']}', () async {
        final memory = _FakeMemory();
        final writer = _FakeWriter();
        final pipeline = VixrexNluPipeline(
          memory: memory,
          canonicalWriter: writer,
        );

        final sonuc = await pipeline.handle(
          input: s['cumle'] as String,
          controller: null,
          onValidate: _validate,
          needsSpecialFlow:
              (alan) => alan.anahtar == 'il' || alan.anahtar == 'ilce',
        );

        final beklenenOutcome =
            s['outcome'] == 'handled'
                ? VixrexNluPipelineOutcome.handled
                : VixrexNluPipelineOutcome.needsSpecialFlow;
        expect(sonuc.outcome, beklenenOutcome);
        expect(sonuc.appliedAnahtar, s['anahtar']);

        if (s['outcome'] == 'handled') {
          expect(sonuc.appliedDeger, s['deger']);
          expect(writer.writeCount, 1);
          expect(writer.lastValues, [s['deger']]);
        } else {
          expect(writer.writeCount, 0);
        }
      });
    }
  });
}
