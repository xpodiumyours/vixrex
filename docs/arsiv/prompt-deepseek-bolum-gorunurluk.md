# deepseek görevi — Next.js section_visibility'i gerçekten okusun (ACİL — #70'in eşleniği)

Bu dosyanın tamamı tek seferde deepseek'e yapıştırılacak prompt'tur.
Aşağıdaki çizginin altındaki her şey kopyalanır.

---

Sen VixRex deposunda çalışıyorsun: `C:\Projects\vixrex`.

## 1. Sorun (ölçüldü, doğrulandı — bugün)

`stores.section_visibility` sütunu var (JSONB, 7 anahtar: `categories`,
`products`, `about`, `gallery`, `blog`, `faq`, `contact`). PR #70 bu
sütunu Flutter'daki manuel panelden yazılabilir yapıyor (7 açık/kapalı
anahtarı).

**Ama Next.js tarafı bu sütunu hiç okumuyor.** Doğrulandı:

- `public_web/src/app/v/[slug]/page.tsx`'teki `PUBLIC_STORE_SELECT`
  sorgusunda `section_visibility` **yok** — veritabanından çekilmiyor
  bile.
- `VitrinProfileView.tsx`'te bölümlerin gösterilip gösterilmeyeceği
  (`showAbout`, `showGallery`, `showFaq`, `showContact`, `showArticles`,
  `collections.length > 0`, `productCount > 0`) **yalnız veri dolu mu**
  diye bakıyor — `section_visibility`'e hiç bakmıyor.

**Sonuç:** Esnaf Flutter panelinden "blog bölümünü gizle" dese bile
vitrinde blog hâlâ görünür (veri doluysa). Anahtar hiçbir işe yaramıyor.

**Bu iş #70 ile birlikte tamamlanmadan #70 yarım demektir** — Casper'ın
kararı, öncelikli.

## 2. Yapılacaklar

### A. Sorguya ekle

`public_web/src/app/v/[slug]/page.tsx` — `PUBLIC_STORE_SELECT` string'ine
`section_visibility` ekle (satır ~141-150, virgülle ayrılmış liste).

### B. Prop olarak taşı

`store.section_visibility`'i `VitrinProfileView`'e yeni bir prop olarak
geçir: `sectionVisibility: Record<string, boolean> | null`.
`VitrinProfileView.tsx`'teki `interface` tanımına (satır ~100-140
civarı, diğer prop'ların yanına) ekle.

### C. Yedi `show*` hesabına uygula

`VitrinProfileView.tsx` içinde küçük bir yardımcı fonksiyon yaz:

```ts
const bolumGorunur = (anahtar: string, varsayilan: boolean) =>
  sectionVisibility?.[anahtar] === false ? false : varsayilan;
```

Sonra yedi yeri **birebir bu satırlar**, sadece `varsayilan`'ı eski
hesaplamaya sarmalayarak değiştir — mantığı bozma, yalnız üstüne
`false` durumunda kapatan bir katman ekle:

| Bölüm | Anahtar | Şu an (satır ~) | Olacak |
|---|---|---|---|
| Kategoriler | `categories` | `collections.length > 0` (312, 433) | `bolumGorunur('categories', collections.length > 0)` — yeni bir `showCategories` değişkeni tanımla, iki yerde de onu kullan |
| Ürünler | `products` | `productCount > 0` (528) | `bolumGorunur('products', productCount > 0)` — yeni `showProducts` değişkeni |
| Hakkımızda | `about` | `showAbout` (226) | `bolumGorunur('about', ...)` sarmala |
| Galeri | `gallery` | `showGallery` (236) | aynı desen |
| Blog | `blog` | `showArticles` (246) | aynı desen |
| SSS | `faq` | `showFaq` (242) | aynı desen |
| İletişim | `contact` | `showContact` (251) | aynı desen |

**Kural (migration açıklamasından, `20260804220000_add_owner_editable_section_labels.sql`):**
Anahtar yoksa ya da `true`/başka bir şeyse → eski davranış (veri
doluluğuna göre otomatik). Anahtar **kesin `false`** ise → bölüm
kapansın, verisi olsa bile.

## 3. Kesin kurallar

1. Yalnız `public_web/src/app/v/[slug]/page.tsx` ve
   `public_web/src/app/v/[slug]/VitrinProfileView.tsx`'e dokun.
2. Mevcut `show*` değişkenlerinin isimlerini değiştirme (testler/başka
   kod onlara bağlı olabilir) — yalnız hesaplama mantığını
   `bolumGorunur(...)` ile sarmala.
3. `section_visibility` boş/null ise **hiçbir vitrinin görünümü
   değişmemeli** — bugün main'de olan hiçbir mağaza etkilenmeyecek,
   bunu doğrula.
4. Sahip modu işaretleyicilerine (`editableProps`) dokunma.
5. Türkçe yaz, depo kuralına uy.

## 4. Doğrula

1. `npx tsc --noEmit`, `npm run lint`, `npm run build` temiz.
2. Yerel/test bir mağazada SQL ile `section_visibility` sütununu
   `{"blog": false}` yap → sayfayı aç → blog bölümü **kesin kaybolmalı**
   (veri dolu olsa bile). Sonra `{}` yap → geri gelmeli.
3. `section_visibility` `NULL`/`{}` olan mevcut bir mağazada (ör.
   demo mağazalardan biri) **hiçbir görsel fark olmamalı** — öncesi/
   sonrası ekran görüntüsüyle kanıtla.
4. Mümkünse uçtan uca dene: PR #70'in Flutter kodu aynı ortamda
   varsa, panelden bir bölümü kapat → yayınla → vitrinde gerçekten
   kayboluyor mu bak. Ortamda yoksa SQL ile simüle et (madde 2 yeterli).

## 5. Dal

`duzeltme/bolum-gorunurluk-nextjs` main'den (worktree hazır:
`C:\Projects\vixrex-bolum-gorunurluk-worktree`).

## 6. Nasıl rapor ver

Kanıtla, anlatma. `tsc`/`lint`/`build` çıktıları, `section_visibility`
dolu/boş iki durumun ekran görüntüsü. Uydurma yasak — "hiçbir mağaza
etkilenmedi" diyorsan gerçek bir mağazada gerçekten baktığını göster.
