import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

class VixrexBekleyenBaglam {
  final String anahtar;
  final String etiket;
  final String tip;
  final String? eylem;

  const VixrexBekleyenBaglam({
    required this.anahtar,
    required this.etiket,
    required this.tip,
    this.eylem,
  });
}

enum VixrexBaglamKarari {
  genelSor,
  ozelSor,
  ayniKalsin,
  kaldirmaOnayi,
  kaldir,
  iptal,
  boolTrue,
  boolFalse,
  saatEksik,
  adresEksik,
  deger,
}

class VixrexBaglamSonucu {
  final VixrexBaglamKarari karar;
  final bool yazma;
  final String mesaj;
  final Object? deger;

  const VixrexBaglamSonucu({
    required this.karar,
    required this.yazma,
    required this.mesaj,
    this.deger,
  });
}

const vixrexDogalGenelSoru = 'Vitrininde neyi farklı görmek istersin?';

const _iptal = {'iptal', 'vazgec', 'vazgectim'};
const _evet = {'evet'};
const _hayir = {'hayir'};
const _ayni = {'aynisi', 'aynen aynisi'};
const _degerOlmayanKisa = {
  'tamam',
  'olur',
  'peki',
  'aynen',
  'degistir',
  'degissin',
  'yap',
};

String _alanSorusu(VixrexBekleyenBaglam bekleyen) =>
    '${bekleyen.etiket} için ne yazayım?';

bool _calismaSaatiTamMi(String input) {
  final norm = VixrexNormalizer.normalize(input);
  if (RegExp(r'\b24\s*saat\b').hasMatch(norm) ||
      RegExp(r'\b7\s*[/ ]\s*24\b').hasMatch(norm)) {
    return true;
  }

  final saatler = RegExp(r'\b(?:[01]?\d|2[0-3])[:.]\d{2}\b').allMatches(input);
  if (saatler.length >= 2) return true;

  if (RegExp(r'\b\d{1,2}\s*[-–—]\s*\d{1,2}\b').hasMatch(norm)) {
    return true;
  }

  final sayilar = RegExp(r'\b\d{1,2}\b').allMatches(norm).length;
  return sayilar >= 2 && norm.contains('sabah') && norm.contains('aksam');
}

bool _adresYeterinceAcikMi(String input) {
  final norm = VixrexNormalizer.normalize(input);
  final kelimeler = norm.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (kelimeler.length > 3) return true;
  return RegExp(
    r'\b(mahalle|mah|cadde|cad|sokak|sok|bulvar|blv|no|numara|apartman|apt|site|meydan)\b',
  ).hasMatch(norm);
}

/// Yalnız mevcut konuşma bağlamını yorumlar. Yeni niyet çözmez ve kayıt yapmaz.
/// Kısa cevap bağlamla güvenle açıklanamıyorsa vitrine yazmak yerine doğal bir
/// takip sorusu üretir.
VixrexBaglamSonucu vixrexBaglamsalCevapKarari(
  String input,
  VixrexBekleyenBaglam? bekleyen,
) {
  final trimmed = input.trim();
  final norm = VixrexNormalizer.normalize(trimmed);

  if (bekleyen == null) {
    return const VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.genelSor,
      yazma: false,
      mesaj: vixrexDogalGenelSoru,
    );
  }

  if (bekleyen.eylem == 'kaldir') {
    if (_evet.contains(norm)) {
      return const VixrexBaglamSonucu(
        karar: VixrexBaglamKarari.kaldir,
        yazma: true,
        mesaj: '',
        deger: '',
      );
    }
    if (_hayir.contains(norm) || _iptal.contains(norm)) {
      return VixrexBaglamSonucu(
        karar: VixrexBaglamKarari.iptal,
        yazma: false,
        mesaj: 'Tamam, ${bekleyen.etiket} bilgisini kaldırmıyorum.',
      );
    }
    return VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.kaldirmaOnayi,
      yazma: false,
      mesaj:
          '${bekleyen.etiket} bilgisini kaldırmamı istiyorsan evet, vazgeçtiysen hayır diyebilirsin.',
    );
  }

  if (_iptal.contains(norm)) {
    return const VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.iptal,
      yazma: false,
      mesaj: 'Tamam, bu değişikliği yapmıyorum. Başka neyi değiştirmek istersin?',
    );
  }

  if (_ayni.contains(norm)) {
    return VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.ayniKalsin,
      yazma: false,
      mesaj: 'Tamam, ${bekleyen.etiket} aynı kalsın.',
    );
  }

  if (bekleyen.tip == 'acikKapali') {
    if (_evet.contains(norm)) {
      return const VixrexBaglamSonucu(
        karar: VixrexBaglamKarari.boolTrue,
        yazma: true,
        mesaj: '',
        deger: true,
      );
    }
    if (_hayir.contains(norm)) {
      return const VixrexBaglamSonucu(
        karar: VixrexBaglamKarari.boolFalse,
        yazma: true,
        mesaj: '',
        deger: false,
      );
    }
  } else if (_evet.contains(norm) ||
      _hayir.contains(norm) ||
      _degerOlmayanKisa.contains(norm)) {
    return VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.ozelSor,
      yazma: false,
      mesaj: _alanSorusu(bekleyen),
    );
  }

  if (RegExp(r'\b(onu|bunu)\s+(kaldir|sil|temizle)\b').hasMatch(norm) ||
      RegExp(r'^(kaldir|sil|temizle)$').hasMatch(norm)) {
    return VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.kaldirmaOnayi,
      yazma: false,
      mesaj: '${bekleyen.etiket} bilgisini kaldırmamı mı istiyorsun?',
    );
  }

  if (bekleyen.anahtar == 'calismaSaatleri' && !_calismaSaatiTamMi(trimmed)) {
    return const VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.saatEksik,
      yazma: false,
      mesaj: 'Çalışma saatlerini tamamlamak için kaçta açıp kaçta kapandığınızı yazar mısın?',
    );
  }

  if (bekleyen.anahtar == 'adres' && !_adresYeterinceAcikMi(trimmed)) {
    return const VixrexBaglamSonucu(
      karar: VixrexBaglamKarari.adresEksik,
      yazma: false,
      mesaj: 'Açık adresi biraz daha ayrıntılı yazar mısın?',
    );
  }

  return VixrexBaglamSonucu(
    karar: VixrexBaglamKarari.deger,
    yazma: true,
    mesaj: '',
    deger: trimmed,
  );
}
