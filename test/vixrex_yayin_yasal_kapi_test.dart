import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_canonical_draft_writer.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_conversation_memory.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';

class _EmptyMemory implements VixrexConversationMemoryPort {
  @override
  Future<VixrexPendingSlot?> loadPendingSlot({String? scope}) async => null;

  @override
  Future<void> savePendingSlot(VixrexPendingSlot slot, {String? scope}) async {}

  @override
  Future<void> clearPendingSlot({String? scope}) async {}
}

class _NoWriteWriter extends VixrexCanonicalDraftWriter {
  int writeCount = 0;

  @override
  Future<VixrexCanonicalWriteResult> write({
    required List<VixrexNiyetAlan> alanlar,
    required List<Object?> degerler,
  }) async {
    writeCount += 1;
    return const VixrexCanonicalWriteResult(
      VixrexCanonicalWriteState.written,
      commandId: '00000000-0000-4000-8000-000000000001',
    );
  }
}

Future<({bool ok, String? hata, Object? normalizedDeger})> _validate(
  VixrexNiyetAlan alan,
  String hamDeger,
) async => (ok: true, hata: null, normalizedDeger: hamDeger);

void main() {
  group('Vixrex Flutter yayın ve yasal onay güvenlik kapısı', () {
    test('serbest doğal dil yasal onay veya yayın işlemini çalıştırmaz', () async {
      final writer = _NoWriteWriter();
      final pipeline = VixrexNluPipeline(
        memory: _EmptyMemory(),
        canonicalWriter: writer,
      );

      for (final metin in [
        'Vitrini yayınla',
        'Şartları kabul ediyorum',
        'Yasal onayı ver ve yayınla',
      ]) {
        final sonuc = await pipeline.handle(
          input: metin,
          controller: null,
          onValidate: _validate,
        );
        expect(
          sonuc.outcome,
          isNot(VixrexNluPipelineOutcome.handled),
          reason: metin,
        );
      }

      expect(writer.writeCount, 0);
    });

    test('legal ekranı gerçek kullanıcı onaylarını ve hazır olma kapısını kullanır', () {
      final screen = File(
        'lib/screens/vixrex_onboarding_chat_screen.dart',
      ).readAsStringSync();

      expect(screen, contains('LegalConsentSection('));
      expect(
        screen,
        contains('onPrivacyChanged: _controller.setPrivacyNoticeAcknowledged'),
      );
      expect(screen, contains('onTermsChanged: _controller.setTermsAccepted'));
      expect(
        screen,
        contains('onPublicationChanged: _controller.setPublicationConsentAccepted'),
      );
      expect(screen, contains('busy || !_controller.isLegalPublishReady'));
      expect(screen, contains(': _onboarding.acceptLegalAndPublish'));
    });

    test('controller yayın çağrısından önce legal readiness kontrolünü yapar', () {
      final source = File(
        'lib/controllers/vixrex_onboarding_controller.dart',
      ).readAsStringSync();
      final methodStart = source.indexOf('Future<void> acceptLegalAndPublish()');
      final readiness = source.indexOf(
        'if (!_editor.isLegalPublishReady)',
        methodStart,
      );
      final publish = source.indexOf('await _editor.publish()', methodStart);

      expect(methodStart, greaterThanOrEqualTo(0));
      expect(readiness, greaterThan(methodStart));
      expect(publish, greaterThan(readiness));
    });
  });
}
