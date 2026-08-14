import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vixrex/services/chatbot_service.dart';
import 'package:vixrex/services/sohbet_gecmisi_gocu.dart';

/// Faz C (Tek Asistan planı) doğrulama notu: "üç senaryo elle — (a) hiç
/// geçmiş, (b) yalnız eski anahtar, (c) v2 scope'lu geçmiş. Üçünde de
/// sohbet kaybolmadan açılmalı." Elle test edilemediği için burada
/// otomatik karşılığı yazılıyor.
void main() {
  const eskiScopesuzAnahtar = 'vixrex_chat_history';
  const eskiScopluOnEk = 'vixrex_chat_history_v2_';
  const yeniOnEk = 'vixrex_sohbet_v3_';

  String kodla(String scope) =>
      base64Url.encode(utf8.encode(scope)).replaceAll('=', '');

  String ornekMesajJson(String metin) =>
      '[{"id":"1","text":"$metin","isBot":true,"timestamp":"2026-01-01T00:00:00.000","type":"text","quickReplies":[]}]';

  test('(a) hiç geçmiş yokken göç sessizce çıkar', () async {
    SharedPreferences.setMockInitialValues({});
    await SohbetGecmisiGocu.calistir();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('vixrex_gecmis_goc_v3'), isTrue);
    expect(await ChatbotService().loadHistory(), isEmpty);
  });

  test("(b) yalnız eski (scope'suz) anahtar → local scope'a taşınır", () async {
    SharedPreferences.setMockInitialValues({
      eskiScopesuzAnahtar: ornekMesajJson('Eski mesaj'),
    });
    await SohbetGecmisiGocu.calistir();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(eskiScopesuzAnahtar), isFalse);
    expect(prefs.getString('${yeniOnEk}local'), isNotNull);

    final history = await ChatbotService().loadHistory();
    expect(history, hasLength(1));
    expect(history.single.text, 'Eski mesaj');
  });

  test("(c) v2 scope'lu geçmiş → aynı scope'ta v3'e taşınır", () async {
    final kodluScope = kodla('test-slug');
    SharedPreferences.setMockInitialValues({
      '$eskiScopluOnEk$kodluScope': ornekMesajJson('Yayinli magaza mesaji'),
    });
    await SohbetGecmisiGocu.calistir();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('$eskiScopluOnEk$kodluScope'), isFalse);
    expect(prefs.getString('$yeniOnEk$kodluScope'), isNotNull);

    final history = await ChatbotService().loadHistory(scope: 'test-slug');
    expect(history, hasLength(1));
    expect(history.single.text, 'Yayinli magaza mesaji');
  });

  test(
    'göç ikinci kez çalıştırılınca bayrak sayesinde hiçbir şey yapmaz',
    () async {
      SharedPreferences.setMockInitialValues({
        eskiScopesuzAnahtar: ornekMesajJson('Silinmemesi gereken'),
        'vixrex_gecmis_goc_v3': true,
      });
      await SohbetGecmisiGocu.calistir();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(eskiScopesuzAnahtar), isTrue);
    },
  );

  test("yerel geçmiş, yayına geçilince scope'a bir kez taşınır", () async {
    SharedPreferences.setMockInitialValues({
      '${yeniOnEk}local': ornekMesajJson('Yerel sohbet'),
    });
    final service = ChatbotService();

    await service.migrateLocalToPublishedScope('yeni-yayinlanan-slug');

    expect(await service.loadHistory(), isEmpty);
    final yayinHistory = await service.loadHistory(
      scope: 'yeni-yayinlanan-slug',
    );
    expect(yayinHistory, hasLength(1));
    expect(yayinHistory.single.text, 'Yerel sohbet');

    // İkinci çağrı — hedefte zaten veri var, dokunmaz, üzerine yazmaz.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${yeniOnEk}local',
      ornekMesajJson('Ikinci yerel mesaj'),
    );
    await service.migrateLocalToPublishedScope('yeni-yayinlanan-slug');
    final yayinHistorySonra = await service.loadHistory(
      scope: 'yeni-yayinlanan-slug',
    );
    expect(yayinHistorySonra, hasLength(1));
    expect(yayinHistorySonra.single.text, 'Yerel sohbet');
  });
}
