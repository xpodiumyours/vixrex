# PayTR Canlı Kurulum Kontrol Listesi

Durum: **kod ve veritabanı hazır** (PR #211 main'de, migration canlıda).
Bu belge yalnız PayTR panel numarası/anahtarları gelince uygulanır.

## 1. Neler zaten hazır (atlanmaz, tekrar yapılmaz)

- [x] `create_premium_order` + `record_premium_payment` RPC'leri **canlıda** (yalnız service_role)
- [x] `/api/paytr/create-link` + `/api/paytr/callback` rotaları main'de (Vercel deploy sonrası canlı)
- [x] İmza formülü tek dosyada: `public_web/src/lib/paytr.ts`
- [x] Migration kayıtları canlı `schema_migrations`'da (CLI formatı)

## 2. Numara/anahtarlar gelince — Vercel (vixrex-public, Production)

Kodun okuduğu değişkenler (eksikse create-link **503 "henüz yapılandırılmadı"** döner, site çökmez):

| Değişken | Kaynak | Zorunlu |
|---|---|---|
| `PAYTR_MERCHANT_ID` | PayTR panel → Destek & Kurulum → Entegrasyon Bilgileri | ✅ |
| `PAYTR_MERCHANT_KEY` | aynı yer | ✅ |
| `PAYTR_MERCHANT_SALT` | aynı yer | ✅ |
| `PAYTR_MERCHANT_PASS` | panelde parola varsa (yoksa boş bırak) | ⬜ |

Ekleme yolları:
- **Panel:** Vercel → vixrex-public → Settings → Environment Variables → Production + "Encrypt"
- **CLI (proje dizininden):**
  ```bash
  cd public_web
  vercel env add PAYTR_MERCHANT_ID production
  vercel env add PAYTR_MERCHANT_KEY production
  vercel env add PAYTR_MERCHANT_SALT production
  # (gerekirse) vercel env add PAYTR_MERCHANT_PASS production
  ```
  Her biri değeri sorar. Sonra yeni production deploy tetiklenir (main'e push veya
  `vercel --prod`).

## 3. PayTR panelinde

1. **Link API** erişimini kontrol et (panelde aktif olmalı).
2. **Callback URL** kaydet: `https://vixrex-public.vercel.app/api/paytr/callback`
   - Not: `vixrex.app` özel alan adı şu an sunucuya bağlı değil (curl 000). Alan adı
     bağlandığında callback URL bu alan adıyla güncellenir — kod değişmez, yalnız paneldeki adres.
3. Link API ayarlarında **tek kullanımlık link** (link_type=0) ve **taksitsiz** seçenekleri
   kod tarafında zaten sabit — panelde onayla.

## 4. İlk ödeme teyidi (kritik — imza formülü `DOĞRULANACAK` idi)

İmza formülü dev.paytr.com erişilemediği için araştırma notuna dayanıyor. İlk canlı
ödemede formül birebir teyit edilir:

1. Gerçek bir esnafla 299 TL'lik ödeme akışını başlat (`/api/paytr/create-link`).
2. Ödeme sayfası açılıyorsa create-link imzası **doğrudur** (ilk kontrol bu).
3. Ödemeyi tamamla (küçük tutar için PayTR test kartı yoksa gerçek 299 TL — geri iade edilebilir).
4. Callback doğrulaması:
   ```bash
   # DB'de sipariş paid + premium uzadı mı:
   # Supabase dashboard → SQL Editor:
   select merchant_oid, status, amount_kurus, paid_at from public.premium_orders order by created_at desc limit 3;
   select id, slug, premium_expires_at from public.stores where premium_expires_at is not null limit 3;
   ```
5. **Formül tutmazsa:** imza reddedilir (`FAIL` + log). Düzeltme **yalnız**
   `public_web/src/lib/paytr.ts` içindeki `paytrCreateToken`/`paytrCallbackToken`
   formülüdür (tek doğruluk kaynağı) — küçük düzeltme PR'ı ile main'e iner,
   Vercel otomatik deploy eder. Başka hiçbir dosyaya dokunulmaz.

## 5. Güvenlik hatırlatması (kodda zaten var)

- Premium'u **yalnız doğrulanmış callback** yazar; istemciden yazma yolu yok
- Tutar callback'ten değil, siparişte saklanan tutarla karşılaştırılır (`AMOUNT_MISMATCH`)
- Aynı `merchant_oid` tekrarı süreyi uzatmaz (replay koruması)
- Sırlar asla koda/log'a yazılmaz — yalnız Vercel env (secret)

## 6. Bu belgeyi ne zaman güncelle

- Numara/anahtarlar eklendiğinde: bu bölümün başına "✅ uygulandı (tarih)" notu.
- İmza formülü canlıda teyit edildiğinde: `paytr.ts`'teki `DOĞRULANACAK` notunu kaldır.
- `vixrex.app` bağlandığında: callback URL'ini güncelle.
