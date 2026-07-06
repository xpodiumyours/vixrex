# VixRex - Kod Kuralları

> Bu dosya her otomatik okunur. Bu kurallara uymak zorunludur.

---

## Zorunlu Kurallar

### 1. Hata Yönetimi
- `catch (_) {}` KULLANMA. En azından `debugPrint` ile logla.
- Tüm servis metotları `Future<Result<T>>` dönmeli.
- Hatalar servis katmanında yakalanmalı, ekrana `throw` fırlatılmamalı.
- Kullanıcıya Türkçe, anlaşılır hata mesajı gösterilmeli.

### 2. Kod Tekrarı (DRY)
- Aynı fonksiyon 2 dosyada olamaz.
- 3 benzer satır gördüysen, fonksiyona çevir.
- `lib/utils/` altına yardımcı fonksiyonları koy.

### 3. Dosya Boyutu
- Dosya 300 satırı geçerse böl.
- 500 satırı kesinlikle geçmemeli.
- Screen dosyalarını section'lara, servis dosyalarını helper'lara böl.

### 4. Servis Kalıbı
Yeni servis eklerken bu kalıbı kullan:
```dart
class XService {
  final SupabaseClient? _client;
  const XService({SupabaseClient? client}) : _client = client;
  SupabaseClient get _resolveClient => _client ?? Supabase.instance.client;

  Future<Result<T>> methodName() async {
    try {
      // ...
      return Result.success(data);
    } catch (e, s) {
      return Result.failure(SupabaseErrorMapper.map(e, s));
    }
  }
}
```

### 5. Test
- Yeni servis eklerken test de ekle.
- Mevcut testleri bozma.
- `flutter analyze` sıfır hata vermeli.

### 6. Import Kuralları
- Kullanılmayan import olmamalı.
- `supabase_flutter` sadece servis dosyalarında kullanılmalı.
- Screen dosyalarında doğrudan `Supabase.instance.client` kullanılmamalı.

### 7. Güvenlik
- Service role anahtarı istemci koduna eklenmemeli.
- Gerçek ortam değişkenleri Git'e gönderilmemeli.
- RLS politikaları devre dışı bırakılmamalı.

---

## Yasaklar

| Yapma | Neden |
|---|---|
| `catch (_) {}` | Hata yutuluyor, debug edilemez |
| `Supabase.instance.client` screen içinde | Test edilemez, katman ihlali |
| `throw Exception('msg')` serviste | Result<T> kullanmalısın |
| Dosya > 500 satır | Anlaşılması zor, bakım maliyeti yüksek |
| Aynı kod 2 dosyada | Değişiklik unutulabilir |

---

## Mevcut Yapı

```
lib/
  core/          → Result, SupabaseErrorMapper
  services/      → Tüm Supabase işlemleri (Result<T> döner)
  controllers/   → İş mantığı, state yönetimi
  screens/       → Sadece UI, iş mantığı yok
  widgets/       → Tekrar kullanılabilir UI bileşenleri
  utils/         → Yardımcı fonksiyonlar
  models/        → Veri modelleri
  config/        → Sabitler, yapılandırma
  repositories/  → Veri erişim soyutlaması (şimdilik boş)
```

---

## Commit Mesajı Formatı

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

## Kontrol Listesi (Her İşlem Sonrası)

- [ ] `flutter analyze` → sıfır hata?
- [ ] `catch (_) {}` var mı? → kaldır veya log ekle
- [ ] Dosya 300 satırı geçti mi? → böl
- [ ] Aynı kod başka yerde var mı? → merkezileştir
- [ ] Test çalıştırıldı mı? → çalıştır
