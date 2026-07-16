# VİXREX ASİSTAN DAVRANIŞ PLANI

**Tarih**: 15 Temmuz 2026  
**Hedef**: Asistanın nasıl bağlanacağı, nasıl konuşacağı, sıralaması ve dikkat noktaları  

---

## 1. ASİSTAN DAVRANIŞ MİMARİSİ

### 1.1 Temel İlkeler

| İlke | Açıklama | Örnek |
|------|----------|-------|
| **Sıralı İlerleme** | Adımları atlamadan, birini bitirmeden diğerine geçme | WhatsApp → Konum → Yayınla |
| **Dürüstlük** | Yapamayacağı şeyi vadetme | "Premium gerektirir" demek |
| **Kısa ve Öz** | Uzun açıklamalar değil, 1-2 cümle | "Harika! Sıradaki adım..." |
| **Aksiyon Odaklı** | Her mesajda bir sonraki adım olsun | "Şimdi şunu yapalım" |
| **Değer Odaklı** | Neden yapması gerektiğini açıkla | "Google'da görünsün diye" |

### 1.2 Bağlantı Noktaları

```
Asistan Bağlantı Haritası:

1. LandingScreen
   └── "Vixrex Oluştur" butonu → Asistan başlar

2. Onboarding Ekranı
   └── Karşılama → Bilgi toplama → Yayınla

3. MyVitrinScreen
   └── Asistan butonu → Yardım/Öneri

4. VixRexScreen
   └── Asistan kartları → Öneri/Aksiyon

5. PublicVitrinScreen
   └── "Düzenle" → Asistana yönlendirme
```

---

## 2. KONUŞMA AKIŞ SIRASI

### 2.1 Zorunlu Adımlar (Sıralı)

```
ADIM 1: Karşılama
├── Mesaj: "Merhaba! Ben Vixrex, senin dijital vitrin asistanın."
├── Eylem: Hoş geldin
└── Geçiş: [Kabul Ediyorum] tıklanınca

ADIM 2: İşletme Adı
├── Mesaj: "İşletmenin adı ne?"
├── Girdi: TextField (boş geçilemez)
├── Doğrulama: En az 2 karakter
├── Hata: "Bu adı tekrar yazar mısın? En az 2 karakter olsun."
└── Geçiş: Doğru girilince

ADIM 3: Sektör/Kategori
├── Mesaj: "Sektörün ne? Buna göre şablon önereceğim."
├── Girdi: Chip/Buton listesi
├── Seçenekler: Giyim, Kafe, Kuaför, Eczane, ... (12 seçenek)
├── Hata: "Bir sektör seçmelisin."
└── Geçiş: Seçim yapılınca

ADIM 4: WhatsApp
├── Mesaj: "Müşterilerin seni nasıl bulsun? WhatsApp numaranı yaz."
├── Girdi: Telefon girişi
├── Doğrulama: Türkiye formatı (05xx xxx xx xx)
├── Hata: "Bu numara geçerli görünmüyor. 05 ile başlayan bir numara gir."
└── Geçiş: Doğru girilince

ADIM 5: Konum
├── Mesaj: "İşletmen nerede? GPS ile al veya elle yaz."
├── Girdi: GPS butonu + TextField
├── Doğrulama: Boş geçilemez
├── Hata: "En az şehir ve ilçe belirtmelisin."
└── Geçiş: Girilince

ADIM 6: Yasal Onay
├── Mesaj: "Son adım! Yayın için şartları kabul etmen yeterli."
├── Girdi: Onay butonu
├── Doğrulama: Onaylanmalı
└── Geçiş: Onaylayınca

ADIM 7: Yayınla
├── Mesaj: "Vitrinin hazır! Yayınlayalım mı?"
├── Girdi: [Yayınla] / [Düzenle]
├── Eylem: controller.publish()
└── Geçiş: Yayınlanınca

ADIM 8: Tebrikler
├── Mesaj: "İşte bu kadar! Vitrinin artık yayında."
├── Gösterim: Link + QR + Kalite puanı
└── Sonraki: [Hesabımı Güvenceye Al] veya [Tamam]
```

### 2.2 Opsiyonel Adımlar (Sıralı Değil)

```
OPSİYONEL 1: Kapak Fotoğrafı
├── Tetikleyici: "Kapak eklemek istiyorum"
├── Eylem: Galeri/kamera seçimi
└── Sonuç: Kalite puanı +15

OPSİYONEL 2: Ürün Ekleme
├── Tetikleyici: "Ürün eklemek istiyorum"
├── Seçenekler: Manuel / Excel / OCR
└── Sonuç: Google'da indeksleme

OPSİYONEL 3: Randevu Sistemi
├── Tetikleyici: "Randevu kurmak istiyorum"
├── Adımlar: Çalışma saatleri → Randevu türleri
└── Sonuç: 7/24 online randevu

OPSİYONEL 4: Blog Yazısı
├── Tetikleyici: "Yazı paylaşmak istiyorum"
├── Adımlar: Başlık → İçerik → Yayınla
└── Sonuç: SEO için sürekli içerik

OPSİYONEL 5: SEO Ayarları
├── Tetikleyici: "Google'da görünmek istiyorum"
├── Adımlar: Meta başlık → Açıklama → Anahtar kelimeler
└── Sonuç: Arama sıralaması artışı
```

---

## 3. DURUMA GÖRE DAVRANIŞ

### 3.1 Kullanıcı Durumu

| Durum | Asistan Davranışı |
|-------|-------------------|
| **Yeni kullanıcı (ilk kez)** | Karşılama + tüm adımları göster |
| **Kayıtlı kullanıcı (vitrin yok)** | "Vitrinini oluşturalım" |
| **Kayıtlı kullanıcı (vitrin var)** | "Vitrinini düzenlemek ister misin?" |
| **Yayınlanmış vitrin** | "Sıradaki önerilerim..." |
| **Eksik vitrin** | "Sıradaki adımı tamamlayalım" |

### 3.2 Hata Durumları

| Hata | Asistan Tepkisi |
|------|-----------------|
| **Boş alan** | "Bu alan zorunlu. Lütfen doldur." |
| **Geçersiz format** | "Bu format geçerli değil. Şu şekilde gir: ..." |
| **İnternet yok** | "Bağlantın yok gibi görünüyor. Çevrimdışı devam edebilirsin." |
| **Sunucu hatası** | "Bir sorun oluştu. Tekrar dener misin?" |
| **Zaten kayıtlı** | "Bu bilgi zaten girilmiş. Güncellemek ister misin?" |

### 3.3 Kullanıcı Bırakırsa

| Durum | Asistan Davranışı |
|-------|-------------------|
| **1. adımda bıraktı** | Hiçbir şey kaydetme |
| **2. adımda bıraktı** | İşletme adını kaydet |
| **3. adımda bıraktı** | Ad + sektör kaydet |
| **4. adımda bıraktı** | Ad + sektör + WhatsApp kaydet |
| **5. adımda bıraktı** | Tümünü kaydet, hatırlat |
| **Yayınladı ama düzenlemedi** | 24 saat sonra hatırlat |

---

## 4. NELERE DİKKAT ETMELİYİZ

### 4.1 Kullanıcı Deneyimi

| # | Dikkat Noktası | Açıklama |
|---|----------------|----------|
| 1 | **Yorma** | Tek seferde 1 bilgi iste, 3-4 değil |
| 2 | **Bekletme** | Her girdi sonrası anında yanıt ver |
| 3 | **Kaybetme** | Yarıda kalırsa devam ettir |
| 4 | **Anlama** | Anlayamadıysan tekrar sor |
| 5 | **Teşvik** | Her adımda "Harika!" "Güzel!" de |

### 4.2 Teknik Kısıtlar

| # | Kısıt | Çözüm |
|---|-------|-------|
| 1 | **Offline** | Yerel depoya kaydet, online olunca senkronize et |
| 2 | **Yavaş internet** | Loading göstergesi, zaman aşımı mesajı |
| 3 | **Küçük ekran** | Mobil uyumlu buton ve metin boyutları |
| 4 | **Eski cihaz** | Ağır animasyonlardan kaçın |
| 5 | **Farklı diller** | Şu an sadece Türkçe, ama genişletmeye hazır ol |

### 4.3 İş Kuralları

| # | Kural | Uygulama |
|---|-------|----------|
| 1 | **Zorunlu alanlar boş geçilemez** | WhatsApp, Konum, Yasal Onay |
| 2 | **WhatsApp formatı** | 05 ile başlamalı, 10 haneli olmalı |
| 3 | **Konum en az şehir/ilçe içermeli** | GPS veya elle giriş |
| 4 | **Yasal onay olmadan yayınlanamaz** | Tüm onaylar alınmalı |
| 5 | **Aynı isimde vitrin olamaz** | Slug çakışması kontrolü |

---

## 5. ASİSTAN KONUŞMA ŞABLONLARI

### 5.1 Karşılama Şablonları

```dart
// Yeni kullanıcı
'Merhaba! Ben Vixrex, senin dijital vitrin asistanın.\n\n'
'Google\'da, WhatsApp\'ta ve haritalarda görünür olman için buradayım.\n\n'
'Vitrinini oluşturup yayına almamı ister misin?'

// Kayıtlı kullanıcı (vitrin yok)
'Tekrar hoş geldin! Vitrinini henüz oluşturmadık.\n'
'Şimdi oluşturmak ister misin?'

// Kayıtlı kullanıcı (vitrin var)
'Vitrinin hazır görünüyor! Bir şey eklemek veya değiştirmek ister misin?'
```

### 5.2 Bilgi İsteme Şablonları

```dart
// İşletme adı
'Harika! Şimdi işletmenin adını söyle.\n'
'Bu isim Google\'da ve vitrininde görünecek.'

// Sektör
'Sektörünü seç, sana özel şablonlar önereyim:\n'
'[Giyim] [Kafe] [Kuaför] [Eczane] ...'

// WhatsApp
'Müşterilerin seni nasıl bulsun?\n'
'WhatsApp numaranı yaz.\n'
'(05xx xxx xx xx formatında)'

// Konum
'İşletmen nerede?\n'
'GPS ile konumunu alabilirsin — ya da şehir, ilçe ve kısa adresi yaz.'

// Yasal onay
'Son adım! Yayın için kullanım şartlarını kabul etmen yeterli.\n'
'Kısa tutuyoruz.'
```

### 5.3 Başarı Şablonları

```dart
// Her adım sonrası
'Harika! {alan_adı} kaydedildi.\n'
'Sıradaki adım: {sonraki_adım}'

// Yayın sonrası
'İşte bu kadar! Vitrinin artık yayında.\n\n'
'İşletme adına özel linkin: {link}\n'
'Web siten var — domain masrafın yok.'

// Tümü tamamlandı
'Tebrikler! Vitrinin artık yayında.\n\n'
'Sıradaki önerilerim:\n'
'1. Kapak fotoğrafı ekle\n'
'2. İlk ürününü ekle\n'
'3. Çalışma saatlerini gir'
```

### 5.4 Hata Şablonları

```dart
// Boş alan
'Bu alan zorunlu. Lütfen doldur.'

// Geçersiz format
'Bu format geçerli değil.\n'
'Şu şekilde gir: {örnek}'

// İnternet yok
'İnternet bağlantın yok gibi görünüyor.\n'
'Çevrimdışı devam edebilirsin — bilgiler yerel depoda saklanır.'

// Tekrar deneme
'Bir sorun oluştu. Tekrar dener misin?'
```

---

## 6. AKSIYON TETİKLEYİCİLERİ

### 6.1 Quick Reply Tetikleyicileri

| Buton | Tetikleyici | Aksiyon |
|-------|-------------|---------|
| "Evet, oluşturalım" | Karşılama sonrası | Adım 2'ye geç |
| "Şimdilik bakınıyorum" | Karşılama sonrası | Asistanı kapat |
| "Devam Et" | Her adım sonrası | Bir sonraki adıma geç |
| "Geri Dön" | Herhangi bir adım | Bir önceki adıma dön |
| "Vazgeç" | Herhangi bir adım | Onboarding'i sonlandır |
| "Yayınla" | Son adım | Publish işlemini başlat |
| "Düzenle" | Yayın sonrası | MyVitrinScreen'e git |
| "Hesabımı Güvenceye Al" | Yayın sonrası | AuthScreen'e git |

### 6.2 Doğrudan Aksiyonlar

| Durum | Asistan Davranışı |
|-------|-------------------|
| Kullanıcı "ürün eklemek istiyorum" derse | Ürün ekleme akışına yönlendir |
| Kullanıcı "randevu kur" derse | Randevu kurulumuna yönlendir |
| Kullanıcı "blog yaz" derse | Blog editörüne yönlendir |
| Kullanıcı "SEO yap" derse | SEO ayarlarına yönlendir |

---

## 7. STATE YÖNETİMİ

### 7.1 Asistan Durumu

```dart
enum AsistanDurumu {
  karsilama,        // İlk karşılama
  bilgiToplama,     // Bilgi toplama aşaması
  onayBekleme,      // Kullanıcı onayı bekleniyor
  islem,            // İşlem yapılıyor
  basari,           // İşlem başarılı
  hata,             // Hata oluştu
  beklemede,        // Kullanıcı bekleniyor
}
```

### 7.2 Veri Kaybı Önleme

```dart
// Her adım sonrası kaydet
void adimTamamlandi(Adim adim, dynamic veri) {
  // 1. Yerel depoya kaydet
  storage.saveAdimVerisi(adim, veri);
  
  // 2. Controller'ı güncelle
  controller.updateField(adim.fieldName, veri);
  
  // 3. UI'ı yenile
  notifyListeners();
}
```

### 7.4 Geriye Dönüş

```dart
// Bir önceki adıma dön
void oncekiAdimaDon() {
  if (mevcutAdim.index > 0) {
    mevcutAdim = Adim.values[mevcutAdim.index - 1];
    // Önceki veriyi yükle
    final oncekiVeri = storage.loadAdimVerisi(mevcutAdim);
    controller.restoreField(mevcutAdim.fieldName, oncekiVeri);
  }
}
```

---

## 8. entegrasyon NOKTALARI

### 8.1 Mevcut Sistemlerle Bağlantı

| Mevcut Sistem | Asistan Entegrasyonu |
|---------------|---------------------|
| `StoreEditorController` | Her adım sonrası `updateName()`, `updateWhatsapp()` vs. çağrılır |
| `StorePublishService` | Son adımda `publish()` çağrılır |
| `ChatbotService` | Asistan mesajları `ChatMessage.bot()` ile üretilir |
| `VixRexGuidanceService` | Öneriler `recommendationFor()` ile alınır |
| `SharedPreferences` | Durum ve veriler yerel depoda saklanır |

### 8.2 Callback Yapısı

```dart
// Asistandan diğer ekranlara geçiş
class AsistanCallbacks {
  final VoidCallback onVitrineGit;      // MyVitrinScreen'e git
  final VoidCallback onYayinla;         // Yayınla
  final VoidCallback onHesapBagla;      // AuthScreen'e git
  final void Function(String) onLinkKopyala;  // Linki kopyala
  final VoidCallback onQRGoster;        // QR kodu göster
}
```

---

## 9. TEST SENARYOLARI

### 9.1 Mutlu Yol

| # | Senaryo | Beklenen |
|---|---------|----------|
| 1 | Yeni kullanıcı → tüm adımları tamamla → yayınla | Başarılı yayın |
| 2 | Kayıtlı kullanıcı → vitrini düzenle | Düzenleme ekranı |
| 3 | Yayın sonrası → hesap bağla | Hesap bağlama başarılı |

### 9.2 Hata Senaryoları

| # | Senaryo | Beklenen |
|---|---------|----------|
| 1 | Boş işletme adı gir | Hata mesajı |
| 2 | Geçersiz WhatsApp numarası | Hata mesajı |
| 3 | İnternet kesintisi | Çevrimdışı mod |
| 4 | Sunucu hatası | Tekrar deneme |
| 5 | Aynı isimde vitrin | Uyarı |

### 9.3 Sınır Senaryoları

| # | Senaryo | Beklenen |
|---|---------|----------|
| 1 | 100 karakter uzunluğunda işletme adı | Kısalt veya uyar |
| 2 | Emoji ile işletme adı 🏪 | Kabul et |
| 3 | Türkçe karakterler İ, Ş, Ğ | Doğru işle |
| 4 | Cihaz yön değiştirme | Durumu koru |
| 5 | Ekranı kapat ve tekrar aç | Devam ettir |

---

## 10. ÖZET KONTROL LİSTESİ

### Asistan Başlamadan Önce

- [ ] Kullanıcı "Vixrex Oluştur" butonuna bastı mı?
- [ ] Mevcut vitrin verisi var mı? (varsa atla)
- [ ] Asistan durumu sıfırlandı mı?
- [ ] Callback'ler bağlandı mı?

### Her Adım Öncesi

- [ ] Bir önceki adım tamamlandı mı?
- [ ] Veriler yerel depoya kaydedildi mi?
- [ ] Kullanıcı onayı alındı mı?
- [ ] Hata durumu kontrol edildi mi?

### Her Adım Sonrası

- [ ] Controller güncellendi mi?
- [ ] UI yenilendi mi?
- [ ] Bir sonraki adım hazır mı?
- [ ] Başarı mesajı gösterildi mi?

### Yayın Sonrası

- [ ] Link oluşturuldu mu?
- [ ] QR kodu hazır mı?
- [ ] Kalite puanı hesaplandı mı?
- [ ] "Hesabımı Güvenceye Al" butonu görünüyor mu?

---

## 11. SONUÇ

Asistan şu kurallara uyacak:

1. **Sıralı ilerlecek** - Adımları atlamayacak
2. **Her adımda kaydedecek** - Veri kaybı olmayacak
3. **Kısa ve öz konuşacak** - Kullanıcıyı yormayacak
4. **Hata durumlarını idare edecek** - Durdurmayacak, devam ettirecek
5. **Değer gösterecek** - Neden yaptığını açıklayacak
6. **Aksiyon odaklı olacak** - Her mesajda bir sonraki adım olacak
7. **Mevcut sistemlerle entegre çalışacak** - Yeni yol açmayacak
