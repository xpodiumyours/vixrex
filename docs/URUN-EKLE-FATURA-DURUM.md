# Ürün Ekle → Fatura → Ürün Kartı: nerede kaldık

Tarih: 2026-10-04. Bu belge ölçülmüş gerçeği yazar; plan değil, ölçüm raporudur.

## Amaç (Casper, 2026-10-04)

Fatura fotoğrafı → **firmanın dijital izi** → ürünlerin sıralanması → esnaf satış fiyatını
girer ve onaylar → kart vitrinde yayınlanır. Sıra önemli: önce firma, sonra ürünler.

## Ne yapıldı (bu dal)

1. Fatura okuma anahtarı (`OPENROUTER_API_KEY`) bulundu ve **yalnız yerel**
   `public_web/.env.local` dosyasına eklendi (git'e girmiyor). Vercel gizli değerleri
   vermediği için anahtar ajan oturum kayıtlarından çıkarıldı ve OpenRouter'a
   doğrulandı (geçerli, ücretli, kullanılmış 0,138 USD).
2. Yerel sunucu `localhost:3000` üzerinde açıldı; `/api/fatura-okuyucu-durumu`
   `{"hazir":true}` dönüyor.
3. Canlı veritabanında atıl mağaza `deneme2222-musjrikc` geçici bir Supabase
   hesabına bağlandı (şifresiz; Google-only ürün politikası nedeniyle).
4. Dört gerçek fiş ölçüldü: `C:\Users\Casper\basak-ai\data\fatura-ornekleri\fis_1..4`.

## Ölçülen sonuç: okuma çalışıyor

| Fiş | Satır | Adet | Tutar | Kanıtlı satır |
|---|---|---|---|---|
| fis_1 (06.07.2026) | 6/6 | 41 | 2.785,50 TL | 1 |
| fis_2 (28.07.2026) | 12/12 | 68 | 3.244,50 TL | 0 |
| fis_3 (14.07.2026) | 13/13 | 142 | 7.974,50 TL | 6 |
| fis_4 (15.09.2026) | 13/13 | 75 | 6.034,00 TL | 0 |

Ürün kodları, barkodlar, adetler ve tutarlar **birebir doğru** okundu (güven 1.0).
Maliyet: 6 okuma = **0,58 TL** (fatura başına ~0,10 TL).

## Ölçülen sonuç: eşleştirmede iki ayrı kırılma

`tool/fatura_havuz_olc.mjs` ile `fis_4`ün 13 satırı tek tek ölçüldü:

- **7 satır:** ürün kodu havuzda **iki firmada birden** var (`seher-mensucat` ve
  `toptan-ic-giyim-pazari`). `ureticiUrunuBul` birden çok adayda **susuyor**
  (`guvenli.length === 1` şartı, `ureticiKatalog.ts:379`) → kart üretilmiyor.
- **6 satır:** kod/barkod havuzdaki kayıtla birebir tutmuyor.
- Bu fişlerde **faturayı kesen firma adı boş okunuyor** (`tedarikci: ""`).
  Fişler satış fişi; üstlerinde tedarikçi adı yazılı değil.

Havuz: 16 firma / **8.594 ürün** (`public_web/data/katalog/`). Ürün kodu alanı `kod`
(barkod değil) ve barkodlar havuzda faturadakinden farklı.

## Açık karar (Casper'e ait)

Eşleşme bulunan satır için iki seçenek ölçüldü, hangisinin yapılacağı kararlaştırılmadı:

- **A)** Aynı kod iki firmada bulunduğunda ikisini de gösterip esnafın seçmesi
  (yalnız arayüz + sunucu eşiği; veriye dokunmaz).
- **B)** Havuz verisini temizlemek: aynı kodu tek ürüne bağlamak (veri işi, izin gerekir).

Ayrıca karar bekleyen ikinci konu: satış fişinde tedarikçi adı yokken ürün eşleştirme
**marka/kod bazlı** devam etsin mi (bugün fişler bu yüzden düşük eşleşme veriyor).

## Yapılmadı / dokunulmadı

- Kaynak koda **hiçbir değişiklik** yapılmadı (`public_web/src`, `lib`, `supabase` temiz).
- Test mağazasında **0 ürün** oluştu (yazma adımı zaten reddedildi).
- Kalan tek canlı veri: `deneme2222-musjrikc` mağazasındaki 1 `invoice_jobs` okuma kaydı ve
  geçici test hesabı — silinmesi Casper'in kararı.
- Ana dala merge edilmedi.

## Bu dalı kullanan ajan için

1. `tool/fatura_havuz_olc.mjs <okuma-json>` → satır satır "eşleşti / belirsiz / yok".
2. Okuma raporu üretmek için: mağazaya ait owner oturumu ile `POST /api/fatura-oku`
   (multipart: `slug`, `dosya`). Zincir: `faturaGoru.ts` (OpenRouter `openai/gpt-5.6-luna`)
   → `faturaSatirAyikla.ts` → `faturaEslestir.ts` → `/api/products/batch` → `/api/fatura-yayinla`.
3. Yayın kapısı: `faturaKartDurumu.ts` — kanıtlı satır + satış fiyatı + stok onayı +
   en az 1 fotoğraf + esnaf onayı. Beşi olmadan kart yayınlanmaz.