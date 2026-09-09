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
    // 2026-09-09: uygulama içi asistanda "Sıfırdan Oluştur" butonu
    // seçeneğin etiketini konuşmaya düşürüyor; katalogda karşılığı
    // olmadığı için asistan "anlaşılamadı" diyordu. `vitrin_kurulum`
    // niyeti eklendi — 16 → 17.
    expect(vixRexIntentSemasi.length, 17);
    // 2026-08-27: landing asistanı gerçek hâle getirilirken kapanış
    // mesajları eklendi (landing_finish_baslik/aciklama/buton) — 96 → 99.
    // Blog yayınlama sonucu iki yüzeyde ortaklaştırıldı — 99 → 100.
    // Faz 1 NLU netleştirme mesajları eklendi (netlestirme_sor/sor_genel/onay/basari/hata/belirsiz) — 100 → 106.
    // Akış 1 paritesi (2026-09-03): "Hazır Vitrin Seç" niyet sorusu iki
    // yüzeyde de katalogdan konuşsun diye niyet_kategori_baslik/aciklama,
    // niyet_geri_buton, niyet_anlat_buton, niyet_serbest_yertutucu,
    // niyet_ack eklendi — 106 → 112.
    // Akış 3 paritesi (2026-09-03): yayın-sonrası hesap bağlama paneli iki
    // yüzeyde de katalogdan konuşsun diye hesap_bagla_baslik/aciklama/
    // buton/yukleniyor/hata eklendi — 112 → 117.
    // Sayı kilidi bilerek duruyor: katalog sessizce büyümesin.
    expect(vixRexMesajlari.length, 117);
  });
}
