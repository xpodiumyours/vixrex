# VixRex - Proje Rehberi

> Bu dosya HER otomatik okunur. Kurallara uymak zorunludur.
> Detaylı rehber için `.opencode/skills/SKILL.md` dosyasına bak.

---

## 1. Proje Özeti

**VixRex**, küçük işletmeler için dijital vitrin platformu.

| Katman | Teknoloji |
|---|---|
| İşletme uygulaması | Flutter/Dart |
| Public vitrin | Next.js/React |
| Veritabanı | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Deploy | Vercel |

---

## 2. Zorunlu Kodlama Kuralları

### Hata Yönetimi
- `catch (_) {}` KULLANMA → `if (kDebugMode) debugPrint(...)` ile logla
- Tüm servis metotları `Future<Result<T>>` dönmeli
- Async metodlarda `setState` öncesi `if (!mounted) return;` zorunlu
- Kullanıcıya Türkçe, anlaşılır hata mesajı gösterilmeli

### Kod Kalitesi
- Aynı fonksiyon 2 dosyada olamaz (DRY)
- Yeni dosyalar 300 satırı geçmemeli
- Kullanılmayan import olmamalı
- Her servise test yazılmalı

### Mimari
- Screen'de `Supabase.instance.client` kullanılmamalı
- Servislerde `Result<T>` pattern'ini kullan
- Controller'da iş mantığı, screen'de sadece UI

---

## 3. Yasaklar

| Yapma | Neden |
|---|---|
| `catch (_) {}` | Hata yutuluyor |
| `debugPrint` kDebugMode olmadan | Production'da log sızıntısı |
| `setState` sonrası `mounted` yoksa | Crash |
| Mevcut kodu silip yeniden yazma | İş mantığı kaybolur |
| Method imzasını değiştirip caller'ları unutma | Zincirleme hata |
| Test çalıştırmedan commit | Regression |
| Tek seferde 10+ dosya değiştirme | Hata bulmak zor |

---

## 4. İş Akışı

### Yeni Özellik
```
1. Mevcut durumu oku → 2. İlgili dosyaları oku (max 5) → 3. Planla
4. Uygula (mevcut kodu bozmadan) → 5. Test et → 6. Commit et
```

### Hata Düzeltme
```
1. Kaynağı bul → 2. Kök nedeni analiz et → 3. Minimum düzeltme
4. Test et → 5. Yan etkileri kontrol et → 6. Commit et
```

---

## 5. Kontrol Listesi (Her İşlem Sonrası)

- [ ] `flutter analyze` sıfır hata?
- [ ] `flutter test` tüm testler geçiyor?
- [ ] `if (!mounted) return;` eklendi mi?
- [ ] `try-catch` eklendi mi?
- [ ] `debugPrint` kDebugMode ile sarmalandı mı?
- [ ] Commit mesajı yazıldı mı?

---

## 6. Dosya Referansı

| Dosya | Amaç |
|---|---|
| `CLAUDE.md` | Bu dosya (kurallar) |
| `.opencode/skills/SKILL.md` | Detaylı geliştirme rehberi |
| `VIXREX_OTURUM_OZETI.md` | Proje durumu ve notlar |
| `README.md` | Kurulum ve kullanım |
