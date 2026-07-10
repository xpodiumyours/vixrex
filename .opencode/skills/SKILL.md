# VixRex Profesyonel Yazılım Geliştirme Skill'i

> Bu skill, tüm uygulama geliştirme süreçlerini kapsar: Vibe coding önleme, MVP engelleme, token kontrolü, modülerlik, UI uyumu, E2E test.

---

## 1. TEMEL PRENSİPLER

### 1.1 Vibe Coding Önleme Kuralları

**Tanım:** AI'ın plansız, test edilmeden, mevcut kodu bozarak yazdığı koddur.

**Önleme adımları:**
1. **Oku → Anla → Planla → Uygula** sırası zorunlu
2. Mevcut kodu silip yeniden yazma (refaktör hariç)
3. Her değişiklik sonrası `flutter analyze` + `flutter test`
4. Tek seferde max 3 dosyada değişiklik yap
5. Import zincirlerini kontrol et (yeni import eklerken eskileri koru)
6. Constructor imzası değişikliğinde tüm caller'ları güncelle

### 1.2 MVP/Demo Engelleme Kuralları

**Tanım:** "Çalışıyor" ile "ürün" arasındaki fark.

**Kontrol listesi:**
- [ ] Tüm async metodlarda try-catch var mı?
- [ ] mounted kontrolü her setState sonrası eklendi mi?
- [ ] debugPrint kDebugMode ile sarmalandı mı?
- [ ] Servisler Result<T> pattern'i kullanıyor mu?
- [ ] Testler çalışıyor mu? (flutter test)
- [ ] Production'da log sızıntısı yok mu?
- [ ] Offline durumda uygulama çöküyor mu?
- [ ] Loading state gösteriliyor mu?
- [ ] Hata mesajları kullanıcıya Türkçe gösteriliyor mu?

### 1.3 Token Harcaması Kontrolü

**Kurallar:**
- Gereksiz `flutter analyze` çalıştırma (max günde 3-4 kez)
- Gereksiz dosya okuma (sadece ilgili dosyaları oku)
- Kapsamlı tarama yapmadan önce dosya sayısını kontrol et
- Query token bütçesini aşma (tek mesajda max 10 dosya oku)

---

## 2. KOD MİMARİSİ STANDARTLARI

### 2.1 Klasör Yapısı (Flutter)

```
lib/
  core/           → Result<T>, SupabaseErrorMapper (merkezi araçlar)
  services/       → Tüm iş mantığı (Result<T> döner, HATA YÖNETİMİ BURADA)
  controllers/    → State yönetimi (ChangeNotifier)
  screens/        → Sadece UI, iş mantığı YOK
  widgets/        → Tekrar kullanılabilir bileşenler
  utils/          → Yardımcı fonksiyonlar
  models/         → Veri modelleri
  config/         → Sabitler, yapılandırma
  theme/          → Renkler, stiller
test/             → Unit ve widget testleri
```

### 2.2 Katman Kuralları

| Katman | Yapabilir | Yapamaz |
|---|---|---|
| **Screen** | UI oluştur, controller'ı çağır | Supabase.instance.client, iş mantığı |
| **Controller** | State yönetimi, servis çağrısı | Doğrudan UI oluşturma |
| **Service** | Veritabanı işlemleri, API çağrıları | UI oluşturma, state yönetimi |
| **Model** | Veri yapısı tanımlama | İş mantığı |

### 2.3 Servis Kalıbı

```dart
class XService {
  final SupabaseClient? _client;
  const XService({SupabaseClient? client}) : _client = client;
  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  Future<Result<T>> methodName() async {
    try {
      final res = await _resolveClient.from('table').select();
      return Result.success(data);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}
```

---

## 3. YENİ UYGULAMA GELİŞTİRME İÇİN ADIM ADIM REHBER

### 3.1 Keşif Aşaması (Başlamadan Önce)

```
1. Uygulama türünü belirle (e-ticaret, sosyal, stok, cüzdan, vb.)
2. Hedef kitleyi tanımla (yaş, teknik bilgi, kullanım alanı)
3. Rakip analizi yap (3-5 rakip, güçlü/zayıf yönler)
4. Temel özellik listesi çıkar (MVP için 5-7 özellik)
5. Teknoloji yığınını seç (Flutter, React Native, vb.)
6. Hosting/depolama planını yap
```

### 3.2 Planlama Aşaması

#### Sayfa Haritası (Uygulama Türüne Göre)

**Sosyal Arkadaşlık Platformu:**
```
Landing → Kayıt/Giriş → Ana Sayfa (Keşfet) → Profil → Mesajlar → Bildirimler
                                    ↓
                              Arkadaşlık İstekleri → Profil Detayı
```

**E-Ticaret Platformu:**
```
Landing → Kayıt/Giriş → Ana Sayfa (Ürünler) → Ürün Detayı → Sepet → Ödeme
                                    ↓
                              Kategori → Arama → Favoriler
```

**Stok Takip:**
```
Landing → Kayıt/Giriş → Dashboard → Ürün Ekleme → Raporlar → Ayarlar
                                    ↓
                              Stok Girişi → Stok Çıkışı → Geçmiş
```

**Dijital Cüzdan:**
```
Landing → Kayıt/Giriş → Ana Sayfa (Bakiye) → Para Yatırma → Para Çekme → İşlem Geçmişi
```

#### Landing Sayfası Yapısı

```
┌─────────────────────────────────────────┐
│  [Logo]              [Giriş] [Kayıt]    │
├─────────────────────────────────────────┤
│  Hero Bölümü                            │
│  • Başlık (Ne yapar?)                   │
│  • Alt başlık (Neden biz?)              │
│  • CTA Butonu (Hemen Başla)             │
│  • Telefon/Ekran görüntüsü              │
├─────────────────────────────────────────┤
│  Özellikler (3-6 madde)                 │
│  • İkon + Başlık + Açıklama             │
├─────────────────────────────────────────┤
│  Nasıl Çalışır? (3-4 adım)              │
│  • Numaralı adımlar                     │
├─────────────────────────────────────────┤
│  Sosyal Kanıt (Yorumlar/İstatistikler)  │
├─────────────────────────────────────────┤
│  Fiyatlandırma (varsa)                  │
├─────────────────────────────────────────┤
│  Footer (İletişim, Yasal, Sosyal Medya) │
└─────────────────────────────────────────┘
```

#### Üyelik/Giriş Sayfası Tasarım Kuralları

| Unsur | Kural |
|---|---|
| **Buton İsimleri** | "Kayıt Ol", "Giriş Yap" (kısa, net) |
| **Buton Yerleşimi** | Ana CTA: Ortada büyük, İkincil: üst sağda küçük |
| **Form Alanları** | E-posta + Şifre (minimum), Telefon (opsiyonel) |
| **Sosyal Giriş** | Google, Apple, Facebook (ikonlu butonlar) |
| **Güvenlik** | SSL, 2FA önerisi, şifre gücü göstergesi |
| **Yasal** | "Üye olarak ... kabul etmiş olursunuz" linki |

#### Login Gereksinimleri

```
Zorunlu Alanlar:
- E-posta veya Telefon
- Şifre (min 8 karakter, büyük harf + rakam)

Opsiyonel:
- Sosyal giriş (Google, Apple)
- 2FA (SMS/OTP)
- Beni hatırla

Platform Seçimi:
- Supabase Auth (Flutter için en uygun)
- Firebase Auth (Alternatif)
- Custom API (Tam kontrol)
```

### 3.3 Bulut Depolama ve Güvenlik

#### Depolama Platformları

| Platform | Maliyet | Entegrasyon | Kullanım |
|---|---|---|---|
| **Supabase Storage** | Ücretsiz 1GB | Kolay | Dosya yükleme |
| **Firebase Storage** | Ücretsiz 5GB | Kolay | Görsel/video |
| **AWS S3** | Kullanım başına | Orta | Büyük ölçek |
| **Cloudinary** | Ücretsiz 25GB | Kolay | Görsel optimizasyonu |

#### Güvenlik Kontrol Listesi

- [ ] SSL/TLS zorunlu
- [ ] JWT token süresi kısa (15-30 dk)
- [ ] Refresh token mekanizması var
- [ ] RLS (Row Level Security) aktif
- [ ] Service role anahtarı istemci kodunda yok
- [ ] Kullanıcı verileri şifreli
- [ ] API rate limiting var
- [ ] Input validation her yerde

#### Uygulama İzinleri

| İzin | Ne Zaman | Güvenlik |
|---|---|---|
| Kamera | Fotoğraf çekme | Sadece izin verildiğinde |
| Depolama | Dosya yükleme | Sadece seçilen dosyalar |
| Konum | Konum tabanlı hizmet | Kullanıcı onayı |
| Bildirim | Push notification | Kullanıcı onayı |
| Mikrofon | Ses kaydı | Sadece gerekliyse |

### 3.4 UI Tasarım Standartları

#### Modern UI Kuralları

```
1. Renk Paleti:
   - Ana renk: 1 adet (brand color)
   - Yardımcı renk: 2 adet (success, error)
   - Nötr renk: 3 adet (background, surface, border)

2. Tipografi:
   - Başlık: Bold, 24-32px
   - Alt başlık: SemiBold, 16-20px
   - Gövde: Regular, 14-16px
   - Küçük: Light, 12px

3. Boşluk:
   - İç boşluk: 16px
   - Dış boşluk: 8-12px
   - Bölüm arası: 24-32px

4. Köşe yuvarlaklığı:
   - Kartlar: 12-16px
   - Butonlar: 8-12px
   - Input'lar: 8px
```

#### Sayfa Akış Uyumu

```
Her sayfada bulunması gerekenler:
1. AppBar (başlık + geri butonu)
2. İçerik alanı (scroll edilebilir)
3. Alt bilgi (varsa)
4. Loading state (veri çekiliyorken)
5. Empty state (veri yoksa)
6. Error state (hata oluştuysa)
```

### 3.5 E2E Test Uygunluğu

#### Test Edilebilirlik Kontrol Listesi

- [ ] Her sayfa bağımsız olarak test edilebilir mi?
- [ ] Navigation akışı test edilebilir mi?
- [ ] Form validasyonları test edilebilir mi?
- [ ] API çağrıları mock edilebilir mi?
- [ ] Offline durum test edilebilir mi?
- [ ] Hata durumları test edilebilir mi?

#### Test Stratejisi

```
1. Unit Test: Service ve model katmanı (hızlı, çok)
2. Widget Test: UI bileşenleri (orta hız, orta)
3. Integration Test: Sayfa akışları (yavaş, az)
4. E2E Test: Tam uygulama akışı (en yavaş, en az)
```

---

## 4. HATA DÜZELTME REHBERİ

### 4.1 Compile Hataları

```
1. Import hatası → Dosya yolu doğru mu? Class adı doğru mu?
2. Parametre hatası → Constructor imzası değişti mi?
3. Tip hatası → Atama doğru mu? Cast doğru mu?
4. Tanımsız değişken → Scope doğru mu? Import var mı?
```

### 4.2 Runtime Hataları

```
1. Null check hatası → Null-safe kontrol ekle
2. Mounted hatası → if (!mounted) return; ekle
3. Timeout hatası → Timeout süresini artır veya retry ekle
4. Permission hatası → İzin kontrolü ekle
```

### 4.3 Logic Hataları

```
1. Yanlış sonuç → Debug ile adım adım takip et
2. Eksik veri → Null kontrolü ekle
3. Yanlış eşleşme → Fuzzy matching ekle
4. Performans sorunu → Async işleme ekle
```

---

## 5. TOKEN HARCAMASI KONTROL LİSTESİ

### Yapılacaklar

- [ ] Tek mesajda max 10 dosya oku
- [ ] Gereksiz `flutter analyze` çalıştırma (max günde 3-4)
- [ ] Kapsamlı tarama yapmadan önce dosya sayısını kontrol et
- [ ] Query token bütçesini aşma
- [ ] Uzun dosyaları okurken sadece ilgili bölümleri oku

### Yapılmayacaklar

- [ ] Tüm projeyi tarama (sadece ilgili dosyaları oku)
- [ ] Gereksiz test çalıştırma (sadece değişiklik sonrası)
- [ ] Aynı dosyayı birden fazla okuma
- [ ] Uzun yanıt verme (kısa ve net ol)

---

## 6. COMMIT VE DEPLOY STANDARTLARI

### Commit Formatı

```
tip(değişiklik): kısa açıklama

feat(yeni): yeni özellik eklendi
fix(hata): hata düzeltildi
refactor(temizlik): kod yeniden yapılandırıldı
test: test eklendi/güncellendi
docs: dokümantasyon güncellendi
chore: bakım işi
```

### Deploy Sırası

```
1. flutter analyze → 0 hata
2. flutter test → tüm testler geçiyor
3. Git commit → message formatına uy
4. Git push → remote'a gönder
5. Vercel/CI → otomatik deploy
```

---

## 7. KONTROL LİSTESİ (HER İŞLEM SONRASI)

### Teknik Kontrol
- [ ] `flutter analyze` → sıfır hata?
- [ ] `flutter test` → tüm testler geçiyor?
- [ ] mounted kontrolü eklendi mi?
- [ ] try-catch eklendi mi?
- [ ] debugPrint kDebugMode ile sarmalandı mı?

### Kalite Kontrol
- [ ] Kod okunabilir mi?
- [ ] Yorumlar gerekli mi?
- [ ] Dosya boyutu makul mü? (max 300 satır)
- [ ] Tekrar eden kod var mı?

### Güvenlik Kontrol
- [ ] Service role anahtarı istemci kodunda yok mu?
- [ ] Input validation var mı?
- [ ] RLS aktif mi?
- [ ] SSL zorunlu mu?

### Deploy Kontrol
- [ ] Commit mesajı yazıldı mı?
- [ ] Push edildi mi?
- [ ] Deploy başarılı mı?
- [ ] Test edildi mi?

---

## 8. ÖRNEK SENARYOLAR

### Senaryo 1: Yeni Özellik Eklerken

```
1. VIXREX_OTURUM_OZETI.md oku → Mevcut durumu anla
2. İlgili dosyaları oku (max 5 dosya) → Mevcut kodu anla
3. Plan oluştur → Ne yapılacağını belirle
4. Uygula → Mevcut kodu bozmadan üzerine inşa et
5. Test et → flutter analyze + flutter test
6. Commit et → Mesaj formatına uy
7. Güncelle → VIXREX_OTURUM_OZETI.md'yi güncelle
```

### Senaryo 2: Hata Düzeltirken

```
1. Hatanın kaynağını bul → Hangi dosyada, neden
2. Kök nedeni analiz et → Symptom mu, root cause mu?
3. Çözümü uygula → Minimum değişiklikle düzelt
4. Test et → flutter analyze + ilgili testleri çalıştır
5. Yan etkileri kontrol et → Başka bir şeyi bozdu mu?
6. Commit et → Fix: ... formatında
```

### Senaryo 3: Yeni Uygulama Geliştirirken

```
1. Uygulama türünü belirle → Sosyal mi, e-ticaret mi, stok mu?
2. Landing sayfasını tasarla → Hero, özellikler, CTA
3. Auth akışını kur → Kayıt, giriş, sosyal giriş
4. Ana sayfayı oluştur → Liste/grid, arama, filtre
5. Detay sayfasını oluştur → İçerik, yorum, işlem
6. Navigation kur → Tab bar veya drawer
7. Test et → E2E akışını kontrol et
8. Deploy et → Vercel/Firebase'e gönder
```

---

## 9. VİDEO KODING HATA TESPİT MATRİSİ

| Hata Belirtisi | Muhtemelen Neden | Kontrol |
|---|---|---|
| Compile hatası | Import veya parametre hatası | Dosya yollarını ve imzaları kontrol et |
| Runtime crash | Null check veya mounted | try-catch ve mounted kontrolü ekle |
| Yanlış sonuç | Logic hatası | Debug ile adım adım takip et |
| Yavaş performans | Senkron işleme | Async/await kullan |
| Bellek sızıntısı | Dispose eksik | Controller dispose kontrolü |
| UI bozukluğu | Widget hierarchy hatası |caffold-Column-Expanded sırasını kontrol et |
| Veri kaybı | State yönetimi hatası | Provider/Bloc kontrolü |
| Güvenlik açığı | Input validation eksik | Her input'u doğrula |

---

## 10. PROJE BÜYÜKLÜĞÜNE GÖRE STRATEJİ

### Küçük Proje (1-2 hafta)
- Basit klasör yapısı
- Minimum test (sadece service testleri)
- Manuel test yeterli
- Tek deploy (Vercel/Firebase)

### Orta Proje (1-2 ay)
- Katmanlı mimari (service-controller-screen)
- Unit + widget testleri
- CI/CD (GitHub Actions)
- Monitoring (Sentry/Firebase Crashlytics)

### Büyük Proje (3+ ay)
- Clean Architecture
- TDD (Test Driven Development)
- E2E testleri
- Feature flags
- A/B testing
- Analytics (Firebase/Amplitude)
