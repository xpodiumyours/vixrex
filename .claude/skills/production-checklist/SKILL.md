---
description: YALNIZCA RELEASE — günlük session/task'ta yükleme. Production'a çıkmadan önce çalıştır.
user-invocable: true
---

# Production Checklist

> **Yalnızca release.** Günlük vibe / bind / widget task'ta bu skill'i yükleme (token + hız).
> Her release öncesi bu listeyi tamamla. Eksik madde varsa release yapma.

---

## 1. Güvenlik

```
□ Supabase RLS politikaları test edildi
□ Store/vitrin_views şeması dökümante edildi
□ PII verileri maskeleme çalışıyor
□ KVKK silme fonksiyonu test edildi
□ OCR limiti sunucu tarafında
□ Service role anahtarı client-side'da değil
□ Rate limiting aktif
□ CORS policy doğru
```

## 2. Yasal Uyumluluk

```
□ Privacy Policy sayfası var
□ Terms of Service var
□ Cookie Policy var (eğer cookie kullanılıyorsa)
□ Kullanıcı veri silme endpoint'i çalışıyor
□ Aydınlatma metni mevcut
□ İletişim bilgileri tanımlı
```

## 3. UI Kalitesi

```
□ Tüm ekranlarda error/loading/empty state var
□ Görseller optimize edildi (1MB altı)
□ WhatsApp validasyonu çalışıyor
□ Dark mode uyumlu
□ Responsive (mobil + tablet + masaüstü)
□ Touch target minimum 44x44px
□ Skeleton loading tercih edildi
```

## 4. SEO & Performans

```
□ On-demand revalidation çalışıyor
□ Meta tag'ler tanımlı
□ Sitemap güncellendi
□ Robots.txt doğru
□ Core Web Vitals 80+ skor
□ Bundle split yapıldı
□ Görseller lazy load ediliyor
```

## 5. Entegrasyonlar

```
□ Supabase Auth çalışıyor
□ Storage upload çalışıyor
□ WhatsApp linkleri çalışıyor
□ QR kod üretimi çalışıyor
□ Push notification hazır (OneSignal)
□ Crash reporting aktif (Sentry)
```

## 6. Test

```
□ Unit test'ler geçiyor
□ Widget test'ler geçiyor
□ Manuel fonksiyon testi yapıldı:
  - Kullanıcı kaydı/giriş
  - Vitrin oluşturma/güncelleme
  - Galeri yükleme
  - Public vitrin bağlantısı
  - QR kod
  - Keşfet listesi
  - WhatsApp yönlendirme
  - Randevu oluşturma/takip
  - İşletme randevu yönetimi
```

## 7. Deploy

```
□ Vercel build başarılı
□ Custom domain çalışıyor
□ SSL sertifikası aktif
□ Environment variables tanımlı
□ Build cache temizlendi
□ Rollback planı hazır
```

## 8. Monitoring

```
□ Sentry error tracking aktif
□ Uptime monitoring aktif
□ Log monitoring aktif
□ Alert tanımlı (hata oranı eşiği)
□ Backup stratejisi hazır
```

---

## Kullanım

Release öncesi `/production-checklist` ile yüklenir. Her maddeyi tek tek kontrol et.

Eksik madde varsa, tamamlamadan release yapma.

---

*Bu skill production kalitesini garanti altına almak için zorunludur.*
