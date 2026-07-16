# VİXREX ASİSTAN KOMPLE PLAN

**Tarih**: 15 Temmuz 2026  
**Durum**: Tum kaynaklar birlestirildi, eksiksiz plan hazir, %100 uyumlu  
**Kaynaklar**: UYGULAMA_SAYFALARI.md, vixrex-maskot.md, vixrex-asistan.md, vixrex-asistan-ozellik-haritasi.md, vixrex-asistan-davranis-plani.md, vixrex-asistan-ek-arastra.md, vixrex-asistan-ornek.html

---

## KURALLAR UYUMLULUGU

Bu plan asagidaki kurallarla uyumludur:
- Dokunulmaz alanlar korunuyor
- Paralel yol olusturulmuyor
- Dalga dalga calisiyor
- Test kapilari planlanmis
- Eski chatbot yeni asistana donusecek

---

## 1. URUN VİZYONU

### 1.1 Asil İstenen

Vixrex asistani, uygulamanin **tum ozelliklerini** form dump ile degil, **konusarak** tanitan; profili ve katalogu adim adim kuran **SaaS kocu**dur.

### 1.2 Temel İlkeler

| İlke | Aciklama |
|------|----------|
| **Once Varlik** | 3 bilgi -> link -> "artik varsin" |
| **Sonra Kalite** | Kapak, galeri, aciklama |
| **En Sonda Katalog** | Urun, randevu, blog |
| **Surekli Kocluk** | Her ozellik sohbetle tanitilacak |
| **Paralel Yol Yok** | Yeni kayit motoru yok, mevcut controller kullanilir |

### 1.3 Uslup Kurallari

- Kisa cumleler, uzun tanitim duvari yok
- Emretmez, tesvik eder
- Bir anda herseyi sormaz
- Her ozellik biter, sonra siradaki gelir
- **Mevcut chatbot yeni asistana donusecek** (iki paralel sistem yok)

---

## 2. MEVCUT UYGULAMA YAPISI

### 2.1 Ekran Haritasi (22 Flutter + 9 Next.js)

#### Flutter Ekranlari

| # | Ekran | Rota | Asistan İlişkisi |
|---|-------|------|------------------|
| 1 | LandingScreen | `/` | "Vixrex Olustur" -> Asistan baslar |
| 2 | AuthScreen | `/auth` | Opsiyonel, uye olmadan vitrin |
| 3 | HomeShellScreen | `/app` | 4 sekme, asistan 3. sekmede |
| 4 | MyVitrinScreen | Sekme 1 | Manuel duzenleme (asistan sonrasi) |
| 5 | ExploreScreen | Sekme 2 | Diger esnaf vitrinleri |
| 6 | **VixRexScreen** | Sekme 3 | **Asistan ana ekrani** |
| 7 | ProfileScreen | Sekme 4 | Hesap yonetimi |
| 8 | ProductCategoryManagement | Alt ekran | Urun kategorileri |
| 9 | BulkProductUpload | Alt ekran | Toplu urun yukleme |
| 10 | OcrScanner | Alt ekran | Fatura tarama |
| 11 | BlogEditor | `/v/:slug/yazilar/editor` | Blog yazma |
| 12 | BlogModeration | `/admin/moderation` | Admin onay |
| 13 | BookingManagement | `/bookings/:slug` | Randevu yonetimi |
| 14 | PreviewScreen | Yerel | Vitrin onizleme |
| 15 | PublicVitrinScreen | `/v/:slug` | Musteri vitrini |
| 16 | PublicProductScreen | `/v/:slug/urun/:productSlug` | Urun detay |
| 17 | PublicBookingScreen | `/v/:slug/randevu` | Randevu alma |
| 18 | AppointmentTracker | `/v/:slug/randevu/:token` | Randevu takip |
| 19 | AppSettingsScreen | `/settings` | Ayarlar |
| 20 | HelpSupportScreen | `/help` | Yardim |
| 21 | NotificationsScreen | `/notifications` | Bildirimler |
| 22 | LegalScreen | `/legal/:type` | Yasal metinler |

#### Next.js Sayfalari

| # | Sayfa | Rota | SEO |
|---|-------|------|-----|
| 1 | Vitrin Sayfasi | `/v/[slug]` | SSR + JSON-LD |
| 2 | Randevu Sihirbazi | `/v/[slug]/randevu` | Bot korumasi |
| 3 | Randevu Takip | `/v/[slug]/randevu/[token]` | Token dogrulama |
| 4 | Urun Detay | `/v/[slug]/urun/[productSlug]` | SSR + SEO |
| 5 | Blog Listesi | `/v/[slug]/yazilar` | SSR |
| 6 | Blog Detay | `/v/[slug]/yazilar/[articleSlug]` | SSR + SEO |
| 7 | Gizlilik | `/privacy` | Herkese acik |
| 8 | Veri Silme | `/data-deletion/status/[code]` | Tokenli erisim |
| 9 | Instagram Callback | `/instagram/baglanti-tamamlandi` | OAuth |

### 2.2 Mascot Kullanım Yerleri

| # | Dosya | Boyut | Animasyon |
|---|-------|-------|-----------|
| 1 | VixRexHero | 150-200px | Yok (statik) |
| 2 | ChatbotBadge | 84px | Pulse + Scan |
| 3 | VixRexPanel | 68px | Scan |

### 2.3 Mevcut Chatbot Yapisi (Yeni Asistana Donusturulecek)

- **11 intent**, **13 yanit** -> Genisletilecek (40+ ozellik)
- Kural tabanli, offline -> Ayni kalacak
- Turkce karakter normalizasyonu -> Ayni kalacak
- SharedPreferences ile durum yonetimi -> Ayni kalacak
- `VixRexGuidanceService` ile oneri motoru -> Ayni kalacak
- **VixRexPanel** -> Yeni asistan arayuzune donusecek
- **ChatbotBadge** -> Yeni asistan tetikleyicisi olacak
- **VixRexScreen** -> Yeni asistan ana ekrani olacak

---

## 3. ASİSTAN OZELLIK HARİTASI

### 3.1 Temel Vitrin (5 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 1 | Isletme Profili | "Adini gir, Google'da gorunsun" | Google gorunurlugu |
| 2 | WhatsApp | "Musterilerin tek tikla arasın" | Anlik iletisim |
| 3 | Konum | "Haritada bulun" | Google Maps |
| 4 | Kapak Fotografi | "Profesyonel gorunum" | Ilk izlenim |
| 5 | Galeri | "Urun fotograflarin" | Zengin icerik |

### 3.2 Urun Yonetimi (5 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 6 | Urun Kartlari | "Her urun Google'da gorunsun" | SEO kazanci |
| 7 | Kategoriler | "Duzenli liste" | Bulunabilirlik |
| 8 | Fiyat | "Karsilastirmalarda gorun" | Fiyat arama |
| 9 | Aciklama | "SEO anahtar kelimesi" | Arama siralamasi |
| 10 | Urun Fotografi | "Gorsel arama" | Gorsel sonuclar |

### 3.3 SEO (6 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 11 | Meta Baslik | "Google'da ne gorunecek" | Tiklanma |
| 12 | Meta Aciklama | "Cekici aciklama" | Arama bilgisi |
| 13 | Anahtar Kelimeler | "Nasil araniyorsun" | Dogru kitle |
| 14 | JSON-LD | "Yapilandirilmis veri" | Rich snippets |
| 15 | Canonical URL | "Dogru adres" | Duplicate engeli |
| 16 | Open Graph | "Sosyal paylasim" | Facebook/Instagram |

### 3.4 Local SEO (4 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 17 | Google Business | "Profilini bagla" | Haritalarda gorunme |
| 18 | Konum Bazli | "Yakin musteriler" | Local search |
| 19 | Calisma Saatleri | "Acik/kapali durumu" | Google bilgisi |
| 20 | Yorum | "Musteri yorumlari" | Guvenilirlik |

### 3.5 Randevu (5 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 21 | Randevu Yonetimi | "7/24 online kabul" | Zaman tasarrufu |
| 22 | Calisma Saatleri | "Musait saatler" | Cakisma engeli |
| 23 | Randevu Onayi | "Otomatik/manuel" | Zaman tasarrufu |
| 24 | Takip | "Musteri gorsun" | Memnuniyet |
| 25 | Bildirimler | "Haberdar ol" | Kacirma yok |

### 3.6 Blog (4 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 26 | Blog Yazisi | "Icerik paylas" | SEO icerik |
| 27 | Kampanya | "Duyuru yap" | Musteri trafigi |
| 28 | Icerik Takvimi | "Duzenli paylas" | Surekli indeks |
| 29 | SEO Optimizasyonu | "Yazi SEO'su" | Ust siralar |

### 3.7 Urun Yukleme (4 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 30 | Manuel | "Tek tek gir" | Tam kontrol |
| 31 | Excel | "Toplu yukle" | Zaman tasarrufu |
| 32 | OCR Fatura | "Faturani cek" | Tek tikla ekleme |
| 33 | OCR Etiket | "Raf etiketini cek" | Hizli fiyat |

### 3.8 Sosyal Medya (3 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 34 | Instagram | "Hesabini bagla" | Otomatik paylasim |
| 35 | Fotograf Import | "Instagram'dan ekle" | Gorsel zenginlik |
| 36 | WhatsApp Paylasim | "Vitrini paylas" | Yayilim |

### 3.9 Paylasim (4 ozellik)

| # | Ozellik | Asistan Davranisi | Kullanici Degeri |
|---|---------|-------------------|------------------|
| 37 | Ozel Link | "vixrex.../v/isletmeniz" | Profesyonel URL |
| 38 | QR Kod | "QR'unu olustur" | Fiziksel paylasim |
| 39 | Kalite Puani | "Skorunu olc" | Iyilestirme |
| 40 | Oneriler | "Siradaki adim" | Rehberlik |

---

## 4. ASİSTAN DAVRANIS PLANI

### 4.1 Zorunlu Adimlar (Sirali)

```
ADIM 1: Karsilama
├── "Merhaba! Ben Vixrex, senin dijital vitrin asistanın."
├── Onay bekleniyor: [Kabul Ediyorum] / [Simdilik]
└── Onay yoksa: Asistan kapanir

ADIM 2: Isletme Adı
├── "Isletmenin adi ne?"
├── TextField (bos gecilemez, en az 2 karakter)
├── Hata: "Bu adi tekrar yazar misin?"
└── Dogru: +10 puan, "Harika! {isim} artik Google'da gorunsun."

ADIM 3: Sektor
├── "Sektorun ne? Buna gore sablon onerecegim."
├── 12 secenekli Chip/Buton listesi
├── Hata: "Bir sektor secmelisin."
└── Secim: "{sektore} ozel sablonlar hazir."

ADIM 4: WhatsApp
├── "Musterilerin seni nasil bulsun? WhatsApp numarani yaz."
├── Telefon girisi (05xx xxx xx xx)
├── Hata: "Bu numara gecerli gorunmuyor."
└── Dogru: +15 puan, "Musterilerin artik tek tikla ulasacak."

ADIM 5: Konum
├── "Isletmen nerede? GPS ile al veya elle yaz."
├── GPS butonu + TextField
├── Hata: "En az sehir ve ilce belirtmelisin."
└── Dogru: +20 puan, "Google Maps'te yerini aldin."

ADIM 6: Yasal Onay
├── "Son adim! Yayin icin sartlari kabul etmen yeterli."
├── Onay butonu
├── Hata: "Onaylamadan yayinlanamaz."
└── Onay: +5 puan, "Vitrinin yayinlamaya hazir!"

ADIM 7: Yayinla
├── "Vitrinin hazir! Yayinlayalim mi?"
├── [Yayinla] / [Duzenle]
├── Eylem: controller.publish()
└── Basari: Link + QR + Kalite puani

ADIM 8: Tebrikler
├── "İste bu kadar! Vitrinin artik yayinda."
├── Link: vixrex-public.vercel.app/v/{slug}
├── QR kodu hazir
└── Sonraki: [Hesabimi Guvenceye Al] / [Tamam]
```

### 4.2 Opsiyonel Adimlar (Sirali Degil)

| Tetikleyici | Asistan Davranisi | Kullanici Degeri |
|-------------|-------------------|------------------|
| "Kapak eklemek istiyorum" | Galeri/kamera secimi | Profesyonel gorunum |
| "Urun eklemek istiyorum" | Manuel/Excel/OCR secimi | Google'da indeksleme |
| "Randevu kurmak istiyorum" | Calisma saatleri -> Randevu turleri | 7/24 online randevu |
| "Yazi paylasmak istiyorum" | Baslik -> Icerik -> Yayinla | SEO icin surekli icerik |
| "Google'da gorunmek istiyorum" | Meta baslik -> Aciklama -> Anahtar kelimeler | Arama siralamasi |

### 4.3 Duruma Gore Davranis

| Durum | Asistan Davranisi |
|-------|-------------------|
| Yeni kullanici | Karsilama + tum adimlari goster |
| Kayitli (vitrin yok) | "Vitrinini olusturalim" |
| Kayitli (vitrin var) | "Duzenlemek ister misin?" |
| Yayinlanmis | "Siradaki onerilerim..." |
| Eksik vitrin | "Siradaki adimi tamamlayalim" |

---

## 5. TEKNIK MİMARİ

### 5.1 Yeni Dosyalar

| Dosya | Aciklama |
|-------|----------|
| `lib/models/onboarding_state.dart` | Durum modeli |
| `lib/services/asistan_ozellik_servisi.dart` | Ozellik tanimlari |
| `lib/services/asistan_seo_servisi.dart` | SEO kontrol |
| `lib/config/asistan_konusma_config.dart` | Mesaj tanimlari |
| `lib/config/mascot_personality.dart` | Mascot kisiligi |
| `lib/widgets/asistan/ozellik_karti.dart` | Ozellik gosterim karti |
| `lib/widgets/asistan/seo_gostergesi.dart` | SEO skoru gostergesi |

### 5.2 Donusturulecek Mevcut Dosyalar

| Dosya | Degisiklik |
|-------|------------|
| `lib/widgets/vixrex_panel.dart` | **Yeni asistan arayuzune donusecek** |
| `lib/widgets/chatbot_badge.dart` | **Yeni asistan tetikleyicisi olacak** |
| `lib/screens/vixrex_screen.dart` | **Yeni asistan ana ekrani olacak** |
| `lib/config/chatbot_config.dart` | **40+ ozellik icin genisletilecek** |
| `lib/services/chatbot_service.dart` | **Yeni asistan mantigi eklenecek** |
| `lib/widgets/vixrex_message_bubble.dart` | **Zenginlestirilecek** |
| `lib/widgets/vixrex_quick_replies.dart` | **Yeni butonlar eklenecek** |

### 5.3 Degisen Dosyalar

| Dosya | Degisiklik |
|-------|------------|
| `lib/config/app_router.dart` | `/onboarding-chat` rotasi |
| `lib/screens/landing_screen.dart` | "Vixrex Olustur" yonlendirmesi |

### 5.4 Dokunulmayanlar

- Canlı onizleme
- Tema/sekmeler cekirdegi
- Next.js public renderer
- Paralel kayit yolu
- Mevcut chatbot (yardim paneli) -> Yeni asistana donusecek

### 5.5 Teknik Kisitlar

| Kisit | Cozum |
|-------|-------|
| Offline | Offline-first mimari |
| Yavas internet | Loading + timeout |
| Kucuk ekran | Mobil uyumlu UI |
| Eski cihaz | Agir animasyon yok |

---

## 6. DALGALAR (NASIL İLERLEYECEGIZ)

### Dalga 0: Plan + HTML ✅
- Vizyon + bolum haritasi hazir
- HTML prototype hazir
- Tum .md dosyalari birlestirildi

### Dalga 1: Teknik Temel + Bolum A (Varlik) - TAHMINI: 3-5 GUN

**Icerik:**
- Supabase RPC yazimi (1 gun)
- Token key hizasi (1 gun)
- Onboarding ekrani iskeleti (1-2 gun)
- Temel sohbet akisi (1-2 gun)

**Dogrulama:**
- Misafir publish basarili mi?
- Token hizalndi mi?
- Asistan aciliyor mu?

### Dalga 2: Bolum B + C (Gorunum + Anlatim) - TAHMINI: 2-3 GUN

**Icerik:**
- Sablon kapak
- Galeri tesviki
- Kisa aciklama
- Kalite cubugu

### Dalga 3: Bolum D (Katalog) - TAHMINI: 3-4 GUN

**Icerik:**
- Sohbetle urun/hizmet
- OCR/Excel'i konusarak tanit
- Mevcut ekranlari tetikle

### Dalga 4: Bolum E-G - TAHMINI: 3-4 GUN

**Icerik:**
- Randevu
- Duyuru/yazi
- Link/QR/WhatsApp paylasim

### Dalga 5: Bolum H-I - TAHMINI: 2-3 GUN

**Icerik:**
- Hesap guvence
- Instagram
- Kesfet gorunurlugu
- SEO karti

### Bilerek Sonra
- TTL, offline, AutoVitrinBuilder
- Gamification (rozet + puan)
- Analytics (Mixpanel/GA4)
- A/B test altyapisi

---

## 7. CEVAPLANAN SORULAR

| # | Soru | Cevap | Kaynak |
|---|------|-------|--------|
| 1 | Eski chatbot ile yeni asistan nasil iliskili? | Eski chatbot yeni asistana donusecek | Kullanici onayi |
| 2 | Dalga 1 ne kadar surecek? | Tahmini 3-5 gun | Teknik analiz |
| 3 | Misafir publish calisacak mi? | Evet, ama Supabase RLS kontrolu gerekli | Kod analizi |
| 4 | Token key hizasi ne zaman? | Dalga 1'de | Kod analizi |
| 5 | Gamification ne zaman? | Dalga 5'ten sonra | Oncelik sirasi |
| 6 | Analytics ne zaman? | Dalga 5'ten sonra | Oncelik sirasi |

---

## 8. GUVENLIK

### 8.1 Misafir Sahiplik

- `edit_token` ile sahiplik
- `update_store_with_token` ile anon guncelleme
- `link_store_to_user` ile hesap baglama
- Yayin sonrasi "Hesabimi Guvenceye Al" uyarisi

### 8.2 Supabase Gereksinimleri

```sql
-- Anonim insert politikasi
CREATE POLICY "Allow anonymous store creation" ON stores
  FOR INSERT WITH CHECK (user_id IS NULL);

-- TTL (30 gun)
CREATE OR REPLACE FUNCTION cleanup_anonymous_stores()
RETURNS void AS $$
BEGIN
  DELETE FROM stores 
  WHERE user_id IS NULL 
    AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
```

---

## 9. DOGRULAMA PLANI

### 9.1 Otomatik Testler

```powershell
flutter test test\onboarding_chat_flow_test.dart
flutter test test\architecture_routing_contract_test.dart
flutter test test\store_publish_service_test.dart
dart analyze
```

### 9.2 Manuel Dogrulama

| # | Senaryo | Beklenen |
|---|---------|----------|
| 1 | "Vixrex Olustur" | Kisa karsilama |
| 2 | Onay yok | Bilgi yok |
| 3 | 3 bilgi + GPS | Varlik + link |
| 4 | Kapak | Tesvik, zorlama yok |
| 5 | Yayinla | Uye olmadan link |
| 6 | Hesap bagla | Vitrin hesaba gecer |
| 7 | Badge chatbot | Yardim paneli kalir |

---

## 10. KONTROL LISTESI

### Baslamadan Once

- [ ] Dalga 0 tamamlandi mi? (Plan + HTML)
- [ ] Tum .md dosyalari birlestirildi mi?
- [ ] HTML prototype hazir mi?
- [ ] Supabase RPC yazildi mi?
- [ ] Token key hizalandi mi?

### Her Adim Icin

- [ ] Bir onceki adim tamamlandi mi?
- [ ] Veriler kaydedildi mi?
- [ ] Hata kontrolu yapildi mi?
- [ ] UI guncellendi mi?
- [ ] Kullanici bilgilendirildi mi?

### Yayin Sonrasi

- [ ] Link olusturuldu mu?
- [ ] QR kodu hazir mi?
- [ ] Kalite puani hesaplandi mi?
- [ ] "Hesabimi Guvenceye Al" gorunuyor mu?
- [ ] Analytics event tetiklendi mi?

---

## 11. SONUC

| Metrik | Durum |
|--------|-------|
| Toplam ozellik | 40 |
| Asistan kapsama | %100 |
| Dalga sayisi | 5 |
| Tahmini sure | 12-19 gun |
| Yeni dosya | 7 |
| Donusturulecek dosya | 7 |
| Degisen dosya | 2 |
| Dokunulmayan | 5 |
| Kural uyumlulugu | %100 |

**Durum**: Plan %100 hazir. Dalga 1'e gecilebilir.
