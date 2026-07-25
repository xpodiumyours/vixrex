# Vitrin 2 — Cerrahi uygulama planı

**Hedef:** `vitrin_2.html` sosyal profil vitrinini, mevcut Next.js public storefront’a (`public_web`) kategori-genel taşımak.  
**Kaynak çizim:** [vitrin_2.html](./vitrin_2.html)  
**Dokunulmazlar (bu operasyonda):** Flutter panel formu, yayın akışı, Supabase şema, `/v/[slug]/randevu*`, `/urun/*`, `/yazilar*` route sözleşmeleri (görsel uyum sonra).

---

## 1. Mevcut durum (araştırma özeti)

### Canlı yüzey
- Tek sayfa: `public_web/src/app/v/[slug]/page.tsx` (~750+ satır, monolit)
- Ürün grid: `ProductCatalog.tsx`
- Stil: koyu mavi dashboard + sağ sütun “Profil Araçları”
- Kategori bugün: etiket + JSON-LD `LocalBusiness` tipi; **layout kategoriye göre değişmiyor**
- Flutter’da zengin kategori sözlüğü: `lib/config/business_category_config.dart` (ctaLabel, sectionTitle, booking paketi, WA şablonu)

### Flutter kategori ID’leri (kaynak gerçek)
`giyim`, `butik`, `gida`, `firin`, `kozmetik`, `dekorasyon`, `elektronik`, `kirtasiye`, `kafe_lokanta`, `kuafor`, `teknik_servis`, `hizmet_danismanlik`, `egitim_ders`, `ev_temizlik`, `spor_fitness`, `pet_shop_veteriner`, `saglik_yasam`, `oto_arac`, `diger`

### Public’te zaten var olan özellikler (taşınacak, silinmeyecek)
Kimlik (kapak/logo/isim/kategori/açık-kapalı) · WhatsApp · Instagram · Yol · Web · Randevu · Koleksiyon · Ürün kataloğu · Hikâye · Galeri · QR/link · vCard · Google yorum · Pazaryeri · Yazılar · Referanslar

---

## 2. Tasarım ilkesi (tek iskelet, kategori varyantı)

**Yanlış:** Her kategori için ayrı sayfa / fork.  
**Doğru:** Tek **Profil Vitrin Shell** + kategori **profile config** (metin, CTA sırası, bölüm vurgusu).

```
Hero (kimlik)
  → Primary actions (max 3, kategoriye göre sıra/etiket)
  → Secondary icons (IG, web, Google, yazılar…)
Vitrin feed (ürün/hizmet kartları)
Atmosfer (hikâye + galeri) — veri yoksa gizle
Gel & bağlan (adres, QR, vCard, pazaryeri, daha fazla link)
```

### Kategori profilleri (3 UX ailesi — cerrahi gruplama)

| Aile | Örnek kategoriler | Primary CTA vurgusu | Feed başlığı hissi |
|------|-------------------|---------------------|--------------------|
| **A · Ürün vitrin** | giyim, butik, gida, firin, elektronik, kirtasiye, dekorasyon, pet, kozmetik*, oto | WA + Yol (+ Web) | “Seçtiklerimiz” / kategori `sectionTitle` |
| **B · Hizmet / randevu** | kuafor, spor_fitness, egitim_ders, saglik_yasam, teknik_servis, hizmet_danismanlik, ev_temizlik | WA + **Randevu** + Yol | “Hizmetler” / paketler |
| **C · Mekân** | kafe_lokanta | WA + Yol (+ menü/ürün) | “Menü / Bugün” |

\* kozmetik: ürün veya hizmet ağırlıklı olabilir → `supportsBooking` + ürün varlığına göre A/B karışık.

`diger` → A ailesi varsayılan.

Config kaynağı: Next’te yeni `public_web/src/lib/vitrinProfile.ts` — Flutter `BusinessCategoryConfig` ile **aynı id/label/cta** hizası (kopya sözlük, tek yön: Flutter zaten kaynak; Next mirror).

---

## 3. Cerrahi müdahale kuralları

1. **Tek PR / tek fazda tüm `page.tsx` yeniden yazma yok.**
2. Önce bileşen çıkarma (davranış aynı), sonra shell’i vitrin_2’ye çevir.
3. Her faz sonunda: 1 yayınlı slug smoke (desktop + mobil genişlik).
4. Veri yoksa bölüm render etme (boş kart ormanı yok).
5. “Profil Araçları” grid’i kaldırılır; işlevler icon/connect’e taşınır — özellik kaybı yok.
6. Flutter’a bu turda dokunulmaz (panel ayrı operasyon).
7. Mock HTML referans kalır; canlıda birebir pixel değil, **bilgi hiyerarşisi + spacing + CTA modeli**.

---

## 4. Fazlar

### Faz 0 — Hazırlık (risk sıfır)
- [x] `vitrinProfile.ts`: kategori → aile, `ctaLabel`, `sectionTitle`, primary action sırası
- [x] Label normalize: `store.kategori` → config id (Flutter `fromCategoryLabel` mantığının TS portu)
- [x] Görsel token’lar: Instrument Serif + vitrin_2 paleti (`globals.css`)
- [ ] Acceptance checklist dosyası (smoke maddeleri) — manuel

**Çıkış kriteri:** Config unit testi veya en azından 5 kategori map smoke.

### Faz 1 — Bileşenlere ayırma
- [x] `VitrinProfileView.tsx` (tek shell bileşeni; veri `page.tsx`’te kaldı)
- [x] `page.tsx` sadece data + JSON-LD + shell’e props

### Faz 2 — Shell = vitrin_2 hiyerarşisi (asıl UI)
- [x] Hero: full-bleed kapak, avatar, marka adı baskın, Açık pill, bio
- [x] Primary actions satırı (max 3) + secondary icon row
- [x] Ana kolon: koleksiyon chip + ürün feed (sağ dashboard yok)
- [x] Atmosfer bloğu
- [x] Connect bloğu: QR + vCard + Google + pazaryeri burada
- [x] Eski “Profil Araçları” kart grid’ini kaldır
- [x] `ProductCatalog` vitrin_2 grid stiline uydu

**Durum:** Yerelde `tsc --noEmit` OK. Canlı deploy + manuel smoke bekleniyor.

### Faz 3 — Kategori varyantları (cerrahi)
- [x] Aile A/B/C primary CTA sırası (`vitrinProfile.ts`)
- [x] Bölüm başlıkları `sectionTitle` ile
- [x] Randevu: sadece `booking enabled` iken primary’de
- [x] Ürün yok + hizmet var → feed’de boş state
- [x] Ürün kartı aspect: A/C 4/5 · B 1/1 (`--vitrin-card-ratio`)
- [x] HTML paket tamam: `vitrin_2_tamam.html` (A/B/C sekmeli)

**Çıkış kriteri:** Her aileden ≥1 canlı örnek — manuel test sonda.

### Faz 4 — Alt sayfa uyumu (ayrı küçük PR’lar)
- [x] `/urun/[productSlug]` vitrin_2 diline yaklaştırıldı
- [x] `/yazilar` + yazı detay ton uyumu
- [x] Randevu: sadece chrome/geri stili (wizard’a dokunulmadı)

### Faz 5 — Sertleştirme
- [ ] Deploy `vixrex-public` + manuel smoke (kullanıcı)
- [x] SEO: mevcut JSON-LD korundu (mantık değişmedi)
- [x] HTML paket: `vitrin_2_tamam.html`

---

## 5. Dosya dokunuş haritası (beklenen)

| Dosya | Faz | Not |
|-------|-----|-----|
| `public_web/src/lib/vitrinProfile.ts` | 0 | yeni |
| `public_web/src/app/globals.css` | 0–2 | token |
| `public_web/src/app/v/[slug]/page.tsx` | 1–3 | incelir, küçülür |
| `public_web/src/app/v/[slug]/components/*` | 1–2 | yeni |
| `public_web/src/app/v/[slug]/ProductCatalog.tsx` | 2–3 | chip/styling |
| `public_web/src/app/v/[slug]/urun/...` | 4 | sonra |
| Flutter / panel | — | bu operasyon dışı |

---

## 6. Riskler ve kaçınma

| Risk | Kaçınma |
|------|---------|
| Monolit rewrite regressiyon | Faz 1 extract-first |
| Kategori label eşleşmez | normalize + `diger` fallback |
| Özellik kaybı (vCard/QR) | Connect checklist |
| Booking kırılması | `/randevu` route’a dokunma; sadece link yeri |
| Panel / public drift | Config mirror dokümante; ileride tek kaynak |

---

## 7. Smoke checklist (her faz sonu)

1. Yayınlı ürünlü vitrin açılıyor  
2. WhatsApp / Yol / (varsa) Randevu tıklanıyor  
3. Ürün detay linki çalışıyor  
4. QR/link connect’te duruyor  
5. Mobil &lt; 420px tek kolon, hero okunuyor  
6. Boş galeri/hikâye bölümü gizleniyor  

---

## 8. Bilinçli yapılmayacaklar (şimdi)

- Flutter `PreviewScreen` / panel UI’ı bu turda yeniden tasarlamak  
- Kategori başına ayrı Next route  
- E-ticaret sepet/ödeme eklemek  
- Toplu dosya silme / public_web yıkımı  

---

## 9. İlk uygulama adımı (onay sonrası)

**Sadece Faz 0 + Faz 1** ile başla. UI henüz değişmez; zemin hazırlanır.  
Onay: “Faz 0–1’e geç” → kod.  
Faz 2 ayrı onay (görünür değişiklik).
