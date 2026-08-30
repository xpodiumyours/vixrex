# Görev — web'de ürün yönetimi arayüzü

**Yazan:** Claude (27 Ağustos 2026) · **Yürüten:** Codex (bulut)
**Dal:** `feat/web-yonetim-akislari` — `main` DEĞİL.

---

## Önce: işini push et

Bir önceki turda UI/UX eşitleme çalışman **GitHub'a gönderilmedi** — uzakta ne
dal var ne PR. O iş şu an yalnız senin kutunda ve doğrulanamıyor.

**İlk yapacağın:** o çalışmayı `feat/web-yonetim-akislari` üstüne bir dala
push et ve PR aç. Bu görev ondan sonra başlar.

---

## Neden bu görev

Bir önceki turun hükmü "HÂLÂ PARÇALI"ydı ve en büyük eksik olarak **web'de
ürün yönetimi** işaretlendi. Kullanıcı web'de vitrin kurabiliyor ama ürün
ekleyemiyor; ürün için Flutter zorunlu.

Bu görev yalnız o boşluğu kapatır. Profil, ayarlar, admin ve Google ile giriş
**bu görevin dışında** — ayrı ele alınacak.

---

## Zaten var olanı yeniden yazma

Ürün API'leri **hazır ve denetlenmiş** durumda, dalda mevcut:

`public_web/src/app/api/products/route.ts`

- `POST` — ürün ekle
- `PATCH` — ürün güncelle
- `DELETE` — ürün sil

Üçü de:
- `verifyOwnerSession` çerezini doğrular (401 döner),
- istemciden gelen kimliğe **güvenmez**, vitrini `ownerSession.storeId`
  üzerinden bulur,
- işlemi vitrinin kendi `edit_token`'ıyla RPC'ye yaptırır; RPC ürünün gerçek
  vitrinini bulup yetkiyi ona karşı denetler.

**Yeni API yazma. Yeni Supabase sorgusu açma. Yetki kontrolünü arayüzde
uydurma.** Senin işin bu API'lerin üstüne arayüz koymak.

---

## Yapılacak

`/app` (sahip panosu) içinde ürün yönetimi:

1. **Liste** — vitrinin ürünleri. Boş durum, yükleniyor durumu ve hata
   durumu bir önceki turda kurduğun yönetim diliyle aynı olsun.
2. **Ekle** — ad, fiyat, stok, açıklama, görsel (mevcut alan şeması neyse o).
3. **Düzenle** — aynı form, dolu gelir.
4. **Sil** — **onay iste.** Flutter'da silme onay istiyorsa web de istemeli;
   bir platform sorup diğeri doğrudan silmemeli.

Alan adları ve etiketler Flutter'daki ürün formuyla aynı kavramları
kullanmalı — aynı alan iki tarafta farklı isimle görünmesin.

---

## Değişmez sınırlar

Bunlar bir önceki turda tutuldu, aynen geçerli:

- **`--color-lp-*` tokenlarına ve public vitrin renklerine dokunma.** Yayında
  vitrinler var, görünümleri değişemez.
- **`/`, `/kesfet`, `/v/[slug]` sunucu bileşeni kalacak.** Etkileşim eklemek
  için `"use client"` koymak SSR'ı ve SEO'yu sessizce öldürür; sayfa çalışır,
  testler yeşil kalır, Google farklı görür. Eklediğin sözleşme testini koru.
- **Ana sayfadaki telefon mockup'ındaki sohbet makettir**, motora bağlanmaz
  (`VIXREX_RULES.md` §1).
- **`lib/screens/landing_screen.dart` ve `lib/widgets/landing/` silinmez** —
  APK'nın açılış ekranı ve eşitlik testinin kaynağı.
- Veri/backend katmanını değiştirme.

---

## Doğrulama — bu sefer eksiksiz olmalı

Bir önceki turda `next build` ve tip kontrolü **koşturulamadı** (kutunda
`@sentry/nextjs`, `@playwright/test`, `sanitize-html` eksikti). Bu sefer:

```
cd public_web && npm ci && npm run lint && npm test && npm run build
```

`npm ci` bağımlılık sorununu çözer. Koşamıyorsan **koştuğunu söyleme** —
neyin eksik olduğunu yaz.

Ayrıca ürün akışının kendisi için hedefli bir test ekle: en azından ürün
API'sine giden çağrının oturum çerezi olmadan 401 aldığını doğrulayan bir
sözleşme testi.

---

## Kapsam ve durma noktaları

- PR sınırı **12 dosya / 600 satır**. Aşarsan açıklamaya `Kapsam-Onay:`
  satırı gerekir — ama önce bölmeyi dene.
- Bitirince **dur ve raporla.** Profil/ayarlar/admin/Google girişine geçme.
- Emin olmadığın bir domain kararı çıkarsa (ör. ürün silinince ne olacağı,
  stok alanının zorunluluğu) **uydurma** — sor.

## Raporda istenen

Kısa tut. Şunlar olsun:

- Değiştirilen/eklenen dosyalar
- Hangi doğrulama komutları **gerçekten** koştu, çıktıları ne
- Koşamadıkların ve sebebi
- Ürün silme onayı Flutter'daki ile aynı ciddiyette mi
- Kalan eksikler (yalnız kanıtlı olanlar)
