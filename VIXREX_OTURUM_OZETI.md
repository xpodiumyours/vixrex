# VixRex Proje Defteri
> Son güncelleme: 2026-07-09 | Son commit: `e7ab249`

---

## 1. Anlık Durum (Dashboard)

| Gösterge | Değer | Not |
|---|---|---|
| `flutter analyze` | **0 hata**, 4 info | Temiz |
| Testler | **251/255** | 4 test önceden başarısızdı |
| Son commit | `e7ab249` | AI_AGENT_LOG silindi |
| Toplam dosya | 140+ Dart | lib/: ~30K satır |

---

## 2. Aktif Görevler

### Yapılacaklar (Öncelik sırasıyla)

| # | Görev | Tier | Durum | Not |
|---|---|---|---|---|
| 1 | Oturum hatası (#62) | Acil | ⏳ | Auth token yenilenmiyor |
| 2 | Mascot yarım görünme (#26) | Acil | ⏳ | Her ekranda kesik |
| 3 | Image caching | T1 | ⏳ | `cached_network_image` ekle |
| 4 | Offline mod | T2 | ⏳ | `connectivity_plus` + cache |
| 5 | Public vitrin web sitesi seviyesi | Önemli | ⏳ | Hakkında, ürünler, yorumlar |
| 6 | Kullanıcı profili geliştirme | Önemli | ⏳ | İstatistikler, kalite puanı |
| 7 | Asistan AI seviyesi | Önemli | ⏳ | Gerçek AI, quick reply'ler |
| 8 | Yasal bölüm profesyonelleşme | Önemli | ⏳ | Modal/accordion |
| 9 | Domain satın alma | Gelecek | ⏳ | vixrex.app |
| 10 | SEO genişleme | Gelecek | ⏳ | Local → Genel |

### Büyük Dosyalar (Bölünmeli)

| Dosya | Satır | Öncelik |
|---|---|---|
| `landing_hero_section.dart` | 767 | Orta |
| `booking_wizard_sheet.dart` | 733 | Düşük |
| `blog_editor_screen.dart` | 732 | Düşük |
| `working_hours_editor.dart` | 697 | Düşük |
| `vixrex_screen.dart` | 688 | Düşük |
| `landing_template_catalog.dart` | 615 | Düşük |
| `vitrin_form_section.dart` | 631 | Düşük |
| `store_publish_service.dart` | 608 | Düşük |

---

## 3. Tamamlanan İşler (Geçmiş Özet)

### 2026-07-09: Junie + Vibe Coding Düzeltmeleri
- StoreEditorController 798→324 satır (3 mixin'e bölündü)
- Junie'nin bozduğu 62 hata düzeltildi (chatbot_badge, override'lar, imzalar)
- Vibe coding TIER-1: OCR try-catch, mounted check, debugPrint sarmalama, form validation
- **Commit:** `819f406`, `6e4bd48`, `e7ab249`

### 2026-07-07: Mimari Temizlik + UI
- Result<T> pattern tüm servislere geçirildi
- CLAUDE.md kurallar dosyası oluşturuldu
- Masaüstü sidebar navigation eklendi
- Keşfet kartları kompaktlaştırıldı
- Ürünlerin Supabase'e otomatik senkronizasyonu
- 35 başarısız test → 0 başarısız

### 2026-07-06: God Object Parçalanmaları
- MyVitrinScreen: 1800→248 satır
- StoreData: 849→360 satır
- LandingScreen: 1700→287 satır
- StoreEditorController: İlk adım (EditorGalleryItem ayrıldı)

---

## 4. Mimari Durum

### Çözülen Kritik Riskler ✅
- MyVitrinScreen God Widget (1800→248 satır)
- StoreData God Object (849→360 satır)
- UI'dan doğrudan Supabase çağrıları
- Controller/Screen çift publish mantığı
- StoreEditorController (798→324 satır, 3 mixin)
- unused import hack'leri

### Devam Eden Riskler ⚠️
- `chatbot_badge.dart` 202 satır (hâlâ büyük)
- `AuthService` test edilemezlik (Supabase.instance.client kullanımı)
- Offline mod yok
- Image caching yok

---

## 5. Kurallar & Standartlar

### Kod Kuralları (CLAUDE.md'den)
- `catch (_) {}` KULLANMA → en az `debugPrint` ile logla
- Tüm servis metotları `Future<Result<T>>` dönmeli
- Screen'de `Supabase.instance.client` kullanılmamalı
- Dosya 300 satırsa böl
- Aynı kod 2 dosyada olamaz (DRY)

### Commit Formatı
```
tip(değişiklik): kısa açıklama
feat(yeni): ..., fix(hata): ..., refactor(temizlik): ..., test: ..., docs: ...
```

### Her İşlem Sonrası Kontrol
- [ ] `flutter analyze` → sıfır hata?
- [ ] `catch (_) {}` var mı?
- [ ] Dosya 300 satırı geçti mi?
- [ ] `if (mounted)` kontrolü var mı (async setState)?
- [ ] debugPrint `kDebugMode` ile sarmalanmış mı?
- [ ] Test çalıştırıldı mı?

---

## 6. Demo Kontrol Listesi

> Her büyük değişiklik sonrası bu listeyi çalıştır

- [ ] `flutter analyze` → 0 hata
- [ ] `flutter test` → tüm testler geçiyor
- [ ] Yeni APK build al → gerçek fişle dene
- [ ] İnternet kapalıyken aç → ne oluyor?
- [ ] 5MB+ fotoğraf yükle → donuyor mu?
- [ ] OCR tarama → ürün çıkıyor mu?
- [ ] Vitrin yayınla → link çalışıyor mu?
- [ ] Public vitrin → mobilde düzgün görünüyor mu?

---

## 7. Kişisel Notlar

- **Aymira Giyim** → Babanın dükkanı, demo olarak kullanılıyor
- **Çekmeköy, İstanbul** → İşletme konumu
- **Hedef kitle** → Küçük işletme sahipleri, teknik bilgisi olmayan esnaf
- **Dil:** Türkçe, kısa ve öz yaz
- **Görüş:** Gözleri bozuk, ekrana uzun süre bakamıyor

---

## 8. Kullanılan Linkler

| Servis | Link | Durum |
|---|---|---|
| Vercel | `vitrinx-two.vercel.app` | Çalışıyor |
| Supabase | `chfulefxczbgurtgavtp` | Aktif |
| GitHub | `xpodiumyours/vitrinx` | Push edildi |

---

## 9. Dosya Yolları

| Dosya | Amaç |
|---|---|
| `VIXREX_OTURUM_OZETI.md` | Bu dosya (tek kaynak) |
| `CLAUDE.md` | Proje kuralları |
| `VIXREX_UI_NOTLARI.md` | 90 maddelik UI düzeltme notları |
| `ANALIZ_RAPORU.md` | Teknik röntgen raporu |
| `OCR_ENTEGRESION_PLANI.md` | OCR entegrasyon planı |
| `VIXREX_REKABET_ANALIZI.md` | Rakip analizi |
| `VIXREX_URUN_GELISIM_PLANI.md` | Ürün geliştirme planı |
