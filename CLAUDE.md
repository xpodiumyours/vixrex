# VixRex - Proje Rehberi

> Bu dosya HER otomatik okunur. Bu kurallara ve yapıya uymak zorunludur.

---

## 1. Proje Özeti

**VixRex**, küçük işletmeler için dijital vitrin platformu.

| Katman | Teknoloji | Kullanım |
|---|---|---|
| İşletme uygulaması | Flutter/Dart | Vitrin oluşturma, yayınlama, randevu yönetimi |
| Public vitrin | Next.js/React | Müşterilerin görüntülediği sayfa |
| Veritabanı | Supabase PostgreSQL | Tüm veriler |
| Auth | Supabase Auth | Kullanıcı girişi/kayıt |
| Deploy | Vercel | Flutter ve Next.js ayrı projeler |

---

## 2. Klasör Yapısı

```
lib/
  core/           → Result<T>, SupabaseErrorMapper (merkezi araçlar)
  services/       → Tüm Supabase işlemleri (Result<T> döner, HATA YÖNETİMİ BURADA)
  controllers/    → İş mantığı, state yönetimi (ChangeNotifier)
  screens/        → Sadece UI, iş mantığı YOK
  widgets/        → Tekrar kullanılabilir UI bileşenleri
  utils/          → Yardımcı fonksiyonlar (TextUtils, WhatsAppLinkHelper vb.)
  models/         → Veri modelleri (StoreData, Product, vb.)
  config/         → Sabitler, yapılandırma (AppRouter, BusinessCategoryConfig vb.)
  repositories/   → Veri erişim soyutlaması (şimdilik boş)
  theme/          → Renkler, stiller
test/             → Unit ve widget testleri
```

---

## 3. Zorunlu Kodlama Kuralları

### Hata Yönetimi
- `catch (_) {}` KULLANMA. En azından `debugPrint` ile logla.
- Tüm servis metotları `Future<Result<T>>` dönmeli.
- Hatalar servis katmanında yakalanmalı, ekrana `throw` fırlatılmamalı.
- Kullanıcıya Türkçe, anlaşılır hata mesajı gösterilmeli.

### Kod Kalitesi
- Aynı fonksiyon 2 dosyada olamaz (DRY).
- Dosya 300 satırı geçerse böl.
- Kullanılmayan import olmamalı.

### Mimari
- Screen dosyalarında `Supabase.instance.client` kullanılmamalı.
- Servis dosyalarında constructor injection ile test edilebilirlik sağlanmalı.
- Yeni servis eklerken `Result<T>` pattern'ini kullan.

### Test
- Yeni servis eklerken test de ekle.
- `flutter analyze` sıfır hata vermeli.

---

## 4. Servis Kalıbı (Referans)

Yeni servis eklerken bu kalıbı kullan:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vixrex/core/result.dart';
import 'package:vixrex/core/supabase_error_mapper.dart';

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

## 5. Yasaklar

| Yapma | Neden |
|---|---|
| `catch (_) {}` | Hata yutuluyor, debug edilemez |
| `Supabase.instance.client` screen içinde | Test edilemez, katman ihlali |
| `throw Exception('msg')` serviste | Result<T> kullanmalısın |
| Dosya > 500 satır | Anlaşılması zor |
| Aynı kod 2 dosyada | Değişiklik unutulabilir |
| Service role anahtarı istemci kodunda | Güvenlik açığı |

---

## 6. Adım Adım İş Akışı

### Yeni Özellik Eklerken
```
1. VIXREX_OTURUM_OZETI.md'yi oku → Mevcut durumu anla
2. İlgili dosyaları oku → Mevcut kodu anla
3. Plan oluştur → Ne yapılacağını belirle
4. Uygula → Kodu yaz
5. Test et → flutter analyze + flutter test
6. Commit et → Mesaj formatına uy
7. Güncelle → VIXREX_OTURUM_OZETI.md'yi güncelle
```

### Hata Düzeltirken
```
1. Hatanın kaynağını bul → Hangi dosyada, neden
2. Kök nedeni analiz et → Symptom mu, root cause mu?
3. Çözümü uygula → Minimum değişiklikle düzelt
4. Test et → flutter analyze + ilgili testleri çalıştır
5. Yan etkileri kontrol et → Başka bir şeyi bozdu mu?
6. Commit et → Fix: ... formatında
```

### Refaktör Yaparken
```
1. Mevcut durumu analiz et → Kod kalitesi sorunlarını listele
2. Önceliklendir → Kritik → Orta → Düşük
3. Birer birer düzelt → Aynı anda birden fazla şey değiştirme
4. Her adım sonrası test et → flutter analyze + flutter test
5. Commit et → Her adım ayrı commit
```

---

## 7. Karar Verme Rehberi

### Ne Zaman Soru Sorulur?
- Belirsizlik varsa → "X mi, Y mi?"
- Birden fazla doğru yol varsa → "Hangisi tercih edilir?"
- Kullanıcının tercihi gerekiyorsa → "Bu özellik nasıl görünsün?"

### Ne Zaman Soru Sormadan Yapılır?
- Tek doğru yol varsa → Direkt yap
- Kurallarda belirtilmişse → Kurallara uy
- Daha önce aynı şey yapıldıysa → Aynı şekilde yap
- Test edilebilir ve geri alınabilirse → Yap, sonra göster

### Risk Değerlendirmesi
| Risk | Aksiyon |
|---|---|
| Geri alınabilir (commit ile) | Yap |
| Test edilebilir | Yap, test et |
| Başka dosyaları etkiler | Önce sor |
| Güvenlik açığı yaratır | ASLA yapma |

---

## 8. Bağlam Yönetimi

### Oturum Başında
```
1. CLAUDE.md oku → Bu dosya (zaten otomatik okunur)
2. VIXREX_OTURUM_OZETI.md oku → Son durumu anla
3. flutter analyze çalıştır → Mevcut hataları gör
4. flutter test çalıştır → Test durumunu gör
```

### Oturum Sonunda
```
1. Yapılanları kaydet → VIXREX_OTURUM_OZETI.md'yi güncelle
2. Commit et → Değişiklikleri GitHub'a gönder
3. Kalanları listele → Gelecek oturum için not bırak
```

### Dosya Öncelik Sırası
| Dosya | Ne Zaman Okunur |
|---|---|
| `CLAUDE.md` | Her otomatik (zaten okunuyor) |
| `VIXREX_OTURUM_OZETI.md` | Oturum başında |
| `ANALIZ_RAPORU.md` | Teknik detay gerektiğinde |
| `VIXREX_UI_NOTLARI.md` | UI düzeltmesi gerektiğinde |
| `README.md` | Kurulum/başlatma gerektiğinde |

---

## 9. Kalite Standartları

### "Yeterli" Ne Demek?
- `flutter analyze` sıfır hata → Yeterli
- Tüm testler geçiyor → Yeterli
- Kod okunabilir → Yeterli
- Güvenlik açığı yok → Yeterli

### "Mükemmel" Ne Demek?
- Tüm testler geçiyor + coverage yüksek
- Dosyalar küçük ve anlamlı
- Tekrar eden kod yok
- Dokümantasyon güncel

### Pratik Yaklaşım
- Önce "çalışsın" → Sonra "temiz olsun"
- Kritik hataları düzelt → Kozmetik olanları sonra
- %80 mükemmel → %100 mükemmel için uğraşma

---

## 10. Sık Yapılan Hatalar

| Hata | Sonuç | Çözüm |
|---|---|---|
| `catch (_) {}` | Hata yutuluyor | `debugPrint` ile logla |
| Aynı kodu 2 yere yazma | Değişiklik unutulur | Merkezi fonksiyona taşı |
| Dosyayı bölmeme | Anlaşılması zor | 300 satırsa böl |
| Test yazmama | Hata bulmak zor | Her servise test yaz |
| Commit mesajı yazmama | Geçmiş anlaşılmaz | Conventional commit kullan |
| VIXREX_OTURUM_OZETI.md'yi güncelleme | Bilgi kopar | Her işlem sonrası güncelle |

---

## 11. Commit Mesajı Formatı

```
tip(değişiklik): kısa açıklama

Örnekler:
feat(yeni): randevu hatırlatma eklendi
fix(hata): giriş sayfası hatası düzeltildi
refactor(temizlik): AuthService Result<T>'ye geçirildi
test: legal_screen_test güncellendi
docs: README güncellendi
```

---

## 12. Kontrol Listesi (Her İşlem Sonrası)

- [ ] `flutter analyze` → sıfır hata?
- [ ] `catch (_) {}` var mı? → kaldır veya log ekle
- [ ] Dosya 300 satırı geçti mi? → böl
- [ ] Aynı kod başka yerde var mı? → merkezileştir
- [ ] Test çalıştırıldı mı? → çalıştır
- [ ] VIXREX_OTURUM_OZETI.md güncellendi mi? → güncelle
- [ ] Commit mesajı yazıldı mı? → yaz

---

## 13. İletişim Kalıpları

Teknik terim bilmeden nasıl prompt girilir:

| Siz Ne Dersiniz | Ben Ne Yaparım |
|---|---|
| "Aynı kod 2 yerde var" | Tek yere taşırım |
| "Hatalar yutuluyor" | Loglama eklerim |
| "Dosya çok uzun" | Parçalara bölerim |
| "X çalışmıyor" | Bulur ve düzeltirim |
| "Projeyi analiz et" | Sorunları listelerim |
| "Düzelt" | Çözerim |
| "Test et" | Çalıştırırım |
| "Commit et" | GitHub'a gönderirim |

---

## 14. Dosya Referansı

| Dosya | Amaç |
|---|---|
| `CLAUDE.md` | Bu dosya (kurallar + yapı) |
| `ANALIZ_RAPORU.md` | Teknik detaylı analiz |
| `VIXREX_OTURUM_OZETI.md` | Oturum notları, yapılan işlemler |
| `VIXREX_UI_NOTLARI.md` | UI düzeltme notları |
| `README.md` | Proje kurulumu ve kullanımı |

---

## 15. Örnek Senaryolar

### Senaryo 1: "Yeni bir servis ekle"
```
1. lib/services/ altına XService.dart oluştur
2. Result<T> pattern'ini kullan
3. SupabaseErrorMapper ile hata yönetimi
4. test/ altına XService_test.dart oluştur
5. flutter analyze çalıştır
6. flutter test çalıştır
7. Commit et: "feat(yeni): XService oluşturuldu"
8. VIXREX_OTURUM_OZETI.md'yi güncelle
```

### Senaryo 2: "Bu sayfa çalışmıyor"
```
1. İlgili screen dosyasını oku
2. Hatanın kaynağını bul (hangi satır, ne zaman)
3. Kök nedeni analiz et
4. Çözümü uygula (minimum değişiklik)
5. flutter analyze çalıştır
6. İlgili testleri çalıştır
7. Manually test et (gerekirse)
8. Commit et: "fix(hata): X sayfası düzeltildi"
9. VIXREX_OTURUM_OZETI.md'yi güncelle
```

### Senaryo 3: "Kod kalitesini artır"
```
1. flutter analyze çalıştır → Mevcut hataları gör
2. Büyük dosyaları tespit et → 300+ satır
3. Tekrar eden kodları bul → Aynı fonksiyon 2+ yerde
4. Önceliklendir → Kritik → Orta → Düşük
5. Birer birer düzelt
6. Her adım sonrası test et
7. Commit et: "refactor(temizlik): X düzeltildi"
8. VIXREX_OTURUM_OZETI.md'yi güncelle
```
