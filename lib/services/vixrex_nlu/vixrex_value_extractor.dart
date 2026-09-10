import 'package:vixrex/config/vixrex_niyet_sozlugu.g.dart';
import 'package:vixrex/services/vixrex_nlu/vixrex_normalizer.dart';

/// Kural tabanlı değer ayıklayıcı – AI yok.
///
/// Araştırma-temelli sıra:
/// 1) sözlükteki açık `{deger}` kalıbı,
/// 2) tipe özel güvenli çıkarım (telefon vb.),
/// 3) tırnak / alan+fiil / ayraç,
/// 4) alan eş-anlamı sonrası güvenli kalan.
///
/// Next.js `vixrexValueExtractor.ts` ile aynı davranışta tutulur.
class VixrexValueExtractor {
  const VixrexValueExtractor();

  static const String _komutFiili =
      r'yap|olsun|degistir|değiştir|ekle|guncelle|güncelle|ayarla|yaz|sec|seç';

  static const List<String> _araIsimEkleri = [
    'm',
    'im',
    'um',
    'in',
    'un',
    'min',
    'mun',
    'imin',
    'umun',
    'nin',
    'nun',
    'imiz',
    'umuz',
    'iniz',
    'unuz',
    'imizin',
    'umuzun',
    'inizin',
    'unuzun',
    'larin',
    'lerin',
  ];

  String? extract(String input, VixrexNiyetAlan alan) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    final kalip = _extractFromExamples(raw, alan);
    if (kalip != null) return _serbestMetinAdayiniSinirla(kalip, alan);

    if (alan.tip == 'telefon') {
      final phone = _extractPhone(raw);
      if (phone != null) return phone;
    }

    if (_isFieldOnlyWithoutValue(raw, alan)) return null;

    final quoted = _extractQuoted(raw);
    if (quoted != null && quoted.trim().isNotEmpty) {
      final cleaned = _stripFieldMention(quoted.trim(), alan);
      final sonuc = cleaned.isNotEmpty ? cleaned : quoted.trim();
      return _serbestMetinAdayiniSinirla(sonuc, alan);
    }

    final afterLeadingVerb = _extractAfterLeadingVerb(raw, alan);
    if (afterLeadingVerb != null) {
      return _serbestMetinAdayiniSinirla(afterLeadingVerb, alan);
    }

    final colon = _extractAfterColon(raw, alan);
    if (colon != null && colon.trim().isNotEmpty) {
      final cleaned = _stripFieldMention(colon.trim(), alan);
      final candidate = cleaned.isNotEmpty ? cleaned : colon.trim();
      final withoutTrailingVerb = _stripTrailingVerb(candidate);
      final sonuc =
          withoutTrailingVerb.trim().isNotEmpty
              ? withoutTrailingVerb.trim()
              : candidate.trim();
      if (sonuc.isNotEmpty) return _serbestMetinAdayiniSinirla(sonuc, alan);
    }

    final between = _extractBetweenFieldAndVerb(raw, alan);
    if (between != null && between.trim().isNotEmpty) {
      final withoutVerb = _stripTrailingVerb(between.trim());
      final sonuc =
          withoutVerb.trim().isNotEmpty ? withoutVerb.trim() : between.trim();
      if (sonuc.isNotEmpty) return _serbestMetinAdayiniSinirla(sonuc, alan);
    }

    final beforeVerb = _extractBeforeVerb(raw);
    if (beforeVerb != null && beforeVerb.trim().isNotEmpty) {
      final candidate = _stripFieldMention(beforeVerb.trim(), alan);
      if (candidate.trim().isNotEmpty) {
        var sonuc = _stripTrailingVerb(candidate.trim());
        sonuc = sonuc.replaceFirst(
          RegExp(r'\s+(olarak|diye)$', caseSensitive: false),
          '',
        ).trim();
        if (sonuc.isEmpty) sonuc = candidate.trim();
        return _serbestMetinAdayiniSinirla(sonuc, alan);
      }
    }

    if (_isFreeTextType(alan.tip)) {
      final remainder = _remainderAfterFieldMention(raw, alan);
      if (remainder != null && remainder.trim().length >= 2) {
        var cleaned = _stripTrailingVerb(remainder.trim());
        cleaned = cleaned.replaceFirst(
          RegExp(r'\s+(olarak|diye)$', caseSensitive: false),
          '',
        ).trim();
        final withoutQuotes = _stripQuotes(
          (cleaned.isNotEmpty ? cleaned : remainder).trim(),
        );
        if (withoutQuotes.length >= 2) {
          return _serbestMetinAdayiniSinirla(withoutQuotes, alan);
        }
      }
    }

    return null;
  }

  String _literalPattern(String text) {
    if (text.trim().isEmpty) return '';
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) {
          var escaped = RegExp.escape(part);
          escaped = escaped.replaceAll("'", "['’]?");
          escaped = escaped.replaceAll('’', "['’]?");
          return escaped;
        })
        .join(r'\s+');
  }

  String? _extractFromExamples(String input, VixrexNiyetAlan alan) {
    for (final ornek in alan.ornekIfadeler) {
      final marker = ornek.indexOf('{deger}');
      if (marker < 0) continue;
      final once = ornek.substring(0, marker);
      final sonra = ornek.substring(marker + '{deger}'.length);
      final pattern = RegExp(
        '^\\s*${_literalPattern(once)}\\s*(.+?)\\s*${_literalPattern(sonra)}\\s*[.!]?\\s*\$',
        caseSensitive: false,
        dotAll: true,
      );
      final m = pattern.firstMatch(input);
      final rawDeger = m?.group(1)?.trim();
      if (rawDeger == null || rawDeger.isEmpty) continue;
      final deger = _stripQuotes(rawDeger);
      if (deger.isNotEmpty) return deger;
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
    final patterns = [
      RegExp(r'"([^"]{2,})"'),
      RegExp(r'‘([^’]{2,})’'),
      RegExp(r'“([^”]{2,})”'),
      RegExp(r'`([^`]{2,})`'),
      RegExp(r"'(.{2,})'", dotAll: true),
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

  String _esnekHarfPattern(String ch) {
    switch (ch) {
      case 'c':
        return '[cç]';
      case 'g':
        return '[gğ]';
      case 'u':
        return '[uü]';
      case 's':
        return '[sş]';
      case 'o':
        return '[oö]';
      case 'i':
        return '[iıİI]';
      default:
        return RegExp.escape(ch);
    }
  }

  String _esnekKelimePattern(String text) {
    final normalized = VixrexNormalizer.normalize(text);
    return normalized.runes
        .map((r) => _esnekHarfPattern(String.fromCharCode(r)))
        .join();
  }

  String get _araIsimEkiPattern =>
      '(?:${_araIsimEkleri.map(_esnekKelimePattern).join('|')})?';

  String _esnekAlanPattern(String ifade) {
    final tokens = VixrexNormalizer.normalize(
      ifade,
    ).trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    return tokens.asMap().entries.map((entry) {
      final i = entry.key;
      final token = entry.value;
      final kok = _esnekKelimePattern(token);
      if (i < tokens.length - 1 &&
          RegExp(r'^[a-z0-9]+$').hasMatch(token) &&
          token.length >= 4) {
        return '$kok$_araIsimEkiPattern';
      }
      return kok;
    }).join(r'\s+');
  }

  RegExpMatch? _bestFieldMatch(String input, VixrexNiyetAlan alan) {
    RegExpMatch? best;
    var bestLen = -1;
    for (final ea in alan.esAnlamlar) {
      final n = VixrexNormalizer.normalize(ea);
      final m = RegExp(
        _esnekAlanPattern(ea),
        caseSensitive: false,
      ).firstMatch(input);
      if (m != null && n.length > bestLen) {
        best = m;
        bestLen = n.length;
      }
    }
    return best;
  }

  int _fieldMatchEnd(String input, RegExpMatch m) {
    var end = m.end;
    final devam = RegExp(
      r'^[a-zA-ZçğıöşüÇĞİÖŞÜ]+',
    ).firstMatch(input.substring(end));
    if (devam != null) end += devam.group(0)!.length;
    return end;
  }

  String? _extractPhone(String input) {
    final quoted = _extractQuoted(input);
    if (quoted != null) {
      final digits = quoted.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 10 && digits.length <= 13) return quoted.trim();
    }
    final m = RegExp(
      r'(\+?90\s?)?0?\s?5\d{2}\s?\d{3}\s?\d{2}\s?\d{2}',
    ).firstMatch(input);
    if (m != null) return m.group(0)?.trim();
    final mLand = RegExp(r'0?\d{3}\s?\d{3}\s?\d{2}\s?\d{2}').firstMatch(input);
    if (mLand != null) {
      final digits = mLand.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 10 && digits.length <= 11) {
        return mLand.group(0)?.trim();
      }
    }
    return null;
  }

  bool _isFieldOnlyWithoutValue(String input, VixrexNiyetAlan alan) {
    final norm = VixrexNormalizer.normalize(input);
    var hasField = false;
    for (final ea in alan.esAnlamlar) {
      if (norm.contains(VixrexNormalizer.normalize(ea))) {
        hasField = true;
        break;
      }
    }
    if (!hasField) return false;
    final verbPattern = RegExp(
      '\\b($_komutFiili|yanlis|yanlış|hatali|hatalı|bozuk|degistirmek)\\b',
      caseSensitive: false,
    );
    var remainder = norm;
    for (final ea in alan.esAnlamlar) {
      remainder = remainder.replaceAll(VixrexNormalizer.normalize(ea), '');
    }
    remainder =
        remainder
            .replaceAll(verbPattern, '')
            .replaceAll(RegExp(r'[^a-z0-9]+'), '')
            .trim();
    return remainder.length < 3;
  }

  String? _extractAfterLeadingVerb(String input, VixrexNiyetAlan alan) {
    final m = _bestFieldMatch(input, alan);
    if (m == null) return null;
    var after = input.substring(_fieldMatchEnd(input, m)).trim();
    after = after.replaceFirst(RegExp(r'^[\s:=\-–—,]+'), '').trim();
    final vm = RegExp(
      '^(?:$_komutFiili)(?:\\s+(?:olarak|diye|şöyle|soyle))?\\s*[:=,\\-–—]?\\s*(.+)\$',
      caseSensitive: false,
    ).firstMatch(after);
    final value = vm?.group(1)?.trim();
    if (value == null || value.isEmpty) return null;
    final cleaned = _stripQuotes(
      value.replaceFirst(RegExp(r'[\s.,;]+$'), '').trim(),
    );
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _extractBetweenFieldAndVerb(String input, VixrexNiyetAlan alan) {
    final m = _bestFieldMatch(input, alan);
    if (m == null) return null;
    var after = input.substring(_fieldMatchEnd(input, m)).trim();
    after = after.replaceFirst(RegExp(r'^[\s:=\-–—,]+'), '').trim();
    if (after.isEmpty) return null;
    final verbMatch = RegExp(
      '\\b($_komutFiili)\\b',
      caseSensitive: false,
    ).firstMatch(after);
    var candidate =
        verbMatch != null ? after.substring(0, verbMatch.start).trim() : after;
    candidate = candidate
        .replaceFirst(RegExp(r'\s+(olarak|diye)$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^[\s:=\-–—,]+'), '')
        .trim()
        .replaceFirst(RegExp(r'[\s.,;]+$'), '')
        .trim();
    if (candidate.length < 2) return null;
    final normCand = VixrexNormalizer.normalize(
      candidate,
    ).replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (normCand.length < 3) return null;
    if (RegExp(r'^(yanlis|hatali|bozuk|degistir)$').hasMatch(normCand)) {
      return null;
    }
    return _stripQuotes(candidate);
  }

  String? _extractAfterColon(String input, VixrexNiyetAlan alan) {
    final m = _bestFieldMatch(input, alan);
    if (m == null) return null;
    final afterField = input.substring(_fieldMatchEnd(input, m)).trimLeft();
    if (!afterField.startsWith(':') && !afterField.startsWith('=')) return null;
    final sep = afterField[0];
    final after = afterField.substring(1).trim();
    if (after.isEmpty) return null;
    if (sep == ':' && after.startsWith('//')) return null;
    final quotedAfter = _extractQuoted(after);
    if (quotedAfter != null && quotedAfter.trim().isNotEmpty) {
      return quotedAfter.trim();
    }
    final cleaned = _stripFieldMention(after, alan);
    if (cleaned.isNotEmpty) return cleaned;
    return after;
  }

  String? _extractBeforeVerb(String input) {
    final m = RegExp(
      '^(.*)\\b($_komutFiili)\\b\\s*[.!]?\\s*\$',
      caseSensitive: false,
    ).firstMatch(input.trim());
    final before = m?.group(1);
    return before != null && before.trim().isNotEmpty ? before.trim() : null;
  }

  String _stripTrailingVerb(String s) {
    return s
        .replaceFirst(
          RegExp(
            '\\b($_komutFiili)\\b\\s*[.!]?\\s*\$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  String _stripFieldMention(String candidate, VixrexNiyetAlan alan) {
    var out = candidate;
    final sorted = List<String>.from(alan.esAnlamlar)
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final ea in sorted) {
      out = out.replaceAll(
        RegExp(_esnekAlanPattern(ea), caseSensitive: false),
        '',
      );
    }
    out = out
        .replaceFirst(
          RegExp(
            r"^\s*(adını|adimi|adı|adi|numaramı|numarami|numarası|numarasi|ismi|imi|ımı|umu|ümü|si|sı|su|sü|yi|yı|yu|yü|nı|ni|nu|nü|mı|mi|mu|mü)\b\s*",
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(r"\s*(adını|adimi|adı|adi)\s*$", caseSensitive: false),
          '',
        )
        .trim()
        .replaceFirst(RegExp(r'^[\s:=\-–—,]+'), '')
        .trim()
        .replaceFirst(RegExp(r'[\s.,;]+$'), '')
        .trim()
        .replaceAll(
          RegExp(RegExp.escape(alan.etiket), caseSensitive: false),
          '',
        )
        .trim();
    if (VixrexNormalizer.normalize(out) ==
        VixrexNormalizer.normalize(alan.etiket)) {
      return '';
    }
    if (out.trim().length < 2) return out.trim().isEmpty ? '' : out.trim();
    return out.trim();
  }

  String? _remainderAfterFieldMention(String input, VixrexNiyetAlan alan) {
    final m = _bestFieldMatch(input, alan);
    if (m == null) return null;
    final after = input.substring(_fieldMatchEnd(input, m)).trim();
    if (after.isEmpty) return null;
    final cleaned = after.replaceFirst(RegExp(r'^[\s:=\-–—,]+'), '').trim();
    if (cleaned.length < 2) return null;
    return _stripQuotes(cleaned);
  }

  static final RegExp _telefonSinirRegex = RegExp(
    r'(\+?90[\s.-]?)?0?[\s.-]?5\d{2}[\s.-]?\d{3}[\s.-]?\d{2}[\s.-]?\d{2}',
  );

  List<String> _digerAlanlarinEsAnlamlari(String kendiAnahtar) {
    final out = <String>[];
    for (final a in vixrexNiyetSozlugu) {
      if (a.anahtar == kendiAnahtar) continue;
      for (final ea in a.esAnlamlar) {
        final len = VixrexNormalizer.normalize(
          ea,
        ).replaceAll(RegExp(r'[^a-z0-9]'), '').length;
        if (len > 3) out.add(ea);
      }
    }
    return out;
  }

  String _serbestMetinAdayiniSinirla(String aday, VixrexNiyetAlan alan) {
    if (!_isFreeTextType(alan.tip) ||
        alan.tip == 'telefon' ||
        alan.tip == 'url' ||
        alan.tip == 'eposta') {
      return aday;
    }

    var sinir = aday.length;
    final tel = _telefonSinirRegex.firstMatch(aday);
    if (tel != null && tel.start > 0) sinir = tel.start;

    final digerEsAnlamlar = _digerAlanlarinEsAnlamlari(alan.anahtar);
    final ayracRegex = RegExp(r'[,;]|\bve\b', caseSensitive: false);
    for (final m in ayracRegex.allMatches(aday)) {
      if (m.start >= sinir) break;
      final kuyruk =
          ' ${VixrexNormalizer.normalize(aday.substring(m.end))} ';
      var eslesti = false;
      for (final ea in digerEsAnlamlar) {
        final n = RegExp.escape(VixrexNormalizer.normalize(ea));
        if (RegExp('[^a-z0-9]$n([^a-z0-9]|\$)').hasMatch(kuyruk)) {
          eslesti = true;
          break;
        }
      }
      if (eslesti && m.start < sinir) sinir = m.start;
    }

    if (sinir >= aday.length) return aday;
    final kesilmis = aday
        .substring(0, sinir)
        .trim()
        .replaceFirst(RegExp(r'[\s.,;]+$'), '')
        .trim();
    return kesilmis.length >= 2 ? kesilmis : aday;
  }
}
