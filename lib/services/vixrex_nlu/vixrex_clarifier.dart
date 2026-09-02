import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/config/vixrex_mesajlar.g.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';

/// Netleştirme mesajları – katalogdan, hard-code değil.
/// shared/vixrex_mesajlar.json’daki netlestirme_* anahtarları kullanılır.
class VixrexClarifier {
  const VixrexClarifier();

  String _mesaj(String anahtar) => vixRexMesajlari[anahtar] ?? anahtar;

  String _doldur(String sablon, Map<String, String> degisim) {
    var out = sablon;
    degisim.forEach((k, v) {
      out = out.replaceAll('{$k}', v);
    });
    return out;
  }

  /// Değer yok → sor. ipucu varsa `netlestirme_sor`, yoksa `netlestirme_sor_genel`.
  String sor(VixrexNiyetAlan alan) {
    final ipucu = alanAnahtarla[alan.anahtar]?.ipucu?.trim() ?? '';
    if (ipucu.isNotEmpty) {
      return _doldur(_mesaj('netlestirme_sor'), {
        'etiket': alan.etiket,
        'ipucu': ipucu,
      });
    }
    return _doldur(_mesaj('netlestirme_sor_genel'), {'etiket': alan.etiket});
  }

  /// Değer var ama belirsiz → onay sor.
  String onay(VixrexNiyetAlan alan, String deger) {
    return _doldur(_mesaj('netlestirme_onay'), {
      'etiket': alan.etiket,
      'deger': deger,
    });
  }

  /// Başarı → `netlestirme_basari`.
  String basari(VixrexNiyetAlan alan, String deger) {
    return _doldur(_mesaj('netlestirme_basari'), {
      'etiket': alan.etiket,
      'deger': deger,
    });
  }

  /// Doğrulama hatası → `netlestirme_hata` içinde hata metni.
  String hata(String hataMetni) {
    return _doldur(_mesaj('netlestirme_hata'), {'hata': hataMetni});
  }

  /// Alan bulunamadı → genel netleştirme.
  String belirsiz() => _mesaj('netlestirme_belirsiz');
}
