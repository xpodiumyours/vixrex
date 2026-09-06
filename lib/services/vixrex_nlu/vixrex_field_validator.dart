import 'package:vixrex/config/vitrin_alanlari.g.dart';
import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/utils/address_validator.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

/// Akıllı Motor alan doğrulaması.
/// Karar kaynağı yalnız generated `VitrinAlani` şemasıdır;
/// intent sözlüğü yalnız çağrı uyumu için anahtarı taşır.
class VixrexFieldValidator {
  const VixrexFieldValidator._();

  static ({bool ok, String? hata, Object? normalizedDeger}) validate(
    VixrexNiyetAlan alan,
    Object? hamDeger,
  ) => validateByKey(alan.anahtar, hamDeger);

  static ({bool ok, String? hata, Object? normalizedDeger}) validateByKey(
    String anahtar,
    Object? hamDeger,
  ) {
    final alan = alanAnahtarla[anahtar];
    if (alan == null) {
      return (ok: false, hata: 'Bilinmeyen alan.', normalizedDeger: null);
    }

    final etiket = alan.etiket;

    if (alan.tip == 'acikKapali') {
      final normalized = _normalizeBoolean(hamDeger);
      if (normalized == null) {
        return (
          ok: false,
          hata: '$etiket yalnız açık veya kapalı olabilir.',
          normalizedDeger: null,
        );
      }
      return (ok: true, hata: null, normalizedDeger: normalized);
    }

    if (alan.tip == 'sayi') {
      if (hamDeger == null || (hamDeger is String && hamDeger.trim().isEmpty)) {
        return (ok: true, hata: null, normalizedDeger: null);
      }

      final num? sayi = switch (hamDeger) {
        num value => value,
        String value => num.tryParse(value.trim().replaceAll(',', '.')),
        _ => null,
      };

      if (sayi == null || !sayi.isFinite) {
        return (ok: false, hata: '$etiket sayı olmalı.', normalizedDeger: null);
      }
      if (alan.min != null && sayi < alan.min!) {
        return (
          ok: false,
          hata: '$etiket en az ${alan.min} olabilir.',
          normalizedDeger: null,
        );
      }
      if (alan.max != null && sayi > alan.max!) {
        return (
          ok: false,
          hata: '$etiket en fazla ${alan.max} olabilir.',
          normalizedDeger: null,
        );
      }
      return (ok: true, hata: null, normalizedDeger: sayi);
    }

    if (hamDeger != null && hamDeger is! String) {
      return (ok: false, hata: '$etiket metin olmalı.', normalizedDeger: null);
    }

    final raw = (hamDeger as String? ?? '').trim();
    if (alan.zorunlu && raw.isEmpty) {
      return (
        ok: false,
        hata: '$etiket boş bırakılamaz.',
        normalizedDeger: null,
      );
    }

    if (alan.minUzunluk != null &&
        raw.isNotEmpty &&
        raw.length < alan.minUzunluk!) {
      return (
        ok: false,
        hata: '$etiket en az ${alan.minUzunluk} karakter olmalı.',
        normalizedDeger: null,
      );
    }
    if (alan.maxUzunluk != null && raw.length > alan.maxUzunluk!) {
      return (
        ok: false,
        hata: '$etiket en fazla ${alan.maxUzunluk} karakter olabilir.',
        normalizedDeger: null,
      );
    }

    if (raw.isEmpty) {
      return (ok: true, hata: null, normalizedDeger: null);
    }

    if (alan.dogrulama == 'adres') {
      final hata = AddressValidator.hataMesaji(raw);
      if (hata != null) {
        return (ok: false, hata: hata, normalizedDeger: null);
      }
    }

    switch (alan.tip) {
      case 'telefon':
        if (alan.dogrulama == 'tr_mobil') {
          final normalized = WhatsAppLinkHelper.normalizeTurkeyMobile(raw);
          if (normalized == null) {
            return (
              ok: false,
              hata: '$etiket geçerli bir Türkiye cep telefonu olmalı.',
              normalizedDeger: null,
            );
          }
          return (ok: true, hata: null, normalizedDeger: normalized);
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
        // #anchor yalnız vitrin içindeki açık action-link alanında geçerlidir.
        final anchorIzinli = alan.anahtar == 'galeriAksiyonLinki';
        if (!_isSafeUrl(raw, allowAnchor: anchorIzinli)) {
          return (
            ok: false,
            hata: '$etiket yalnız http veya https adresi olabilir.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);

      case 'gorsel':
        if (!_isSafeUrl(raw, allowAnchor: false)) {
          return (
            ok: false,
            hata: '$etiket yalnız http veya https adresi olabilir.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);

      case 'secim':
        if (alan.secenekler != null && !alan.secenekler!.contains(raw)) {
          return (
            ok: false,
            hata: '$etiket için geçersiz seçim.',
            normalizedDeger: null,
          );
        }
        return (ok: true, hata: null, normalizedDeger: raw);

      case 'metin':
      case 'uzunMetin':
        return (ok: true, hata: null, normalizedDeger: raw);

      default:
        return (
          ok: false,
          hata: 'Desteklenmeyen alan tipi: ${alan.tip}',
          normalizedDeger: null,
        );
    }
  }

  static bool? _normalizeBoolean(Object? value) {
    if (value is bool) return value;
    if (value is! String) return null;

    final normalized = _turkceKucult(value.trim());
    const trueValues = {
      'aç',
      'ac',
      'açık',
      'acik',
      'göster',
      'goster',
      'evet',
      'on',
      'true',
      '1',
    };
    const falseValues = {
      'kapat',
      'kapalı',
      'kapali',
      'gizle',
      'hayır',
      'hayir',
      'off',
      'false',
      '0',
    };

    if (trueValues.contains(normalized)) return true;
    if (falseValues.contains(normalized)) return false;
    return null;
  }

  static String _turkceKucult(String value) {
    return value.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  }

  static bool _isSafeUrl(String value, {required bool allowAnchor}) {
    if (value.startsWith('#')) return allowAnchor && value.length > 1;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
