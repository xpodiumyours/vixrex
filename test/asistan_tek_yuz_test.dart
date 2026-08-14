import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Asistanın tek yüzü — nöbetçi (tur bulgusu 16).
///
/// 2026-08-07: maskot iki ayrı yerde ayrı ayrı çiziliyordu. Uygulama içi
/// asistanda her bot mesajının başında 28 piksellik avatar vardı; kurulum
/// sohbetinde hiç yoktu. Aynı Vixrex, iki farklı yüz.
///
/// Casper: "uygulama içinde her cümlesinin başında vixrex maskotu var,
/// diğer ekranda yok."
///
/// 6 Ağustos'ta "tek asistan" kararıyla DİL birleştirilmişti ("sen"
/// kipi); görünüm birleştirilmemişti — karar yarım kalmıştı.
void main() {
  final kok = Directory.current.path;
  String oku(String yol) => File('$kok/$yol').readAsStringSync();

  test('maskot tek bir bileşenden geliyor', () {
    expect(File('$kok/lib/widgets/vixrex_avatar.dart').existsSync(), isTrue);
  });

  test('iki yüzey de aynı bileşeni kullanıyor', () {
    // Faz A (Tek Asistan planı, sohbet görünüm sözlüğü): avatar artık
    // doğrudan değil, paylaşılan ChatBubble/ChatTopBar üzerinden geliyor.
    // vixrex_message_bubble.dart (eski VixRexBotMessage/UserMessage) tamamen
    // kaldırıldı; tek çizim kaynağı lib/widgets/chat/ altındaki bu iki
    // dosya. Çağıran ekranların (onboarding, companion sohbet) bunları
    // içe aktarması yeterli — kendi başlarına maskot çizmemeleri önemli.
    for (final dosya in ['chat_bubble.dart', 'chat_top_bar.dart']) {
      expect(
        oku('lib/widgets/chat/$dosya'),
        contains('VixrexAvatar'),
        reason: '$dosya artık maskotu VixrexAvatar üzerinden çizmiyor.',
      );
    }
    for (final yol in [
      'lib/screens/vixrex_onboarding_chat_screen.dart',
      'lib/widgets/vixrex/vixrex_companion_chat.dart',
    ]) {
      final icerik = oku(yol);
      expect(
        icerik.contains("widgets/chat/chat_bubble.dart") ||
            icerik.contains("widgets/chat/chat_top_bar.dart"),
        isTrue,
        reason: '$yol paylaşılan sohbet bileşenlerini içe aktarmıyor.',
      );
    }
  });

  test('maskot görseli başka yerde elle çizilmiyor', () {
    // Görsel adı yalnız VixrexAvatar içinde geçmeli. Başka bir dosyada
    // geçiyorsa orada ikinci bir yüz var demektir ve zamanla ayrışır.
    final sapanlar = <String>[];
    for (final dosya in Directory('$kok/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      if (dosya.path.endsWith('vixrex_avatar.dart')) continue;
      final icerik = dosya.readAsStringSync();
      // Yorum satırları sayılmaz.
      final kod = icerik
          .split('\n')
          .where((s) => !s.trimLeft().startsWith('//'))
          .join('\n');
      if (kod.contains('vixrex_v_crystal_mascot.png')) {
        // ChatbotBadge yüzen düğme: kendi nabzı ve tarama animasyonu var,
        // görseli o katmanların içine gömülü. Bilinçli olarak ayrı kalır.
        if (dosya.path.endsWith('chatbot_badge.dart')) continue;
        sapanlar.add(dosya.uri.pathSegments.last);
      }
    }
    expect(
      sapanlar,
      isEmpty,
      reason: 'Maskot şu dosyalarda elle çiziliyor: ${sapanlar.join(", ")}',
    );
  });
}
