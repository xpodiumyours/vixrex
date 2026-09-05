# Vixrex Akıllı Motor — Matcher LOCK

> Kapsam: yalnız storefront 46-alan niyet eşleştirmesi. Bu belge BUILD yapmaz; matcher davranışını kilitler.

## Amaç

Esnafın günlük Türkçe mesajından alan adını **AI API olmadan, deterministik ve yanlış mutation üretmeden** çözmek. Flutter ve Next.js aynı girdide aynı alan(lar)ı bulmak zorundadır.

## Kanıtlanan mevcut sorun

Her iki runtime bugün normalize edilmiş metinde serbest substring arıyor:

- Next.js: `normInput.includes(normEa)`
- Flutter: `normInput.contains(c.esAnlam)`

Bu nedenle kısa alias'lar başka kelimelerin içinde yanlış pozitif üretebilir. Kanıt örneği: telefon alias'ı `tel` olduğunda `otel` kelimesi de aday olabilir.

## LOCK — eşleştirme sırası

Aşağıdaki sıra iki runtime için birebir aynıdır:

1. **Normalize (matching-only)**
   - Türkçe locale küçük harf.
   - Unicode canonical decomposition + combining mark temizliği mevcut parity davranışıyla korunur.
   - `ı→i, ğ→g, ü→u, ş→s, ö→o, ç→c` matching katmanında uygulanabilir.
   - Kullanıcıya gösterilen/kaydedilen orijinal değer bu normalize metinle değiştirilmez.

2. **Token/phrase segmentasyonu**
   - Alias yalnız kelime/token sınırında eşleşebilir.
   - Serbest substring yasaktır.
   - Noktalama token sınırı sayılır; kelime içi parça sınır sayılmaz.
   - Örnek: `tel` → `tel` eşleşir, `otel` eşleşmez.

3. **Exact phrase** — en yüksek güven
   - 2+ token alias tam token dizisiyle eşleşirse `EXACT_PHRASE`.
   - Örnek: `işletme adı`, `çalışma saatleri`, `harita linki`.

4. **Exact token**
   - Tek token alias tam token eşleşmesiyse `EXACT_TOKEN`.
   - Kısa/generik alias'lar yalnız bu sınıfta çalışabilir.

5. **Kontrollü Türkçe ekli biçim**
   - Yalnız alias kökü **en az 5 normalize karakterse** izin verilir.
   - Eşleşme `startsWith` değildir; kökten sonra kalan bölüm aşağıdaki sonlu suffix listelerinden biri olmak zorundadır.
   - İlk hedef günlük düzenleme kalıplarıdır: birinci/ikinci kişi iyelik + hâl ekleri.
   - Normalize suffix adayları:
     - yalın iyelik: `m`, `im`, `um`, `n`, `in`, `un`, `i`, `u`
     - iyelik + belirtme/yönelme: `mi`, `mu`, `imi`, `umu`, `me`, `ma`, `ime`, `uma`, `ni`, `nu`, `ini`, `unu`, `ne`, `na`, `ine`, `una`
     - iyelik + ilgi: `min`, `mun`, `imin`, `umun`, `nin`, `nun`, `inin`, `unun`
     - iyelik + bulunma/ayrılma: `mde`, `mda`, `mden`, `mdan`, `imde`, `imda`, `imden`, `imdan`, `umde`, `umda`, `umden`, `umdan`, `nde`, `nda`, `nden`, `ndan`, `inde`, `inda`, `inden`, `indan`, `unda`, `unde`, `undan`, `unden`
   - Bu liste dışında kalan ek biçimi doğrudan mutation tetiklemez.
   - Örnek güvenli hedefler: `telefonumu`, `adresimi`, `kategorimi`.

6. **Fuzzy / yazım hatası**
   - Fuzzy eşleşme **hiçbir zaman mutation üretmez**.
   - Yalnız netleştirme önerisi üretir.
   - Yalnız tek-token alias uzunluğu ≥ 6 için değerlendirilir.
   - Maksimum Damerau-Levenshtein mesafesi: **1**.
   - Birden fazla alan adayı çıkarsa öneri de yapılmaz; genel netleştirme sorulur.

## Kısa/generik alias güvenlik listesi

Aşağıdaki sınıftaki alias'lar suffix/fuzzy alamaz; yalnız tam token/phrase eşleşebilir:

- normalize uzunluğu < 5 olan alias'lar (`il`, `ig`, `tel`, `url` gibi)
- anlamsal olarak generik alias'lar (`alan`, `tür`, `isim`, `özet`, `etiket`, `site`, `mail`, `saatler` gibi)

Generik liste shared sözlükte açık metadata ile işaretlenebilir; davranış iki runtime'da hard-code farklılaştırılmaz.

## Çakışma çözümü

Bir mesajda aynı token aralığını birden fazla alias kapsarsa:

1. `EXACT_PHRASE` > `EXACT_TOKEN` > `INFLECTED_SAFE` > `FUZZY_SUGGESTION`.
2. Aynı sınıfta daha çok token içeren alias kazanır.
3. Token sayısı eşitse daha uzun normalize alias kazanır.
4. Hâlâ iki farklı alan eşitse **mutation yok → clarification**.
5. Farklı ve çakışmayan token aralıklarında iki güvenli alan bulunursa çok-alan sonucu üretilebilir.

Örnek:
- `telefon whatsapp numaramı ...` içinde daha spesifik `telefon whatsapp` phrase'i aynı span üzerindeki `telefon` alias'ından üstündür.
- `telefonumu ... yap, adresimi ... yap` iki ayrı güvenli span ise iki alan üretilebilir.

## Negation / belirsizlik güvenliği

Matcher yalnız **alanı** bulur; mutation kararı değildir.

- `telefonu değiştirme` gibi olumsuz cümlede alan bulunabilir ama action katmanı negation/komut semantiğini güvenli şekilde çözmeden yazma yapılamaz.
- Değer yoksa `needsClarification`.
- Geçersiz değer varsa mutation yok.
- Aynı span için belirsiz iki alan varsa mutation yok.

## Sonuç kontratı

Matcher yüzdesel confidence üretmez.

```text
matchClass:
  exact_phrase
  exact_token
  inflected_safe
  fuzzy_suggestion
  ambiguous
  none
```

Her sonuç en az şunları taşır:

```text
alanAnahtari
matchedAlias
matchClass
startToken
endToken
```

`fuzzy_suggestion`, `ambiguous`, `none` doğrudan typed mutation action üretemez.

## Flutter ↔ Next parity şartı

Tek bir shared fixture seti iki runtime'da da aynı sonucu vermeden matcher tamamlanmış sayılmaz.

Zorunlu koruma fixture'ları:

- `Telefonumu 0212 555 55 55 yap` → `telefon`
- `Otelimiz bugün açık` → `telefon` **olmamalı**
- `Adresimi Atatürk Cad. No:24 yap` → `adres`
- `Kategorimi Kuaför yap` → `kategori`
- `İli İstanbul yap` → `il`
- `Profil bilgisinde URL var` → yalnız gerçek `url` token bağlamı; kelime içi eşleşme yok
- ilgisiz günlük cümle → `none`
- tek harf yazım hatasıyla benzersiz uzun alias → yalnız `fuzzy_suggestion`, mutation yok
- iki eşit alan adayı → `ambiguous`, mutation yok
- iki bağımsız alan → iki ayrı span, sıralı ve deterministik sonuç

## Araştırma dayanağı

- Unicode UAX #29: kelime sınırları/search kullanımında text segmentation; dil özelinde tailoring gerekebilir.
- spaCy rule-based matching yaklaşımı: phrase/token tabanlı ve normalize token attribute üzerinden deterministik eşleştirme.

Bu referanslar bağımlılık ekleme kararı değildir; Vixrex matcher'ı mevcut TypeScript/Dart stack içinde kalır.

## LOCK sonucu

**Matcher tasarım kararı: LOCKED.**

BUILD sırasında yapılacak değişiklik dar tutulur:

- mevcut iki resolver algoritması bu kontrata hizalanır,
- shared fixture eklenir,
- 46-alan sözlüğü korunur,
- extractor/executor/persistence bu adımda yeniden yazılmaz,
- Blog/Dijital Çarşı domain'i bu adımda açılmaz.
