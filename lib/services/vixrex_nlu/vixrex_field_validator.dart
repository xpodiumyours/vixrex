import 'package:vixrex/config/business_category_config.dart';
import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/utils/address_validator.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

/// Flutter Vixrex Assistant alan doğrulayıcısı.
///
/// Zorunlu/min-max uzunluk/seçenek/doğrulama bilgisi elle tutulmaz;
/// `vitrin_alanlari.g.dart` üzerinden Next.js ile aynı 46-alan şemasından gelir.
class VixrexFieldValidator {
  const VixrexFieldValidator._();

  /// `hamDeger`’i alan tipine göre doğrular, normalize eder.
  /// Dönüş: ok=true + normalizedDeger (kayda gidecek), yoksa ok=false + hata.
  static ({bool ok, String? hata, Object? normalizedDeger}) validate(
    VixrexNiyetAlan alan,
    String hamDeger,
  ) {
    final tip = alan.tip;
    final etiket = alan.etiket;
    final raw = hamDeger.trim();
    final sema = alanAnahtarla[alan.anahtar];

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

    // sayi — merkezi şemadaki iki sayısal alanın sınırları parity için burada
    // aynı anahtarlardan okunur; generated Dart model henüz numeric min/max
    // taşımadığı için yalnız bu iki kanonik koordinat özel durumdur.
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
      if (sema?.zorunlu == true) {
        return (
          ok: false,
          hata: '$etiket boş bırakılamaz.',
          normalizedDeger: null,
        );
      }
      return (ok: true, hata: null, normalizedDeger: null);
    }

    final lengthErr = _metinSinirlari(alan, raw, sema);
    if (lengthErr != null) {
      return (ok: false, hata: lengthErr, normalizedDeger: null);
    }

    switch (tip) {
      case 'telefon':
        if (sema?.dogrulama == 'tr_mobil') {
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
        if (!_isSafeUrl(
          raw,
          allowAnchor: alan.anahtar == 'galeriAksiyonLinki',
        )) {
          return (
            ok: false,
            hata: '$etiket yalnız http veya https adresi olabilir.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      case 'secim':
        if (alan.anahtar == 'kategori') {
          final normalized = raw.toLowerCase();
          final category = BusinessCategoryConfig.categories.where(
            (c) =>
                c.label.toLowerCase() == normalized ||
                c.id.toLowerCase() == normalized ||
                c.aliases.any((alias) => alias.toLowerCase() == normalized),
          );
          if (category.isEmpty ||
              (sema?.secenekler != null &&
                  !sema!.secenekler!.contains(category.first.label))) {
            return (
              ok: false,
              hata: '$etiket için geçersiz seçim.',
              normalizedDeger: null,
            );
          }
          return (
            ok: true,
            hata: null,
            normalizedDeger: category.first.label,
          );
        }
        if (sema?.secenekler != null && !sema!.secenekler!.contains(raw)) {
          return (
            ok: false,
            hata: '$etiket için geçersiz seçim.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);
      case 'metin':
      case 'uzunMetin':
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

  static String? _metinSinirlari(
    VixrexNiyetAlan alan,
    String deger,
    VitrinAlani? sema,
  ) {
    final len = deger.length;
    final min = sema?.minUzunluk;
    final max = sema?.maxUzunluk;
    if (min != null && len > 0 && len < min) {
      return '${alan.etiket} en az $min karakter olmalı.';
    }
    if (max != null && len > max) {
      return '${alan.etiket} en fazla $max karakter olabilir.';
    }
    return null;
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

  static bool _isSafeUrl(String s, {required bool allowAnchor}) {
    if (s.startsWith('#')) return allowAnchor;
    final uri = Uri.tryParse(s);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
