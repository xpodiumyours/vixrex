# VixRex — AI Geliştirme Kuralları

> Bu dosyayı okumadan hiçbir kod yazma. Bu dosya projenin anayasasıdır.

---

## Ne Bu Proje?

Küçük işletmeler için dijital vitrin + müşteri yönetim platformu.
- **Flutter Web/Mobil**: İşletme yönetim paneli
- **Next.js**: Müşteri vitrin sitesi (/v/:slug)
- **Supabase**: Veritabanı + Auth

## Teknoloji Yığını

- Flutter SDK ^3.7.2, Dart
- Next.js (TypeScript, App Router, Tailwind CSS)
- Supabase (PostgreSQL, Auth, Storage)
- Vercel'de iki ayrı uygulama olarak deploy

## ASLA YAPMA

1. **Dosya silme** — Hiçbir dosyayı, sayfayı, ekranı silme. Önce sor.
2. **Büyük değişiklik** — Tek seferde 3'ten fazla dosya değiştirme. Onay al.
3. **Veritabanı değişikliği** — DROP TABLE, ALTER TABLE yapma. Sadece CREATE IF NOT EXISTS.
4. **Deploy etme** — Vercel'e otomatik deploy yapma. Önce test et.
5. **Plan olmadan kodlama** — Önce planı yaz, onay bekle, sonra kodla.

## NASIL ÇALIŞ

1. **Oku**: İlgili dosyaları oku, projeyi anla
2. **Planla**: Ne yapacağını 3-5 maddede yaz
3. **Onay Al**: Kullanıcıya planı göster, onay bekle
4. **Küçük Yap**: 1-2 dosya değiştir, test et
5. **Onay Al**: Sonucu göster, devam et veya geri al

## Veritabanı Kuralları

- Tablolar: `stores`, `vitrin_views`, `bookings`, `products`
- JSONB alanları: `products`, `gallery_items`, `product_categories`
- RLS (Row Level Security) aktif
- Migrationları `supabase_schema.sql`'e ekle, asla silme

## Dosya Yapısı

```
lib/
├── config/        # Router, config
├── controllers/   # State management
├── core/          # Temel yapı taşları
├── models/        # Veri modelleri
├── repositories/  # Veri erişim
├── screens/       # Ekranlar (25 adet)
├── services/      # API servisleri
├── theme/         # Renkler, stiller
├── utils/         # Yardımcı fonksiyonlar
└── widgets/       # Yeniden kullanılabilir bileşenler

public_web/
├── src/app/       # Next.js sayfaları
├── src/components/# React bileşenleri
└── src/lib/       # Yardımcı fonksiyonlar
```

## Hata Durumunda

- Hata olursa: `git log --oneline -10` ile son değişiklikleri kontrol et
- Geri al: `git revert <commit-hash>`
- Asla force push yapma
- Asla `rm -rf` kullanma

## Önemli Notlar

- Flutter Web = İşletme paneli (sadece işletme sahibi görür)
- Next.js = Müşteri vitrin sitesi (herkes görür)
- İkisi ayrı deploy, ayrı domain
- Vercel redirect: /v/* → vixrex-public.vercel.app
