import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';

/// Play Store ödeme politikası kalkanı: asistanın GÖRÜNEN metinlerinde
/// premium üyelik, ücret/ödeme, fiyat vaadi veya satın alma çağrışımı kalmaz.
/// Makine adları (payload/intent anahtarları) kapsam dışıdır.
void main() {
  test('görünen asistan metinleri ödeme/promosyon içermiyor', () {
    final yasakli = RegExp(
      r'premium|ücretli|ücretsiz|ucretli|ucretsiz|ödeme|odeme|paytr|satın al|satinal|aylık\s*\d|\b\d+\s*TL\b',
      caseSensitive: false,
    );
    final ihlaller = <String>[];

    vixRexMesajlari.forEach((anahtar, metin) {
      if (yasakli.hasMatch(metin)) ihlaller.add('mesaj:$anahtar');
    });
    for (final secenek in vixRexHizliSecenekler) {
      if (yasakli.hasMatch(secenek.etiket)) {
        ihlaller.add('hizliSecenek:${secenek.etiket}');
      }
    }
    for (final yanit in vixRexYanitlar.values) {
      for (final hizli in yanit.hizli) {
        if (yasakli.hasMatch(hizli.etiket)) {
          ihlaller.add('yanit:${hizli.etiket}');
        }
      }
    }

    expect(
      ihlaller,
      isEmpty,
      reason: 'Play Billing olmadan ödeme/üyelik vaadi verilmez: $ihlaller',
    );
  });
}
