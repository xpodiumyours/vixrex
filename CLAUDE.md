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

## 6. Mevcut Durum (2026-07-06)

### Tamamlananlar
- vitrinx → vixrex yeniden adlandırma
- God Widget/Object sorunları çözüldü
- Tüm servisler `Result<T>` pattern'ine geçirildi
- `_normalizeTurkish` tekrarı çözüldü
- `StoreLocalStorageService` optimize edildi
- `CLAUDE.md` kurallar dosyası oluşturuldu

### Kalanlar
- Büyük dosyaların bölünmesi (store_editor_controller 758 satır)
- Sessiz hata yutmalarının düzeltilmesi (15 yerde catch (_) {})
- Masaüstü layout sorunu
- Mascot düzeltmesi

---

## 7. Commit Mesajı Formatı

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

## 8. Kontrol Listesi (Her İşlem Sonrası)

- [ ] `flutter analyze` → sıfır hata?
- [ ] `catch (_) {}` var mı? → kaldır veya log ekle
- [ ] Dosya 300 satırı geçti mi? → böl
- [ ] Aynı kod başka yerde var mı? → merkezileştir
- [ ] Test çalıştırıldı mı? → çalıştır

---

## 9. Dosya Referansı

| Dosya | Amaç |
|---|---|
| `CLAUDE.md` | Bu dosya (kurallar + yapı) |
| `ANALIZ_RAPORU.md` | Teknik detaylı analiz |
| `VIXREX_OTURUM_OZETI.md` | Oturum notları, yapılan işlemler |
| `VIXREX_UI_NOTLARI.md` | UI düzeltme notları |
| `README.md` | Proje kurulumu ve kullanımı |

---

## 10. İletişim Kalıpları

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
