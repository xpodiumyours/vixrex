# Kök neden araştırması — 7 Ağustos 2026

Soru: neden düzelttiğimiz her şeyin yerine yenisi geliyor?

Bu belge tahmin değil, ölçüm. Her iddianın altında sayı var.

---

## Yöntem

Üç ayrı hipotez ayrı ayrı sınandı:

1. **Kimlik yok** — "bu vitrin kime ait" sorusunun cevabı yok
2. **Gerçek dağınık** — aynı veri birden fazla yerde, hangisi doğru belli değil
3. **Tasarım sözleşmesi yok** — görünüm her ekranda ayrı ayrı yazılıyor

Sonra 17 bulgunun (tur listesi + bugün çıkan silme hatası) her biri
gerçek köküne bağlandı. Örüntüye kanmamak için ters yönden de bakıldı:
"bu hipotez doğruysa hangi hatalar OLMAMALIYDI?"

---

## Hipotez 1 — Kimlik yok

### Ölçüm

| Ne | Sayı |
|---|---|
| Buluttaki vitrin | 128 |
| **Sahibi olan (`user_id` dolu)** | **0** |
| Sahipsiz | 128 |
| RLS'i atlayan fonksiyon (`SECURITY DEFINER`) | 25 |
| Bu fonksiyonlardaki `p_edit_token` denetimi | 45 |
| `edit_token` taşıyan dosya | 43 |
| Tek kullanımlık oturum zinciri taşıyan dosya | 14 |

### Bulgu

Hesap sistemi **yazılmış ve duruyor**: `stores.user_id` sütunu var,
`auth.users`'a bağlı, Google girişi kodlanmış. RLS politikaları da doğru
yazılmış:

```sql
CREATE POLICY "Owners can update their stores" ON stores
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);
```

Ama **128 vitrinin 128'i sahipsiz** olduğu için bu politikalar hiç
eşleşmiyor. Bu yüzden her işlem RLS'i atlayan 25 fonksiyondan geçiyor ve
yetkiyi elde taşınan bir anahtar (`edit_token`) belirliyor.

Sonuç: sahiplik katmanı ölü kod. Yerine paralel bir kimlik sistemi
kurulmuş.

**Kimliğin gerçek adresi neresi:** tarayıcının hafızası. Karşılama ekranı
"vitrinin var mı?" sorusunu `SharedPreferences`'a soruyor. Orada isim
yazıyorsa vitrin var sayılıyor — bulutta karşılığı olup olmadığına
bakılmıyor.

---

## Hipotez 2 — Gerçek dağınık

### Ölçüm

Aynı vitrinin hâli dört yerde tutuluyor:

| Yer | Ne zaman yazılır |
|---|---|
| `SharedPreferences` (yerel) | Uygulamada her düzenlemede |
| `stores` (bulut) | Yayınlayınca |
| `store_working_drafts` (bulut) | Tarayıcıda düzenlerken |
| `last_published_*` (yerel) | Yayından sonra |

Alan tanımı dört dosyada: `store_data.dart` (116), `vitrinFieldSchema.ts`
(44), `vitrin_alanlari.json` (45), `vitrin_alanlari.g.dart` (12).

### Bulgu — kısmen çürütüldü

Alan tanımı dağınık **görünüyor** ama üçü tek kaynaktan üretiliyor
(`vitrinFieldSchema.ts` → json → dart). Bu iş 6 Ağustos'ta yapılmıştı.

Vitrin çizimi de artık tek yerde: Flutter'ın vitrin çizen dosyaları
silinmiş (0 dosya), yalnız Next.js çiziyor (9 dosya). Yani "iki uygulama
aynı şeyi ayrı ayrı çiziyor" sorunu **yok**.

Kalan gerçek dağınıklık: yerel kopya ile bulut kopyası arasında kimin
haklı olduğunu söyleyen kural yok. Zaman damgası karşılaştırılıyor, ama
"bulutta kayıt silinmişse yerel ne olacak" sorusunun cevabı hiç yok.

Bu, Hipotez 1'in bir sonucu — bağımsız bir kök değil. Kimlik sunucuda
olsaydı yerel kopya yalnız önbellek olurdu, gerçek olmazdı.

---

## Hipotez 3 — Tasarım sözleşmesi yok

### Ölçüm

| Ne | Sayı |
|---|---|
| Flutter'da tema dışında elle yazılmış renk | 141 |
| `AppColors` kullanan dosya | 88 |
| Tek bir Next.js dosyasında sabit renk/sınıf | 110 |
| Paylaşılan tasarım sözleşmesi | **yok** |

`shared/` klasöründe yalnız `vitrin_alanlari.json` var — o da veri
sözleşmesi, tasarım değil.

### Bulgu

Görünüm her ekranda yeniden karar veriliyor. Yazı tipi 7 Ağustos'ta
birleştirildi ama renk, aralık, balon biçimi, hitap tonu hâlâ dosya
dosya. İki yüzey (Flutter / Next.js) arasında ortak bir dil yok.

Bu, Hipotez 1'den **bağımsız** bir kök. Login gelse de bu sorun durur.

---

## 17 bulgunun kök dağılımı

| # | Bulgu | Kök |
|---|---|---|
| 1 ✅ | Kategori balonları dağınık | Tasarım |
| 2 | GPS koordinat alıyor, adres yok | Yarım işlev |
| 3 ✅ | Kapak fotoğrafı | Tekil hata |
| 4 | Oturum 15 dakikada ölüyor | **Kimlik** |
| 5 | 32 alana ulaşılamıyor | Yarım işlev |
| 6 | Eylem butonları düzenlenmiyor | Yarım işlev |
| 7 | Müşteri görünümü yok | **Kimlik** (kısmen) |
| 8 | Kurulum sonu iki kapı | Tasarım |
| 9 ✅ | Ölü vixrex.com adresi | Tekil hata |
| 10 | Taslak tazelenemiyor | Yarım işlev |
| 11 ✅ | Maskot balonu | Tasarım |
| 12 | "siz" kipi kalmış | Tasarım |
| 13 ✅ | Konum düğmesi yalan söylüyor | Tekil hata |
| 14 | 119 çöp vitrin | **Kimlik** |
| 15 ✅ | Yazı tipi tutarsız | Tasarım |
| 16 | Asistanın yüzü değişiyor | Tasarım |
| 17 | Olmayan vitrin / silinemiyor | **Kimlik** |

**Dağılım:** Tasarım 6 · Yarım işlev 4 · Kimlik 4 · Tekil hata 3

---

## Ters kontrol

**"Login tek sebep" doğru olsaydı** kategori balonlarının dağınık
dizilmesi, yazı tipinin cihazdan cihaza değişmesi, GPS'in adres
çevirmemesi olmamalıydı. Oldular. **Yani iddia yanlış.**

**"Tasarım tek sebep" doğru olsaydı** silinmeyen vitrin ve 119 çöp kayıt
olmamalıydı. Oldular. **O da yanlış.**

Üç kök birbirinden bağımsız. Biri kapanınca diğerleri kapanmıyor.

---

## Neden "düzelttik yerine yenisi geldi" hissi var

Kapanan 6 bulgunun 4'ü tasarım, 3'ü tekil hata. **Kimlik kökünden hiçbir
şey kapanmadı.** O kök her açılışta yeni belirti üretiyor — bugünkü
"olmayan vitrin" hatası gibi.

Yani ilerleme gerçek, ama en gürültülü kök hiç ele alınmadı.

---

## Ne yapılmalı — sıra ve gerekçe

### 1. Kimlik (en derin, en gürültülü)

**Misafir kurar, yayınlarken hesap ister.** 45 saniyelik vaat bozulmaz;
ortada kalıcı bir şey yokken kayıt istenmez.

İlk adım **dört dosya**, 43 değil:
- Yayınlama hesap ister
- `stores.user_id` yayında dolar
- Karşılama "vitrinim var mı"yı buluta sorar
- Silme o cevaba göre çalışır

Kapanan: 4, 7, 14, 17. Oluşamaz hale gelen: sahipsiz kayıt, hayalet
vitrin, elle taşınan anahtar zorunluluğu.

**43 dosyalık sadeleştirme bu adımın parçası DEĞİL.** Mevcut anahtar
sistemi çalışmaya devam eder; sonra parça parça emekliye ayrılır.

### 2. Tasarım sözleşmesi (en geniş)

Ortak bir sözleşme: renk, aralık, yazı ölçüsü, balon biçimi, hitap tonu.
İki yüzeyin de ondan beslenmesi. Yazı tipi 7 Ağustos'ta birleşti — model
o.

Kapanan: 8, 12, 16. Bir daha oluşmayan: "bu ekran neden farklı görünüyor".

### 3. Yarım kalmış işlevler (en somut)

2, 5, 6, 10. Bunlar kök sorun değil, bitmemiş iş. Sırayla biter.

---

## Bu araştırmanın kendi zayıflığı

- `SUPABASE_SERVICE_ROLE_KEY` geçersiz (401). Sayımlar anon anahtarla
  yapıldı; yayınlanmamış vitrinler görülemedi. Toplam 128 rakamı
  yayındakileri kapsıyor.
- Kod ölçümleri metin araması; yorum satırındaki geçişler de sayılmış
  olabilir. Büyüklük sırası doğru, ondalık değil.
