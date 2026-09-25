# Faturadan Kataloğa — Ortak Payda

Tarih: 2026-09-26
Bu belgeyi **iki ajan da** okur: Claude ve Gemini. Amaç tek: aynı işi iki kez
yapmamak ve birbirinin üstüne yazmamak.

Kaynak yalnız **gerçek kod** ve **Casper'ın sözü**. Aşağıdaki her sayı depoda
ölçüldü; tahmin yok.

---

## 1. Zincir ve kimin nerede durduğu

```
[Firma havuzu]      [Ürün/SKU havuzu]        [Fatura akışı]          [Vitrin]
Tekstil-Gida-        kod, barkod,            fotoğraf -> satır       ürün kartı
Firma-Havuzu.xlsx -> görsel, beden    ----->  -> fiyat -> onay  ---->  yayın
55 firma             (EKSİK HALKA)            (HAZIR)
     Gemini                Gemini                 Claude              ortak
```

**Claude'un bitirdiği (dal: `fatura/tarayici-akis`, commit `ed2f81bf`):**
- `supabase/functions/vixrex-fatura-oku` — fatura fotoğrafından satır çıkarır
- `public_web/src/app/api/fatura-oku` — sahiplik + hız sınırı + dosya kontrolü
- `public_web/src/components/owner/InvoiceToProducts.tsx` — prototipteki 4 ekran
- `public_web/src/app/api/products/batch/route.ts` — fatura yayın kapısı
- `supabase/migrations/20260925140000_urun_alis_fiyati_kolonu.sql`
- Kapılar: 1656 test, tsc temiz, lint 0 hata, üretim derlemesi başarılı

**Gemini'nin işi (eksik halka):** firma havuzunu ürün/SKU havuzuna bağlamak.

---

## 2. Birleşme noktası — tek sözleşme

Claude'un akışı bugün ürünü `imageUrls: []` ile gönderiyor. Fotoğraf olmadığı
için ürün **taslak** kalıyor, vitrinde görünmüyor.

Gemini'nin işi bittiğinde bağlantı **tek yerden** kurulur:

> Fatura satırındaki **model kodu** veya **barkod**, ürün havuzunda aranır.
> Eşleşme varsa üreticinin görselleri ve açıklaması `imageUrls` / `description`
> alanlarına konur. Ürün taslaktan çıkar, yayına girer.

Bu eşleşme `InvoiceToProducts.tsx` içindeki `vitrineYaz()` fonksiyonunda tek bir
çağrıyla olur. Başka hiçbir yere dokunmak gerekmez.

**Sözleşme alanları** (fatura okuyucunun ürettiği ve havuzun eşleşeceği isimler):

| Alan | Ne | Kaynak |
|---|---|---|
| `model` | ürün/stok kodu (ELT1302) | fatura |
| `barkod` | 8-14 hane | fatura |
| `varyant` | renk | fatura |
| `beden` | L, XL, 8-10 Yaş | fatura |
| `adet` | miktar | fatura |
| `alisBirimFiyat` | birim alış fiyatı | fatura |

---

## 3. Ölçülen gerçekler — plan bunlara göre kurulur

Gemini'nin 25.09 tarihli öneri metninde üç nokta depoda doğrulanmadı:

1. **`sehermensucat.com` 8/8 değil, 7/8.** Havuz dosyasında öyle yazıyor.
   8/8 alan 19 firma var; Seher onlardan biri değil.

2. **`product_database` tablosu kod, barkod ve görsel tutamıyor.** Bugünkü
   kolonlar: `urun_adi, normalize_urun_adi, marka, marka_alias, kategori,
   alt_kategori, aciklama, anahtar_kelimeler, ocr_eslesme_kelimeleri,
   ambalaj_tipi, hacim_miktar, birim`. Ürün kodu yok, barkod yok, görsel
   adresi yok, firma/kaynak yok. **Aktarımdan önce tablo genişletilmeli.**

3. **Havuz "kod"u ölçmedi.** Puanlama K1 ürün listesi, K2 açıklama, K3 görsel,
   K4 toptan ibaresi üzerine. 55 firmanın örnek ürününde kod görünen sayı: **16**.

Buna karşılık havuzda Gemini'nin belirtmediği **en güçlü kanıt** var:

> Seher Mensucat'ın havuzdaki örnek ürünü: **`ELT1001` Elit Erkek Penye Atlet**
> Casper'ın gerçek faturasındaki kodlar: **`ELT1302`, `ELT1303`, `ELT2203`…**
> Aynı kod ailesi. Site kodu ile fatura kodu birebir aynı biçimde.

**Sonuç: ilk pilot 3-5 marka değil, tek marka — Seher Mensucat.**
Sebep: elde faturası olan tek firma o. Berrak ve Donella 8/8 ama faturaları
yok; onlarda kanıt kurulamaz, yalnız site kopyalanmış olur.

---

## 4. Çakışmama kuralları

- **Ayrı klasör.** Her ajan kendi worktree'sinde çalışır. Aynı klasörde iki
  ajan çalışırsa iş sessizce silinir (26 Ağustos'ta oldu).
- **Ayrı tablo.** Claude `products` tablosuna dokundu (tek kolon).
  Gemini `product_database` tablosuna dokunacak. İkisi birbirine karışmaz.
  Bir ajan diğerinin tablosuna dokunacaksa **önce bu belgeye yazar.**
- **Ayrı dosya.** `InvoiceToProducts.tsx`, `api/fatura-oku`,
  `vixrex-fatura-oku`, `products/batch/route.ts` → Claude'un alanı.
  Firma/ürün havuzu toplayıcısı ve `product_database` migration'ı → Gemini'nin.
- **`lib/` (Flutter) kilitli.** İzinsiz açılmaz.
- **Ana dal kapısı Casper'da.** Hiçbir dal onaysız `main`'e inmez.

## 5. Önizleme nasıl açılır

`public_web/vercel.json` dosyasında yazıyor:

```json
"deploymentEnabled": { "*": false, "main": true, "verify-web-*": true }
```

**Yani önizleme adresi yalnız `main` ve `verify-web-` ile başlayan dallarda
çıkar.** Başka isimli bir dalı itmek önizleme üretmez. Casper'ın gözüyle test
edeceği iş `verify-web-...` adıyla itilmelidir.

## 6. Açıkta duran delik

Flutter tarafındaki eski OCR yolu (`lib/controllers/ocr_controller.dart:215`,
`lib/services/product_catalog_sync_service.dart`) ürünü hâlâ doğrudan görünür
yazıyor ve Next.js kalite zincirini hiç görmüyor. Tarayıcı akışı bundan
bağımsız çalışır; ama Flutter uygulamasından OCR kullanılırsa kural delinir.
Kapatılması ayrı izin ister.
