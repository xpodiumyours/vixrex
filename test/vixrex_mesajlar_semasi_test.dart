import 'package:flutter_test/flutter_test.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';

/// Tek mesaj kataloğu — sayı kilidi (Tek Asistan planı, Faz B).
///
/// Plan doğrulama notu: "Mesaj sayısı testle kilitlenir." Üretilen dosya
/// (lib/config/vixrex_mesajlar.g.dart) elle düzenlenmez; sayı değişmişse ya
/// şema (shared/vixrex_mesajlar.json) değişmiş ya da üretim adımı atlanmış
/// demektir.
void main() {
  test('intent ve mesaj sayısı kilitli', () {
    expect(vixRexIntentSemasi.length, 16);
    expect(vixRexMesajlari.length, 20);
  });
}
