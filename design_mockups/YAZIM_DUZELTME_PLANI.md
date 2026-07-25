# Vitrin metin / yazım düzeltme planı

**Kapsam:** Müşteriye görünen metinler (public Next + HTML mock). Panel Flutter’a bu turda dokunulmaz.  
**Amaç:** Yazım hatalarını düzeltmek + her kategoride tonu işletmeye yakışır hale getirmek.  
**Kaynak:** `vitrinProfile.ts` (zaten kategori bazlı `sectionTitle` / `ctaLabel` var) + yeni `vitrinCopy.ts` (bağlantı / atmosfer / boş durum / bio).

---

## 0. Dürüst durum (önceki plan eksikti)

Önceki taslak **çoğunlukla global** düzeltmeydi:
- `Gel & bağlan` → herkese aynı “Bize ulaşın”
- Atmosfer için sadece “aileye göre veya nötr” notu
- `defaultBio` hâlâ ürün dilinde tek şablon

**Yani: her kategoriye özel kaliteli düzenleme henüz planda tamamlanmamıştı.**  
Bu sürüm onu tamamlar: **kategori matrisi zorunlu**.

---

## 1. Katman modeli

| Katman | Ne | Örnek |
|--------|-----|--------|
| **Global** | Her vitrinde aynı, kategori bağımsız | adres normalize, footer, “Rehbere ekle”, paylaşma kutusu |
| **Aile** (`product` / `service` / `venue`) | Ortak iskelet tonu | ürün→katalog dili, hizmet→randevu dili, mekân→ziyaret/menü dili |
| **Kategori** (19 profil) | Başlık, CTA, boş durum, bio fallback, atmosfer | kuaför ≠ fırın ≠ kafe |

Zaten kategoriye özel olanlar (`vitrinProfile`): `sectionTitle`, `ctaLabel`, `primaryActions`.  
**Eksik olanlar** (bu planın asıl işi): connect başlığı, atmosfer/hikâye, boş feed, default bio, WhatsApp buton birleşik metni.

---

## 2. Global düzeltmeler (tüm kategoriler)

| Şu an | Sorun | Hedef |
|--------|--------|--------|
| `Gel & bağlan` | Slang, kategori dışı | Aşağıdaki kategori `connectTitle` |
| `PAYLAŞ` | Bağırıyor | `Vitrini paylaş` |
| `… Mahallesi Mah.` | Veri tekrarı | `normalizeAddressDisplay()` |
| QR’da production URL (localhost) | Env / `getSiteUrl` | Yerel origin |
| `Bu vitrin Vixrex ile oluşturuldu.` | OK | kalır |
| `Yol tarifi al` / `Rehbere ekle` | OK | kalır (global) |

---

## 3. Kategori matrisi (zorunlu sözlük)

`vitrinCopyByCategory[id]` — her satır uygulanacak.  
CTA’da WhatsApp birleşimi: birincil butonda **`WhatsApp · {ctaLabel}`** yerine kısa **`{ctaLabel}`** veya kategoriye göre `whatsappButton` (aşağıda).

### 3.1 Product ailesi

| id | connectTitle | atmosphereTitle | storyTitle | emptyFeed | defaultBio (kısa) | whatsappButton |
|----|--------------|-----------------|------------|-----------|-------------------|----------------|
| `giyim` | Bize ulaşın | Mağazanın hali | Hikâyemiz | Henüz ürün eklenmedi. | {ad} — yeni sezon ve koleksiyon. | Ürün sor |
| `butik` | Bize ulaşın | Atölye / mağaza | Hikâyemiz | Henüz ürün eklenmedi. | {ad} — özel tasarımlar. | Ürün sor |
| `gida` | Sipariş & konum | Tezgâh | Hikâyemiz | Henüz ürün eklenmedi. | {ad} — taze ürünler, sipariş ve konum. | Sipariş sor |
| `firin` | Sipariş & konum | Fırından | Hikâyemiz | Bugün için ürün yok. | {ad} — günlük taze ürünler. | Sipariş sor |
| `kozmetik` | Bilgi & randevu | Mağaza | Hikâyemiz | Henüz ürün eklenmedi. | {ad} — ürünler ve bakım. | Bilgi al |
| `dekorasyon` | Teklif & konum | Showroom | Hikâyemiz | Henüz ürün eklenmedi. | {ad} — koleksiyon ve teklif. | Teklif iste |
| `elektronik` | Ürün sor & konum | Mağaza | Hakkımızda | Henüz ürün eklenmedi. | {ad} — ürünler ve destek. | Ürün sor |
| `kirtasiye` | Bize ulaşın | Mağaza | Hakkımızda | Henüz ürün eklenmedi. | {ad} — ürünler ve konum. | Ürün sor |
| `diger` | Bize ulaşın | Vitrin | Hakkımızda | Henüz içerik eklenmedi. | {ad} — iletişim ve konum. | Bilgi al |

### 3.2 Service ailesi

| id | connectTitle | atmosphereTitle | storyTitle | emptyFeed | defaultBio | whatsappButton |
|----|--------------|-----------------|------------|-----------|------------|----------------|
| `kuafor` | Randevu & iletişim | Salon | Hakkımızda | Henüz hizmet kartı yok. WhatsApp veya randevu ile devam edin. | {ad} — randevu ve iletişim. | Randevu sor |
| `pet_shop_veteriner` | Randevu & iletişim | Klinik / dükkan | Hakkımızda | Henüz hizmet kartı yok. | {ad} — randevu ve bilgi. | Bilgi al |
| `teknik_servis` | Servis talebi | Atölye | Hakkımızda | Henüz hizmet kartı yok. | {ad} — servis ve randevu. | Servis talebi |
| `hizmet_danismanlik` | İletişim | Çalışma alanı | Hakkımızda | Henüz hizmet kartı yok. | {ad} — danışmanlık ve randevu. | Bilgi al |
| `egitim_ders` | Kayıt & iletişim | Ortam | Program hakkında | Henüz program eklenmedi. | {ad} — programlar ve kayıt. | Bilgi al |
| `ev_temizlik` | Teklif & iletişim | — (galeri varsa) | Hakkımızda | Henüz hizmet kartı yok. | {ad} — teklif ve randevu. | Teklif iste |
| `spor_fitness` | Üyelik & randevu | Salon | Hakkımızda | Henüz program eklenmedi. | {ad} — programlar ve randevu. | Bilgi al |
| `saglik_yasam` | Randevu & iletişim | Klinik | Hakkımızda | Henüz hizmet kartı yok. | {ad} — randevu ve iletişim. | Bilgi al |
| `oto_arac` | Randevu & iletişim | Servis | Hakkımızda | Henüz hizmet kartı yok. | {ad} — randevu ve servis. | Randevu sor |

### 3.3 Venue ailesi

| id | connectTitle | atmosphereTitle | storyTitle | emptyFeed | defaultBio | whatsappButton |
|----|--------------|-----------------|------------|-----------|------------|----------------|
| `kafe_lokanta` | Rezervasyon & konum | Mekân | Hikâyemiz | Menü henüz eklenmedi. WhatsApp ile sorabilirsiniz. | {ad} — menü, rezervasyon ve konum. | Sipariş / rezervasyon |

---

## 4. Kod yapısı (uygulama)

```ts
// vitrinCopy.ts — kategoriye özel
type CategoryCopy = {
  connectTitle: string;
  atmosphereTitle: string;
  storyTitle: string;
  emptyFeed: string;
  defaultBio: (name: string) => string;
  whatsappButton: string; // birincil WA metni; ctaLabel ile hizalı
};

export function getVitrinCopy(categoryId: string): CategoryCopy;
```

`VitrinProfileView` / `page.tsx`:
- Hardcoded `Gel & bağlan`, `Dükkanın hali`, `Dükkan hikâyesi` **kaldırılır**
- `getVitrinCopy(profile.id)` kullanılır
- `sectionTitle` / `ctaLabel` mevcut `vitrinProfile`’da kalır (zaten kategoriye özel); tutarsızlık varsa aynı PR’da hizalanır

Mevcut profil alanları gözden geçirme (kalite):
- [ ] `kozmetik` `Ürünler & Bakım` → `Ürünler ve bakım` (`&` azalt)
- [ ] `kafe` CTA uzun → UI’da taşma kontrolü
- [ ] `diger` `Vitrin` → `Öne çıkanlar` (daha az iç jargon)

---

## 5. Fazlar

### Faz A — Matris + sözlük dosyası
- [x] `vitrinCopy.ts` (yukarıdaki 19 satır)
- [x] `getVitrinCopy` + `diger` fallback

### Faz B — Shell bağlama
- [x] Connect / atmosfer / hikâye / empty / WA buton metni
- [x] Mock HTML A/B/C sekmeleri aynı metinlerle

### Faz C — Bio + adres + URL
- [x] `defaultBio` kategoriye göre
- [x] `normalizeAddressDisplay`
- [x] Yerel `getSiteUrl`

### Faz D — Kategori smoke (manuel)
Her aileden en az bir slug:
1. product: giyim veya gıda  
2. service: kuaför  
3. venue: kafe  

Kontrol: connect + atmosphere + empty + CTA dili kategoriye uyuyor mu.

---

## 6. Bilinçli dokunulmayanlar

- Kullanıcının yazdığı işletme / ürün / açıklama metni  
- Flutter WhatsApp şablon gövdeleri (ayrı iş)  
- Schema.org İngilizce alan adları  

---

## 7. Onay (tek soru)

Matrisdeki başlıklar (özellikle `connectTitle` satırları) uygun mu?
- **Evet** → uygulamaya geç  
- **Hayır** → hangi kategoriyi nasıl değiştirmek istediğini yaz  
