import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/controllers/store_editor_controller.dart';
import 'package:vixrex/controllers/vixrex_onboarding_controller.dart';

/// Akış 1 paritesi (2026-09-03): "Hazır Vitrin Seç" artık doğrudan Keşfet'e
/// gitmez — önce niyet sorusu adımı açılır (Web C1 karşılığı). Bu testler
/// adım makinesinin geçişlerini ve Keşfet'e taşınan kategori etiketini kilitler.
void main() {
  late List<String> botMessages;
  late List<String> userMessages;
  late List<String?> pickerCalls;
  late VixRexOnboardingController onboarding;

  setUp(() {
    botMessages = [];
    userMessages = [];
    pickerCalls = [];
    onboarding = VixRexOnboardingController(
      editorController: StoreEditorController(),
      onBotMessage: (text, {publicLink}) => botMessages.add(text),
      onUserMessage: (text) => userMessages.add(text),
      onPersistTranscript: () async {},
      onChooseReadyTemplate:
          (kategoriEtiketi) => pickerCalls.add(kategoriEtiketi),
    );
  });

  test('katalogda niyet metinleri var', () {
    expect(vixRexMesajlari['niyet_kategori_baslik'], 'Ne iş yapıyorsun?');
    expect(
      vixRexMesajlari['niyet_kategori_aciklama'],
      "İşine uygun hazır vitrinleri Keşfet'ten göstereyim.",
    );
    expect(vixRexMesajlari['niyet_geri_buton'], '‹ Geri');
    expect(vixRexMesajlari['niyet_anlat_buton'], 'Anlat ve devam et');
    expect(
      vixRexMesajlari['niyet_ack'],
      'Anlattıklarını not aldım — vitrinini seçtiğinde bunlardan otomatik dolduracağım.',
    );
  });

  test('chooseReadyTemplate soruyu açar, Keşfet\'e hemen gitmez', () {
    onboarding.chooseReadyTemplate();

    expect(onboarding.step, VixRexOnboardingStep.templateNiyet);
    expect(pickerCalls, isEmpty);
    expect(userMessages.last, 'Hazır bir vitrin görmek istiyorum');
    expect(botMessages.last, contains('Ne iş yapıyorsun?'));
    expect(
      botMessages.last,
      contains("İşine uygun hazır vitrinleri Keşfet'ten göstereyim."),
    );
  });

  test('selectTemplateCategory etiketi Keşfet\'e taşır', () {
    onboarding.chooseReadyTemplate();
    onboarding.selectTemplateCategory('Giyim');

    expect(pickerCalls, ['Giyim']);
    expect(userMessages.last, 'Giyim');
    expect(
      botMessages.last,
      'Giyim işletmesine uygun hazır vitrinleri buldum.',
    );
  });

  test('cancelTemplateNiyet karşılamaya döner, satır eklemez', () {
    onboarding.chooseReadyTemplate();
    final botSayisi = botMessages.length;
    final userSayisi = userMessages.length;

    onboarding.cancelTemplateNiyet();

    expect(onboarding.step, VixRexOnboardingStep.welcome);
    expect(botMessages.length, botSayisi);
    expect(userMessages.length, userSayisi);
    expect(pickerCalls, isEmpty);
  });

  test('submitTemplateFreeText boşken reddeder', () async {
    onboarding.chooseReadyTemplate();

    expect(await onboarding.submitTemplateFreeText('   '), isFalse);
    expect(pickerCalls, isEmpty);
  });

  test('submitTemplateFreeText bilinmeyende süzgeçsiz açar', () async {
    onboarding.chooseReadyTemplate();

    expect(
      await onboarding.submitTemplateFreeText('kuaför salonu işletiyorum'),
      isTrue,
    );
    expect(pickerCalls, [null]);
    expect(
      botMessages.last,
      'Anlattıklarını not aldım — vitrinini seçtiğinde bunlardan otomatik dolduracağım.',
    );
  });

  test('submitTemplateFreeText etiket eşleşirse filtreler', () async {
    onboarding.chooseReadyTemplate();

    expect(await onboarding.submitTemplateFreeText('giyim'), isTrue);
    expect(pickerCalls, ['Giyim']);
  });

  test('templateKategoriCoz Türkçe duyarsız eşleşir', () {
    expect(onboarding.templateKategoriCoz('Giyim'), 'Giyim');
    expect(onboarding.templateKategoriCoz('  giyim  '), 'Giyim');
    expect(onboarding.templateKategoriCoz('GİYİM'), 'Giyim');
    expect(onboarding.templateKategoriCoz('uzay üssü'), isNull);
    expect(onboarding.templateKategoriCoz('   '), isNull);
  });

  test('onSend niyet adımında serbest metne gider', () async {
    onboarding.chooseReadyTemplate();

    await onboarding.onSend('giyim');

    expect(pickerCalls, ['Giyim']);
  });

  test('baglaniyor baslangicta false (Akış 3: baglama etiketi katalogdan)', () {
    // hesabiBagla() Supabase gerektirir — burada yalnız başlangıç
    // durumu kilitlenir; düğme etiketi baglaniyor'a göre seçilir.
    expect(onboarding.baglaniyor, isFalse);
    expect(onboarding.busy, isFalse);
  });
}
