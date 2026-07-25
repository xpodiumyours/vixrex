# Profil güçlendirme planı — 5 sorun + Keşfet kalite barı

**Kapsam:** Public vitrin (`public_web`) + gerekli panel/payload hizası (Flutter).  
**Hedef:** Çalışma saatleri, kategori chip, ürün görseli, Google ikonu, Açık/Kapalı.  
**+ Yeni:** Public ürün kartları, Keşfet `VitrinStoreCard` kalite barına yaklaşsın (OCR/panel sızıntısı yok).  
**Yöntem:** Mevcut mimari analizi → rakip/UX araştırması → cerrahi fazlar.  
**Deploy / commerce / analitik P0 bu planda yok.**

---

## 0.1 Keşfet vs public kart — dahil mi?

| | Keşfet (`localhost:5000`) | Public katalog (`/v/slug`) |
|--|---------------------------|----------------------------|
| Bileşen | Flutter `VitrinStoreCard` | Next `ProductCatalog` |
| Nesne | **Vitrin / mağaza** | **Ürün** |
| Kalite | CANLI badge, temiz kapak, tek kategori, konum, WA CTA | Şu an: OCR ekran görüntüsü, “ssss”, panel UI sızıntısı |

**Cevap:** Eski planda sadece “görsel fallback” vardı — **Keşfet kart kalitesine hizalama tam dahil değildi.**  
Ekranındaki sorun (fatura/OCR UI’nin ürün görseli gibi çıkması) ayrı kök neden: `products.image_urls` içine panel/OCR screenshot URL’si yazılmış.

Bu belgeye **Faz E** olarak eklendi.

### Keşfet’ten alınacak kalite kuralları (ürün kartına uyarlanmış)
1. Medya alanı her zaman “vitrin kalitesinde” dolu (gerçek ürün/logo/kapak veya nötr marka placeholder)  
2. Panel/OCR/Chrome UI görseli **asla** müşteriye çıkmaz  
3. Tek tip footer: ad + fiyat (placeholder “ssss” jargonu yok; boşsa gizle veya “Fiyat sorun”)  
4. Kart oranı / radius / koyu zemin Keşfet kartıyla aynı dil (`vitrin-shell` token)  
5. Keşfet’teki yeşil WA butonu ürün kartında zorunlu değil (kart tıklanınca ürün sayfası + orada WA) — ama görsel dil aynı aile

### OCR görsel sızıntısı — kök neden araştırması
- [x] Public filtre: junk ad + şüpheli UI screenshot URL heuristic + OCR source görsel yok sayma  
- [x] Geçici güvenlik ağı: katalogda logo/kapak/harf fallback  
- [ ] Panel yayın öncesi görsel kalite uyarısı (Faz D)

---

## 0. Araştırma özeti (ne yapmalı?)

| Konu | Sektör standardı | Vixrex’e uygun seçim |
|------|------------------|----------------------|
| Saatler | Yapılandırılmış haftalık tablo + bugün vurgusu + “Open until…” | Booking’deki gün map’ini **tek kaynak** yap; string `stores.working_hours` ikincil |
| Açık/Kapalı | Saatten canlı hesap; manuel override (tatil) | `Europe/Istanbul` ile hesap + panelde “Manuel zorla” opsiyonu |
| Kategori | Tek birincil kategori | Public’te tek chip = resolved profile label; `business_type` serbest etiket veya gizle |
| Ürün görseli | Boş kart yok / kaliteli placeholder | Katalog: logo→kapak→kategori placeholder; OCR sızıntısı yok |
| Google vs Yol | Farklı ikon + metin | `GoogleIcon` + “Google” / “Yorum”; pin sadece Maps |
| Kart kalitesi | Keşfet store card barı | Public ürün kartı aynı dil + temiz medya |

Kaynak ilkeler: GBP/Yext tarzı “bugün + hafta listesi”; timezone wall-clock (TR için `Europe/Istanbul`).

---

## 1. Mevcut yapı analizi (kök neden)

### 1.1 Çalışma saatleri görünmüyor

**İki paralel model var:**

| Kaynak | Şekil | Nerede dolduruluyor | Public’te |
|--------|--------|---------------------|-----------|
| `stores.working_hours` | **string** (`StoreData.workingHours`) | Yayın payload: `data.workingHours.trim()` | `page.tsx` sadece `typeof === "string"` ise gösteriyor |
| `booking_settings.working_hours` | **map** `{ "1": {start,end,active}, … }` | `WorkingHoursEditor` / randevu | Public **okumuyor** (sadece `is_enabled`) |

Sonuç:
- Panelde kullanıcı gün gün saat giriyor → çoğu zaman **booking** map’ine yazılıyor.
- `stores.working_hours` string çoğu mağazada boş → connect’te saat yok.
- JSON-LD tarafı `store.working_hours`’u **obje** sanıyor; string gelince schema da bozuk/eksik kalabilir.

**Flutter public ekran** (`vitrin_header_identity`) de string bekliyor — aynı borç.

### 1.2 Kategori chip karmaşası (Diğer + Butik)

| Alan | Default / anlam | Public chip |
|------|-----------------|-------------|
| `kategori` | Default `'Diğer'` (`StoreEditorController`) | İşletme kategorisi (config id/label) |
| `business_type` | Default `'Butik'` (`StoreData`) | Serbest “işletme tipi” metni; kategori seçiciyle senkron değil |

`resolveVitrinProfile(kategori, businessType)` fallback ile **metin/CTA düzeldi**, ama UI hâlâ iki chip basabiliyor:
- `showKategoriChip`: `Diğer` gizleniyor ✅  
- `showBusinessChip`: `Butik` kalıyor → kullanıcı “neden Butik?” diyor; aslında default kalıntı.

Kök: **tek kaynak yok**; panel `business_type`’ı kategori seçince güncellemiyor.

### 1.3 Boş / zayıf ürün görselleri

- Katalog: `getProductImages(product)[0]` — yoksa düz “Ürün görseli bekleniyor”.
- Ürün detay: logo/kapak fallback var; **katalogda yok**.
- OCR / fatura / Excel ürünleri sıkça `image_urls=[]`.
- Placeholder metni paneli çağrıştırıyor (müşteri yüzü değil).

### 1.4 Google ikonu = Yol tarifi

`VitrinProfileView` secondary satırında:
```tsx
googleBusinessLink → <MapPinIcon />  // aynı pin
maps → <MapPinIcon />
```
Connect’te “Google yorum” metin butonu var; hero ikon satırı karışık.

### 1.5 Açık/Kapalı saate bağlı değil

- Panel: dropdown `Açık` / `Kapalı` → `stores.status` string.
- Public: `status === "Kapalı"` ise kırmızı pill; aksi halde yeşil.
- Saat map’i ile **hiç bağ yok**; gece 03:00’te “Açık” kalabilir.

---

## 2. Hedef davranış (onaylı varsayılanlar)

### Saatler
1. Öncelik sırası: `booking_settings.working_hours` (map) → değilse parse edilebilir `stores.working_hours` string → yoksa gizle.  
2. Connect: kompakt satır **“Bugün 09:00–19:00”** + isteğe bağlı haftalık liste (accordion / `<details>`).  
3. JSON-LD `openingHoursSpecification` aynı map’ten üretilir.  
4. Timezone: `Europe/Istanbul` (v1; panel timezone alanı yok — TR odaklı yeterli).

### Açık/Kapalı
1. Varsayılan: saatten hesapla (`isOpenNow`).  
2. Panel “Manuel durum” açıksa `stores.status` override (tatil günü).  
3. Hero pill: `Açık · 19:00’a kadar` / `Kapalı · Yarın 09:00`.  
4. Saat yoksa: mevcut manuel `status` (geriye uyum).

### Kategori chip
1. Public’te **tek chip**: `profile.label` (resolved).  
2. `business_type` chip’i gösterme **veya** sadece `kategori`/profile’dan farklı ve anlamlıysa göster (allowlist değil; boş/`Butik` default ve `profile.label === Butik` değilse dikkat).  
3. Panel (küçük): kategori seçilince `business_type = config.label` senkron (opsiyonel aynı PR veya Faz B).

### Ürün görseli
1. Katalog fallback zinciri: ürün görseli → `logo_url` → `shelf_image_url` → kategori nötr gradient + baş harf (OCR UI yok).  
2. Metin: “Görsel yok” (panel jargonu yok).  
3. Panel tarafı (ayrı not): yayın öncesi “görselsiz ürün N adet” uyarısı — bu planda opsiyonel Faz D.

### Google vs Yol
1. Yeni `GoogleIcon` (çok renkli G veya tek renk “G” marka glifi).  
2. Hero secondary: Google → GoogleIcon, `aria-label="Google"`.  
3. Pin sadece Yol tarifi / Maps.  
4. Connect: “Google yorum” yanında küçük G ikonu (opsiyonel).

---

## 3. Teknik tasarım (cerrahi)

### Yeni / güncellenecek dosyalar

| Dosya | İş |
|-------|-----|
| `public_web/src/lib/workingHours.ts` | Parse map/string; `formatTodayHours`; `isOpenNow`; `toOpeningHoursSpec`; `nextChangeLabel` |
| `public_web/src/app/v/[slug]/page.tsx` | booking hours + store hours birleştir; status resolve; props |
| `public_web/src/app/v/[slug]/VitrinProfileView.tsx` | saat UI; tek chip; GoogleIcon; pill metni |
| `public_web/src/lib/vitrinBrandIcons.tsx` | `GoogleIcon` |
| `public_web/src/app/v/[slug]/ProductCatalog.tsx` | fallback görsel props |
| `lib/controllers/store_editor_controller.dart` *(Faz B)* | `selectCategory` → `businessType = label` |
| Panel status UI *(Faz C)* | “Otomatik (saatlere göre)” / “Manuel Açık” / “Manuel Kapalı” |

### `workingHours.ts` sözleşmesi (özet)

```ts
type DayHours = { start: string; end: string; active: boolean };
type WeekMap = Record<string, DayHours>; // "1".."7" = Pazartesi..Pazar (mevcut booking)

function normalizeWeekMap(raw: unknown): WeekMap | null;
function formatTodayLine(map: WeekMap, now?: Date): string | null; // "Bugün 09:00–19:00" | "Bugün kapalı"
function resolveOpenState(map: WeekMap | null, manualStatus: string | null, now?: Date): {
  isOpen: boolean;
  label: string;       // "Açık" | "Kapalı"
  detail?: string;     // "19:00'a kadar"
  source: "hours" | "manual" | "fallback";
};
```

Öğle arası (`lunch_break`): v1’de **hesaba katma** (cerrahi sınır); v1.1’de `isOpenNow` içine ekle.

### Status resolve önceliği
1. Manuel override flag yokken + map varsa → saat  
2. Manuel override / veya map yok → `stores.status`  
3. Hiçbiri → `"Açık"` (bugünkü default)

> Not: DB’de `status_mode` kolonu yoksa v1: **map varsa saati kullan, yoksa status**. Manuel tatil için kısa vadede işletme “Kapalı” seçer (saat map’i yok sayılmaz — çakışma riski).  
> **Tercih edilen v1 kuralı:** map varsa canlı saat; panelde “Bugün kapalı (manuel)” için ileride flag. İlk PR’da: map varsa saat kazanır (işletme tatildeyse booking gününü kapatır veya status=Kapalı **ve** map yok/boş).  
> Daha temiz: `status === "Kapalı"` her zaman override (manuel tatil), aksi halde saatten hesapla. **Bu planın seçimi: Kapalı override > saat > Açık fallback.**

---

## 4. Uygulama fazları

### Faz A — Public saat + Açık/Kapalı (çekirdek) — DONE
- [x] `workingHours.ts`  
- [x] `page.tsx`: `bookingResult.data?.working_hours` + store string  
- [x] Connect’te bugün satırı + 7 gün `<details>`  
- [x] JSON-LD opening hours map’ten  
- [x] Hero pill: `resolveOpenState` (`Kapalı` override)  
- [ ] Smoke: saatli mağaza + saatleri boş mağaza (lokal doğrula)

**Dokunma:** Flutter yayın modeli (A’da zorunlu değil).

### Faz B — Chip + Google ikon — DONE
- [x] Tek chip = `profile.label`  
- [x] `business_type` chip kaldırıldı (tek etiket)  
- [x] `GoogleIcon` + Maps pin ayrımı  
- [x] Flutter `selectCategory` → `businessType = config.label`  

### Faz C — Katalog görsel fallback — DONE
- [x] `ProductCatalog` props: `fallbackImage`, `storeInitial`  
- [x] Zincir: ürün → logo → kapak → harf+gradient  
- [x] Placeholder metni sadeleştir  
- [ ] Smoke: görselsiz OCR ürünü (lokal doğrula)

### Faz E — Keşfet kalite barı (public ürün kartı) — DONE
- [x] Kart iskeleti: Keşfet dilinde radius / koyu footer / tipografi  
- [x] OCR/panel screenshot heuristic + source_type görsel yok sayma  
- [x] Çöp ürün adı (`ssss` vb.) public’te gizle  
- [ ] Smoke: Keşfet kartı yanında public ürün grid (lokal doğrula)

### Faz D — Panel güçlendirme (ayrı, isteğe bağlı)
- [ ] Status: Otomatik / Manuel Açık / Manuel Kapalı  
- [ ] `stores.working_hours` string’i yayınında map’ten özet üret (geriye uyum: eski Flutter public)  
- [ ] Görselsiz ürün yayın uyarısı  

---

## 5. Bilinçli sınırlar (bu planda yok)

- Tatil / özel gün takvimi  
- Çoklu zaman dilimi UI  
- Öğle arası v1  
- Zorunlu ürün görseli (bloklayan validasyon)  
- Google yorumları API ile çekme  

---

## 6. Doğrulama checklist

1. `sdene` (veya booking saatleri dolu slug): Connect’te **Bugün …** görünür.  
2. Gece saatinde pill **Kapalı** (map’e göre) — manuel `Kapalı` değilse.  
3. Manuel `Kapalı` seçili mağaza: her zaman Kapalı.  
4. Chip: tek anlamlı etiket (Butik+Diğer yan yana yok).  
5. Hero: Yol = pin, Google = G ikonu.  
6. Katalog: görselsiz üründe logo/kapak veya harf kartı; “Fotoğraf Çek” hissi yok.  
7. `tsc --noEmit`  
8. Mobil + masaüstü smoke (`localhost:3000/v/SLUG`)

---

## 7. Onay sorusu (tek)

Açık/Kapalı kuralı:
- **A (önerilen):** `status === "Kapalı"` her zaman kazanır; değilse saatten hesapla; saat yoksa `status`/`Açık`
- **B:** Her zaman sadece saat; manuel status yok sayılır

Onay → Faz A’dan uygulamaya geç.
