---
paths:
  - "lib/**/*.dart"
---

# Flutter Kod Stili

## Genel
- 2 boşluk girinti
- `const` constructor'ları tercih et
- Named parameters kullan
- Trailing commas ekle (formatting için)
- Dosya adı: `snake_case.dart`
- Class adı: `PascalCase`

## Async
- `await` işlemlerde `try-catch` kullan
- `mounted` kontrolü sonrası `setState`
- `Future.wait` ile parallel işlem yap

## Widget
- `StatelessWidget` tercih et (mümkünse)
- `Key` parametresi ekle
- `const` constructor kullan
- `build` metodunu temiz tut (max 50 satır)

## Hata Yönetimi
- `catch (_) {}` kullanma (boş catch yasağı)
- Kullanıcıya Türkçe hata mesajı göster
- Debug modda `debugPrint` ile log yaz
- `kDebugMode` kontrolü ile log yazdırma
