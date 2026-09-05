import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_decision_contract.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_field_validator.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_nlu_pipeline.dart';

void main() {
  test('günsüz çalışma saati cümlesi generic mutation üretmez', () async {
    SharedPreferences.setMockInitialValues({});
    final pipeline = VixrexNluPipeline();

    final result = await pipeline.handle(
      input: 'Çalışma saatlerini 09:00-18:00 yap',
      controller: null,
      onValidate: (alan, ham) async {
        final validation = VixrexFieldValidator.validate(alan, ham);
        return (
          ok: validation.ok,
          hata: validation.hata,
          normalizedDeger: validation.normalizedDeger,
        );
      },
    );

    expect(result.decision, VixrexDecisionKind.needsSpecialFlow);
    expect(result.outcome, VixrexNluPipelineOutcome.needsSpecialFlow);
    expect(result.actions, isEmpty);
    expect(result.appliedAnahtar, 'calismaSaatleri');
    expect(result.message.text.contains('Hangi günler'), true);
    expect(result.message.text.contains('Kaydettim'), false);
  });
}
