# VixRex Vibe Coding Master Skill

> Bu skill, vibe coding süreçlerini kontrol altına almak, MVP/demo engellemek, token harcamasını optimize etmek ve VixRex'in çift platform yapısını yönetmek için kullanılır.

---

## 1. Token Optimizasyonu ve Context Yönetimi

AI session yönetimi vibe coding'in en kritik konusudur. Context çöküşü tüm geliştirme sürecini durdurur.

### Kurallar
- Context 80K token'a ulaşınca **YENİ SESSION** başlat
- Her session'da tek feature odaklan (max 5 dosya)
- Önce `VIXREX_OTURUM_OZETI.md` oku, sonra devam et
- Eski tool output'larını session'da tutma, `NOTES.md` özet dosyası kullan
- `/context` komutu ile token kullanımını izle, `/compact` ile alan aç
- Gereksiz `flutter analyze` çalıştırma (max günde 3-4 kez)
- Kapsamlı tarama yapmadan önce dosya sayısını kontrol et

### Token Bütçesi
| İşlem | Tahmini Token | Not |
|---|---|---|
| Tek dosya okuma | ~2K | Makul |
| 5 dosya okuma | ~10K | Sınır |
| flutter analyze | ~5K | Gereksizse çalıştırma |
| Kapsamlı tarama (10+ dosya) | ~20K+ | Dikkatli ol |

---

## 2. Scope Drift Önleme (MVP Koruma)

Vibe coding'in en tehlikeli sonucu: Her session'da yeni özellik eklenmesi.

### Kurallar
- `PLAN.md` dosyasındaki "Faz 1" dışına çıkma
- Yeni fikir gelirse → `PLAN.md`'ye "Faz 2/Gelecek" bölümüne yaz, şimdi implemente ETME
- Her session başında: "Bugün sadece [X] özelliği. Başka önerme."
- AI'dan 3 yaklaşım iste: "Basit / Orta / Full-featured" → Hep **Basit**'i seç
- "Bu özellik MVP'ye dahil mi?" sorusunu her değişiklik öncesi sor

### MVP Sınırı
```
VixRex MVP'si şunları kapsar:
✅ Vitrin oluşturma ve yayınlama
✅ Ürün ekleme ve düzenleme
✅ QR kod ile paylaşma
✅ Keşfet sayfası
✅ Randevu sistemi
❌ Ödeme sistemi (gelecek)
❌ Çoklu dil desteği (gelecek)
❌ AI destekli öneriler (gelecek)
```

---

## 3. Flutter ↔ Next.js Çapraz Tutarlılık

VixRex'in çift platform yapısı en kritik zorluktur. Aynı veri farklı yüzeylerde gösterilir.

### Kurallar
- **Aynı API contract**: Supabase RLS ve fonksiyonlar her iki platformda aynı çalışmalı
- **Aynı veri modeli**: `lib/models/` ve `src/types/` senkronize olmalı
- **UI kararları**: Bir platformda alınan UI kararı diğerine de yansıtılmalı
- **Auth flow**: Flutter'daki login/register akışı ile Next.js'teki aynı olmalı
- Değişiklik yaparken: "Bu değişiklik diğer platformu etkiler mi?" sorusunu sor

### Platform Karşılaştırması
| Katman | Flutter (İşletme) | Next.js (Public) |
|---|---|---|
| Auth | Supabase Auth | Supabase Auth |
| Veri | Supabase PostgreSQL | Supabase PostgreSQL |
| UI | Dart/Flutter | React/Next.js |
| Deploy | Vercel (Flutter web) | Vercel (Next.js) |
| Storage | Supabase Storage | Supabase Storage |

---

## 4. Hallucinated API / Dependency Doğrulama

AI, olmayan metodlar ve paketler önerebilir. Bu vibe coding'in en sinsi hatasıdır.

### Kurallar
- Yeni paket önerisi gelirse: `pub.dev` veya `npm` üzerinden varlığını kontrol et
- Supabase fonksiyonu önerilirse: Resmi dokümantasyondan doğrula
- Breaking change içeren paket güncellemesi → Önce changelog oku, sonra uygula
- `flutter pub deps` ve `npm audit` her hafta çalıştırılmalı
- AI'ın önerdiği kodu körlemesine kullanma, her zaman doğrula

### Doğrulama Checklist
- [ ] Paket pub.dev/npm'de var mı?
- [ ] Son sürüm hangisi? Uyumlu mu?
- [ ] Breaking change var mı?
- [ ] Dokümantasyon doğru mu?

---

## 5. E2E Test Stratejisi

Vibe-coded kodda unit test yerine E2E test daha güvenilirdir.

### E2E Test Önceliği
- **Kritik kullanıcı akışları** E2E ile test edilmeli:
  - İşletme kaydı → Vitrin oluşturma → Ürün ekleme → Public vitrin görüntüleme
  - Login → Dashboard → Ürün düzenleme → Değişikliğin public vitrinde görünmesi
- Araçlar: Flutter için **Patrol**, Next.js için **Playwright**
- Her PR'da E2E pipeline geçmeli (GitHub Actions)
- Unit test sadece: `Result<T>` utilities, validation, calculation

### Test Piramidi
```
        E2E (Az, Yavaş, Güvenilir)
       /                           \
      Integration (Orta)            \
     /                               \
    Unit Test (Çok, Hızlı, Temel)
```

---

## 6. Vitrin UI Kalite Kontrolü

VixRex bir vitrin platformu — UI kalitesi iş modelinin merkezinde.

### Kurallar
- **8pt grid** sistemi kullanılmalı
- **Loading states**: Skeleton > CircularProgressIndicator
- **Empty states**: "Henüz ürün eklenmemiş" gibi kullanıcı dostu mesajlar
- **Error states**: Teknik hata mesajı değil, "Bir sorun oluştu, tekrar dene" + retry butonu
- **Dark mode**: Her iki platformda aynı tema tokenları
- **Responsive**: Mobil vitrin ve web vitrin aynı bilgiyi farklı formatta göstermeli
- **Accessibility**: WCAG 2.2 AA minimum

### UI Kontrol Listesi
- [ ] 8pt grid kullanılıyor mu?
- [ ] Loading/empty/error states var mı?
- [ ] Dark mode uyumlu mu?
- [ ] Primary CTA belirgin mi?
- [ ] Responsive düşünüldü mü?

---

## 7. Hata Mesajı Standartları (Türkçe)

Tüm hata mesajları Türkçe, anlaşılır ve aksiyon odaklı olmalı.

### Hata Mesajı Şablonları
| Durum | Mesaj | Aksiyon |
|-------|-------|---------|
| Ağ hatası | "İnternet bağlantınızı kontrol edin" | Retry butonu |
| Auth hatası | "Giriş bilgileriniz hatalı, tekrar deneyin" | Login ekranına yönlendir |
| Veri bulunamadı | "Henüz içerik eklenmemiş" | Ekleme butonu göster |
| Sunucu hatası | "Bir sorun oluştu, lütfen tekrar deneyin" | Retry + destek linki |
| Validasyon | "[Alan] zorunludur" / "[Alan] geçersiz format" | İlgili input'a odaklan |

---

## 8. Güvenlik ve İzin Yönetimi

### Mobil İzin Yönetimi
| İzin | Kullanım | Zorunlu |
|------|----------|---------|
| Kamera | Ürün fotoğrafı çekme | Evet |
| Galeri | Ürün fotoğrafı seçme | Evet |
| Konum | İşletme adresi tespiti | Önerilen |
| Bildirimler | Sipariş/Sipariş durumu | Evet |
| Biyometrik | Hızlı giriş | Önerilen |

- İzin **contextual** istenmeli (kullanıcı kamera butonuna bastığında)
- Reddedilirse: Ayarlara yönlendirme + alternatif sunma
- `permission_handler` paketi kullan

### Veri Gizliliği
- **Public vitrin**: İşletme adı, adres, ürünler, fiyatlar → Herkese açık
- **Private veri**: Müşteri listesi, sipariş geçmişi, finansal veriler → Auth gerekli
- **Supabase RLS**: Her tabloda row-level security politikaları aktif
- **API rate limiting**: 100 req/min başlangıç
- **GDPR/KVKK**: Kullanıcı verisi silme talebi endpoint'i hazır olmalı

---

## 9. Prompt Şablonları (VixRex Özel)

Her işlem türü için standart prompt şablonları.

### Yeni Özellik
```
VixRex [Flutter/Next.js] projesinde [özellik adı] implementasyonu.
Mevcut mimari: Clean Architecture, Result<T> pattern, Supabase.
İlgili dosyalar: [max 5 dosya listesi]

Önce:
1. Implementasyon planı (hangi dosyalar değişecek)
2. API endpoint / Supabase fonksiyonları
3. UI değişiklikleri
4. Test senaryoları

Onay verince kod yaz. Context window'u 80K altında tut.
```

### Debug
```
VixRex'te [hata açıklaması].
Hata: [stack trace / mesaj]
İlgili dosyalar: [dosyalar]

Sadece bu dosyaları analiz et. Root cause bul, minimum fix uygula.
Diğer dosyalara dokunma. Test yazmayı unutma.
```

### UI Review
```
[Screen] UI'sini VixRex vitrin standartlarına göre review et:
- 8pt grid kullanılıyor mu?
- Loading/empty/error states var mı?
- Dark mode uyumlu mu?
- Primary CTA belirgin mi?
- Responsive (mobil vitrin + web vitrin) düşünüldü mü?
```

---

## 10. Vibe Coding Hata Tespit Matrisi

| Hata Belirtisi | Muhtemelen Neden | Kontrol |
|---|---|---|
| Compile hatası | Import veya parametre hatası | Dosya yollarını ve imzaları kontrol et |
| Runtime crash | Null check veya mounted | try-catch ve mounted kontrolü ekle |
| Yanlış sonuç | Logic hatası | Debug ile adım adım takip et |
| Yavaş performans | Senkron işleme | Async/await kullan |
| Bellek sızıntısı | Dispose eksik | Controller dispose kontrolü |
| UI bozulluğu | Widget hierarchy hatası | Scaffold-Column-Expanded sırasını kontrol et |
| Veri kaybı | State yönetimi hatası | Provider/Bloc kontrolü |
| Güvenlik açığı | Input validation eksik | Her input'u doğrula |

---

## 11. Kontrol Listesi (Her İşlem Sonrası)

### Teknik Kontrol
- [ ] `flutter analyze` sıfır hata?
- [ ] `flutter test` tüm testler geçiyor?
- [ ] `if (!mounted) return;` eklendi mi?
- [ ] `try-catch` eklendi mi?
- [ ] `debugPrint` kDebugMode ile sarmalandı mı?

### MVP Kontrol
- [ ] Bu değişiklik MVP sınırları içinde mi?
- [ ] Yeni özellik eklenmedi mi? (Scope drift)
- [ ] Mevcut kod bozulmadı mı?

### Platform Kontrol
- [ ] Diğer platformu etkiledi mi? (Flutter ↔ Next.js)
- [ ] API contract değişti mi?
- [ ] Veri modeli tutarlı mı?

### Güvenlik Kontrol
- [ ] Service role anahtarı istemci kodunda yok mu?
- [ ] Input validation var mı?
- [ ] RLS aktif mi?

### Deploy Kontrol
- [ ] Commit mesajı yazıldı mı?
- [ ] Push edildi mi?
- [ ] Deploy başarılı mı?
- [ ] Test edildi mi?
