import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// Kural tabanlı değer ayıklayıcı – AI yok.
/// Öncelik:
/// 1) Tırnak içi: '...' / "..." / '...' / "..." / `...`
/// 2) ":" / "=" sonrası (örn. "İşletme adı: Aymira")
/// 3) "yap/olsun/değiştir/ekle/güncelle" fiillerinden önce son anlamlı parça
/// 4) Bulunamazsa null → netleştirme sorusu
class VixrexValueExtractor {
  const VixrexValueExtractor();

  /// `alan` için `input` içinden ham değeri ayıklar, yoksa null.
  /// Dönen değer hamdır; doğrulama/normalizasyon `validateField`’ta yapılır.
  String? extract(String input, VixrexNiyetAlan alan) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    // Telefon için doğrudan numara yakala – "numaramı" ekini atlatır.
    if (alan.tip == 'telefon') {
      final phone = _extractPhone(raw);
      if (phone != null) return phone;
    }

    // Faz 1 emniyeti: sadece alan adı + fiil/yanlış gibi değersiz cümleler netleştirme için null.
    if (_isFieldOnlyWithoutValue(raw, alan)) {
      // print('isFieldOnlyWithoutValue true for $raw / ${alan.anahtar}');
      return null;
    }

    // 1) Tırnak içi – en güvenilir.
    final quoted = _extractQuoted(raw);
    if (quoted != null && quoted.trim().isNotEmpty) {
      final cleaned = _stripFieldMention(quoted.trim(), alan);
      if (cleaned.isNotEmpty) return cleaned;
      // Tırnak içi alan adını içermiyorsa doğrudan değerdir.
      if (quoted.trim().isNotEmpty) return quoted.trim();
    }

    // 2) ":" / "=" sonrası – sadece alan adından sonra gelen ":" için (No: içindeki ":" değil)
    final colon = _extractAfterColon(raw, alan);
    if (colon != null && colon.trim().isNotEmpty) {
      final cleaned = _stripFieldMention(colon.trim(), alan);
      // ":" sonrası alan adı tekrarı varsa temizle, yoksa olduğu gibi al.
      final candidate = cleaned.isNotEmpty ? cleaned : colon.trim();
      final withoutTrailingVerb = _stripTrailingVerb(candidate);
      if (withoutTrailingVerb.trim().isNotEmpty) return withoutTrailingVerb.trim();
      if (candidate.trim().isNotEmpty) return candidate.trim();
    }

    // 3) Fiil öncesi – "WhatsApp numaramı 0555... yap / olsun"
    // Önce alan-adından fiile kadar olan aralığı doğrudan al (daha güvenilir).
    final between = _extractBetweenFieldAndVerb(raw, alan);
    if (between != null && between.trim().isNotEmpty) {
      final withoutVerb = _stripTrailingVerb(between.trim());
      final cand = withoutVerb.trim().isNotEmpty ? withoutVerb.trim() : between.trim();
      if (cand.isNotEmpty) return cand;
    }
    final beforeVerb = _extractBeforeVerb(raw);
    if (beforeVerb != null && beforeVerb.trim().isNotEmpty) {
      final candidate = _stripFieldMention(beforeVerb.trim(), alan);
      if (candidate.trim().isNotEmpty) {
        final trimmed = _stripTrailingVerb(candidate.trim());
        if (trimmed.isNotEmpty) return trimmed;
        return candidate.trim();
      }
    }

    // 4) Son çare: alan eş-anlamını çıkar, kalanı değer say
    // Sadece metin/uzunMetin/telefon/url için güvenli – seçim/sayi/acikKapali için değil.
    if (_isFreeTextType(alan.tip)) {
      final remainder = _remainderAfterFieldMention(raw, alan);
      if (remainder != null && remainder.trim().length >= 2) {
        final cleaned = _stripTrailingVerb(remainder.trim());
        final withoutQuotes = _stripQuotes(cleaned.trim());
        if (withoutQuotes.length >= 2) return withoutQuotes;
      }
    }

    return null;
  }

  bool _isFreeTextType(String tip) {
    return tip == 'metin' ||
        tip == 'uzunMetin' ||
        tip == 'telefon' ||
        tip == 'url' ||
        tip == 'gorsel' ||
        tip == 'eposta';
  }

  String? _extractQuoted(String input) {
    // '...' , "..." , '...' , "..." , `...`
    final patterns = [
      RegExp(r"'([^']{2,})'"),
      RegExp(r'"([^"]{2,})"'),
      RegExp(r'‘([^’]{2,})’'),
      RegExp(r'“([^”]{2,})”'),
      RegExp(r'`([^`]{2,})`'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(input);
      if (m != null) return m.group(1);
    }
    return null;
  }

  String _stripQuotes(String s) {
    var t = s.trim();
    if ((t.startsWith("'") && t.endsWith("'")) ||
        (t.startsWith('"') && t.endsWith('"')) ||
        (t.startsWith('‘') && t.endsWith('’')) ||
        (t.startsWith('“') && t.endsWith('”')) ||
        (t.startsWith('`') && t.endsWith('`'))) {
      t = t.substring(1, t.length - 1).trim();
    }
    return t;
  }

  String? _extractAfterColon(String input, VixrexNiyetAlan alan) {
    // Sadece alan adından hemen sonra gelen ":" / "=" – "https://" ve "?q=" içindeki değil.
    final normInput = VixrexNormalizer.normalize(input);
    String? bestEa;
    int bestLen = -1;
    int bestIdx = -1;
    for (final ea in alan.esAnlamlar) {
      final normEa = VixrexNormalizer.normalize(ea);
      final idx = normInput.indexOf(normEa);
      if (idx != -1 && normEa.length > bestLen) {
        bestEa = ea;
        bestLen = normEa.length;
        bestIdx = idx;
      }
    }
    if (bestEa == null || bestIdx == -1) return null;
    // Normalized index ile orijinalde yaklaşık bitişi bul (Türkçe İ/i için RegExp güvenilmez)
    int fieldEnd = bestIdx + bestLen;
    if (fieldEnd > input.length) fieldEnd = input.length;
    // Gerçek input'ta alan adından sonraki ":" aranır – normalize uzunluğu aynı olduğu için yaklaşık doğru.
    // Küçük sapma için 2 karakter toleransla ara.
    String afterField;
    if (fieldEnd < input.length) {
      afterField = input.substring(fieldEnd).trimLeft();
      // Eğer afterField ":" ile başlamıyorsa, 2 karakter geri/ileri ara (örn. "nı" eki nedeniyle 2 sapma)
      if (!afterField.startsWith(':') && !afterField.startsWith('=')) {
        // 2 karakter geri dene
        final altEnd = (fieldEnd - 2).clamp(0, input.length);
        final alt = input.substring(altEnd).trimLeft();
        if (alt.startsWith(':') || alt.startsWith('=')) {
          afterField = alt;
        } else {
          // 2 karakter ileri dene
          final alt2 = fieldEnd + 2 <= input.length ? input.substring(fieldEnd + 2).trimLeft() : '';
          if (alt2.startsWith(':') || alt2.startsWith('=')) {
            afterField = alt2;
          } else {
            return null;
          }
        }
      }
    } else {
      return null;
    }
    if (afterField.isEmpty) return null;
    if (!afterField.startsWith(':') && !afterField.startsWith('=')) return null;
    final sep = afterField[0];
    final after = afterField.substring(1).trim();
    if (after.isEmpty) return null;
    if (sep == ':' && after.startsWith('//')) return null;
    final quotedAfter = _extractQuoted(after);
    if (quotedAfter != null && quotedAfter.trim().isNotEmpty) return quotedAfter.trim();
    final cleaned = _stripFieldMention(after, alan);
    if (cleaned.isNotEmpty) return cleaned;
    return after;
  }

  /// "yap/olsun/değiştir/degistir/ekle/güncelle/guncelle/ayarla" öncesi
  String? _extractBeforeVerb(String input) {
    final verbPattern = RegExp(
      r'^(.*)\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b\s*[.!]?\s*$',
      caseSensitive: false,
    );
    final m = verbPattern.firstMatch(input.trim());
    if (m != null) {
      final before = m.group(1);
      if (before != null && before.trim().isNotEmpty) return before.trim();
    }
    return null;
  }

  String _stripTrailingVerb(String s) {
    return s
        .replaceAll(
          RegExp(
            r'\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b\s*[.!]?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  /// "İşletme adını" gibi alan adını metinden temizle – kalan değer kalsın.
  String _stripFieldMention(String candidate, VixrexNiyetAlan alan) {
    var out = candidate;
    // Önce uzun eş-anlamları temizle (çakışma önlemek için uzun önce).
    final sorted = List<String>.from(alan.esAnlamlar)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final ea in sorted) {
      final pattern = RegExp(
        RegExp.escape(ea),
        caseSensitive: false,
      );
      out = out.replaceAll(pattern, '');
    }
    // Türkçe ek temizliği: adres->adresimi, işletme adı->adını gibi kalan ekleri at.
    // "Adresimi" içindeki "adres" çıkarılınca "imi" kalır → baştaki ekleri temizle.
    out = out
        .replaceAll(RegExp(r"^\s*(adını|adimi|adı|adi|numaramı|numarami|numarası|numarasi|ismi|ismi|imi|ımı|umu|ümü|si|sı|su|sü|yi|yı|yu|yü|nı|ni|nu|nü|mı|mi|mu|mü)\b\s*", caseSensitive: false), '')
        .replaceAll(RegExp(r"\s*(adını|adimi|adı|adi)\s*$", caseSensitive: false), '')
        .trim();
    // Baştaki noktalama ve ekleri temizle
    out = out.replaceAll(RegExp(r"^[\s:=\-–—,]+"), '').trim();
    out = out.replaceAll(RegExp(r"[\s.,;]+$"), '').trim();
    // Alan etiketini de temizle (örn. "İşletme Adı")
    out = out.replaceAll(
      RegExp(RegExp.escape(alan.etiket), caseSensitive: false),
      '',
    ).trim();
    out = VixrexNormalizer.normalize(out) == VixrexNormalizer.normalize(alan.etiket)
        ? ''
        : out;
    // Çok kısa kalan ("i", "ı") değersizdir
    if (out.trim().length < 2) return out.trim().isEmpty ? '' : out.trim();
    return out.trim();
  }

  String? _extractPhone(String input) {
    final quoted = _extractQuoted(input);
    if (quoted != null) {
      final digits = quoted.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 10 && digits.length <= 13) return quoted.trim();
    }
    // Mobil 5xx
    final m = RegExp(r'(\+?90\s?)?0?\s?5\d{2}\s?\d{3}\s?\d{2}\s?\d{2}').firstMatch(input);
    if (m != null) return m.group(0)?.trim();
    // Sabit hat 0212 vb. – 10-11 haneli herhangi bir numara
    final mLand = RegExp(r'0?\d{3}\s?\d{3}\s?\d{2}\s?\d{2}').firstMatch(input);
    if (mLand != null) {
      final digits = mLand.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 10 && digits.length <= 11) return mLand.group(0)?.trim();
    }
    return null;
  }

  bool _isFieldOnlyWithoutValue(String input, VixrexNiyetAlan alan) {
    final norm = VixrexNormalizer.normalize(input);
    // Alan eş-anlamı var mı?
    bool hasField = false;
    for (final ea in alan.esAnlamlar) {
      if (norm.contains(VixrexNormalizer.normalize(ea))) {
        hasField = true;
        break;
      }
    }
    if (!hasField) return false;
    // Fiil/yanlış/doğru gibi değersiz kelimeler dışında değer yoksa null.
    final verbPattern = RegExp(r'\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz|yanlis|yanlış|hatali|hatalı|bozuk|degistirmek)\b', caseSensitive: false);
    // Alan adını ve fiili çıkar, kalanı ölç.
    var remainder = norm;
    for (final ea in alan.esAnlamlar) {
      remainder = remainder.replaceAll(VixrexNormalizer.normalize(ea), '');
    }
    remainder = remainder.replaceAll(verbPattern, '').replaceAll(RegExp(r'[^a-z0-9]+'), '').trim();
    return remainder.length < 3;
  }

  String? _extractBetweenFieldAndVerb(String input, VixrexNiyetAlan alan) {
    final normInput = VixrexNormalizer.normalize(input);
    // En uzun eş-anlamı bul
    String? bestEa;
    int bestLen = -1;
    int bestIdx = -1;
    for (final ea in alan.esAnlamlar) {
      final normEa = VixrexNormalizer.normalize(ea);
      final idx = normInput.indexOf(normEa);
      if (idx != -1 && normEa.length > bestLen) {
        bestEa = ea;
        bestLen = normEa.length;
        bestIdx = idx;
      }
    }
    if (bestEa == null || bestIdx == -1) return null;
    // Orijinal metinde aynı eş-anlamın bitişini bul
    final pattern = RegExp(RegExp.escape(bestEa), caseSensitive: false);
    final m = pattern.firstMatch(input);
    if (m == null) return null;
    var afterField = input.substring(m.end).trim();
    if (afterField.isEmpty) return null;
    // Baştaki ekleri at: "nı/ni, mı/mi, yı/yi, sını, imi, u/ü" gibi
    afterField = afterField.replaceAll(RegExp(r"^[\s:=\-–—,]+"), '').trim();
    afterField = afterField.replaceAll(RegExp(r"^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi|numaramı|numarami|imi|ımı|umu|ümü|yi|yı|u|ü|ı|i)\b\s*", caseSensitive: false), '').trim();
    if (afterField.isEmpty) return null;
    // Fiilden öncesini al: " ... yap" → fiile kadar
    final verbIdx = afterField.toLowerCase().indexOf(RegExp(r'\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b').pattern);
    // Basit: fiil var mı?
    final verbMatch = RegExp(r'\b(yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz)\b', caseSensitive: false).firstMatch(afterField);
    String candidate;
    if (verbMatch != null) {
      candidate = afterField.substring(0, verbMatch.start).trim();
    } else {
      candidate = afterField;
    }
    candidate = candidate.replaceAll(RegExp(r"^[\s:=\-–—,]+"), '').trim();
    candidate = candidate.replaceAll(RegExp(r"[\s.,;]+$"), '').trim();
    if (candidate.length < 2) return null;
    // Sadece fiil/yanlış kaldıysa null
    final normCand = VixrexNormalizer.normalize(candidate).replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (normCand.length < 3) return null;
    if (RegExp(r'^(yanlis|hatali|bozuk|degistir)$').hasMatch(normCand)) return null;
    return _stripQuotes(candidate);
  }

  String? _remainderAfterFieldMention(String input, VixrexNiyetAlan alan) {
    var normInput = VixrexNormalizer.normalize(input);
    String? matchedEa;
    int matchLen = -1;
    for (final ea in alan.esAnlamlar) {
      final normEa = VixrexNormalizer.normalize(ea);
      if (normInput.contains(normEa) && normEa.length > matchLen) {
        matchedEa = ea;
        matchLen = normEa.length;
      }
    }
    if (matchedEa == null) return null;
    final idx = normInput.indexOf(VixrexNormalizer.normalize(matchedEa));
    if (idx == -1) return null;
    // Orijinal metinden eş-anlam sonrası kalanı al (normalize uzunluğu yaklaşık eşdeğer).
    // Basit: orijinalde eş-anlamı case-insensitive ara, sonrası al.
    final pattern = RegExp(RegExp.escape(matchedEa), caseSensitive: false);
    final m = pattern.firstMatch(input);
    if (m == null) return null;
    final after = input.substring(m.end).trim();
    if (after.isEmpty) return null;
    // Baştaki ekleri at: "nı/ni, mı/mi, yi, sını"
    final cleaned = after
        .replaceAll(RegExp(r"^[\s:=\-–—,]+"), '')
        .replaceAll(RegExp(r"^(nı|ni|nu|nü|mı|mi|mu|mü|yı|yi|yu|yü|sı|si|su|sü|sını|sini|sunı|adını|adimi)\b\s*", caseSensitive: false), '')
        .trim();
    if (cleaned.length < 2) return null;
    // Kalan sadece fiil/yanlış ise değersiz say.
    final normCleaned = VixrexNormalizer.normalize(cleaned).replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (normCleaned.length < 2) return null;
    if (RegExp(r'^(yanlis|hatali|bozuk|degistir)$').hasMatch(normCleaned)) return null;
    return _stripQuotes(cleaned);
  }
}
