import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/utils/address_validator.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

/// Faz 1: 6 zorunlu + Faz 2 kalite için tip/dogrulama → validateField eşdeğeri.
/// Tam `public_web/src/lib/vitrinFieldValidation.ts` ile aynı kural olmalı – parity testleri kilitler.
class VixrexFieldValidator {
  const VixrexFieldValidator._();

  /// `hamDeger`’i alan tipine göre doğrular, normalize eder.
  /// Dönüş: ok=true + normalizedDeger (kayda gidecek), yoksa ok=false + hata (Türkçe).
  static ({bool ok, String? hata, Object? normalizedDeger}) validate(
    VixrexNiyetAlan alan,
    String hamDeger,
  ) {
    final tip = alan.tip;
    final etiket = alan.etiket;
    final raw = hamDeger.trim();

    // acikKapali
    if (tip == 'acikKapali') {
      final norm = raw.toLowerCase();
      if ([
        'açık',
        'acik',
        'göster',
        'goster',
        'evet',
        'on',
        'true',
        '1',
      ].contains(norm)) {
        return (ok: true, hata: null, normalizedDeger: true);
      }
      if ([
        'kapalı',
        'kapali',
        'gizle',
        'hayır',
        'hayir',
        'off',
        'false',
        '0',
      ].contains(norm)) {
        return (ok: true, hata: null, normalizedDeger: false);
      }
      return (
        ok: false,
        hata: '$etiket yalnız açık veya kapalı olabilir.',
        normalizedDeger: null,
      );
    }

    // sayi
    if (tip == 'sayi') {
      if (raw.isEmpty) return (ok: true, hata: null, normalizedDeger: null);
      final numStr = raw.replaceAll(',', '.');
      final num = double.tryParse(numStr);
      if (num == null || !num.isFinite) {
        return (ok: false, hata: '$etiket sayı olmalı.', normalizedDeger: null);
      }
      final min = _minFor(alan);
      final max = _maxFor(alan);
      if (min != null && num < min) {
        return (
          ok: false,
          hata: '$etiket en az $min olabilir.',
          normalizedDeger: null,
        );
      }
      if (max != null && num > max) {
        return (
          ok: false,
          hata: '$etiket en fazla $max olabilir.',
          normalizedDeger: null,
        );
      }
      return (ok: true, hata: null, normalizedDeger: num);
    }

    // metin tabanlı tipler
    if (raw.isEmpty) {
      // Zorunlu alan boş bırakılamaz – Faz 1’de 6 zorunlu için kontrol.
      final zorunlular = {
        'isletmeAdi',
        'kategori',
        'whatsapp',
        'adres',
        'il',
        'ilce',
      };
      if (zorunlular.contains(alan.anahtar)) {
        return (
          ok: false,
          hata: '$etiket boş bırakılamaz.',
          normalizedDeger: null,
        );
      }
      return (ok: true, hata: null, normalizedDeger: null);
    }

    // uzunluk sınırları (vitrin_alanlari.g.dart’tan gelen bilgi sözlükte beklenenVeriTipi’nde ama burada elle)
    final lengthErr = _metinSinirlari(alan, raw);
    if (lengthErr != null) {
      return (ok: false, hata: lengthErr, normalizedDeger: null);
    }

    switch (tip) {
      case 'telefon':
        if (alan.anahtar == 'whatsapp') {
          final norm = WhatsAppLinkHelper.normalizeTurkeyMobile(raw);
          if (norm == null) {
            return (
              ok: false,
              hata: WhatsAppLinkHelper.invalidNumberMessage,
              normalizedDeger: null,
            );
          }
          return (ok: true, hata: null, normalizedDeger: norm);
        }
        final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 10 || digits.length > 13) {
          return (
            ok: false,
            hata: '$etiket 10–13 rakam olmalı.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: digits);
      case 'eposta':
        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(raw)) {
          return (
            ok: false,
            hata: '$etiket geçerli bir e-posta olmalı.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      case 'url':
      case 'gorsel':
        if (!_isSafeUrl(raw)) {
          return (
            ok: false,
            hata: '$etiket yalnız http veya https adresi olabilir.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      case 'secim':
        // Faz 1: kategori için seçenek kontrolü – BusinessCategoryConfig ile eşdeğer.
        if (alan.anahtar == 'kategori') {
          final exists = BusinessCategoryConfig.categories.any(
            (c) =>
                c.label.toLowerCase() == raw.toLowerCase() ||
                c.id.toLowerCase() == raw.toLowerCase(),
          );
          if (!exists) {
            return (
              ok: false,
              hata: '$etiket için geçersiz seçim.',
              normalizedDeger: null,
            );
          }
          // Normalize: label’ı döndür (UI’da label gösterilir)
          final cat = BusinessCategoryConfig.categories.firstWhere(
            (c) =>
                c.label.toLowerCase() == raw.toLowerCase() ||
                c.id.toLowerCase() == raw.toLowerCase(),
            orElse: () => BusinessCategoryConfig.categories.first,
          );
          return (ok: true, hata: null, normalizedDeger: cat.label);
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      case 'metin':
      case 'uzunMetin':
        // Adres için özel validator (sokak/cadde + numara)
        if (alan.anahtar == 'adres') {
          final hata = AddressValidator.hataMesaji(raw);
          if (hata != null) {
            return (ok: false, hata: hata, normalizedDeger: null);
          }
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      default:
        return (
          ok: false,
          hata: 'Desteklenmeyen alan tipi: $tip',
          normalizedDeger: null,
        );
    }
  }

  static String? _metinSinirlari(VixrexNiyetAlan alan, String deger) {
    final len = deger.length;
    // Zorunlu boş kontrol yukarıda yapıldı.
    final min = _minUzunluk(alan);
    final max = _maxUzunluk(alan);
    if (min != null && len > 0 && len < min) {
      return '${alan.etiket} en az $min karakter olmalı.';
    }
    if (max != null && len > max) {
      return '${alan.etiket} en fazla $max karakter olabilir.';
    }
    return null;
  }

  static int? _minUzunluk(VixrexNiyetAlan alan) {
    // Faz 1 dar: sadece kritik alanlar – diğerleri sözlükteki beklenenVeriTipi’nden parse edilebilir ama burada sabit.
    switch (alan.anahtar) {
      case 'isletmeAdi':
        return 2;
      default:
        return null;
    }
  }

  static int? _maxUzunluk(VixrexNiyetAlan alan) {
    switch (alan.anahtar) {
      case 'isletmeAdi':
        return 60;
      case 'heroRozet':
        return 60;
      case 'kisaTanitim':
        return 300;
      case 'konumMetni':
        return 60;
      case 'isletmeTuru':
        return 40;
      case 'adres':
        return 200;
      case 'il':
      case 'ilce':
      case 'mahalle':
        return 60;
      case 'haritaEtiketi':
        return 120;
      case 'calismaSaatleri':
        return 400;
      case 'instagram':
        return 30;
      case 'website':
      case 'haritaLinki':
      case 'referansLinki':
        return 2000;
      case 'hakkindaUstBaslik':
        return 40;
      case 'hakkindaBaslik':
        return 90;
      case 'hakkindaMetin':
        return 1200;
      case 'hakkindaGorselAlt':
        return 120;
      case 'galeriUstBaslik':
        return 40;
      case 'galeriBaslik':
        return 90;
      case 'galeriAksiyonMetni':
        return 40;
      case 'kategoriBolumBaslik':
      case 'urunBolumBaslik':
        return 60;
      case 'bantEtiket':
        return 40;
      case 'bantBaslik':
        return 90;
      case 'bantAciklama':
        return 200;
      case 'bantFiyat':
        return 30;
      case 'blogUstBaslik':
        return 40;
      case 'blogBaslik':
        return 90;
      case 'sssUstBaslik':
        return 40;
      case 'sssBaslik':
        return 90;
      case 'sssAciklama':
        return 200;
      case 'eposta':
        return 120;
      case 'kategori':
        return 40;
      case 'logo':
      case 'kapakGorseli':
      case 'bantGorsel':
      case 'hakkindaGorsel':
        return 2000;
      default:
        return null;
    }
  }

  static double? _minFor(VixrexNiyetAlan alan) {
    if (alan.anahtar == 'enlem') return -90;
    if (alan.anahtar == 'boylam') return -180;
    return null;
  }

  static double? _maxFor(VixrexNiyetAlan alan) {
    if (alan.anahtar == 'enlem') return 90;
    if (alan.anahtar == 'boylam') return 180;
    return null;
  }

  static bool _isSafeUrl(String s) {
    if (s.startsWith('#')) return true;
    final uri = Uri.tryParse(s);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
