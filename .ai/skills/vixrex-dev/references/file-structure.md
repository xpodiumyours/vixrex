# VixRex Dosya Yapısı

## Flutter (lib/)

```
lib/
├── main.dart                    # Uygulama başlangıcı
├── config/
│   └── app_router.dart          # Sayfa yönlendirme (go_router)
├── controllers/                 # State management
│   ├── store_controller.dart
│   ├── product_controller.dart
│   └── booking_controller.dart
├── core/
│   └── ...                      # Temel yapı taşları
├── models/
│   ├── store_model.dart
│   ├── product_model.dart
│   └── booking_model.dart
├── repositories/                # Veri erişim katmanı
├── screens/                     # 25 ekran
│   ├── auth_screen.dart         # Giriş/Kayıt
│   ├── home_shell_screen.dart   # Ana iskelet
│   ├── my_vitrin_screen.dart    # Vitrin düzenleme
│   ├── ocr_scanner_screen.dart  # OCR tarama
│   ├── bulk_product_upload_screen.dart # Excel yükleme
│   ├── booking_management_screen.dart  # Randevu yönetimi
│   ├── explore_screen.dart      # Keşfet
│   ├── blog_editor_screen.dart  # Blog yönetimi
│   └── vixrex_onboarding_chat_screen.dart # AI asistan
├── services/                    # API servisleri
│   ├── supabase_service.dart
│   ├── storage_service.dart
│   └── push_notification_service.dart
├── theme/
│   └── app_colors.dart          # Renk paleti
├── utils/                       # Yardımcı fonksiyonlar
└── widgets/                     # Yeniden kullanılabilir bileşenler
```

## Next.js (public_web/)

```
public_web/
├── src/
│   ├── app/
│   │   ├── v/[slug]/            # Vitrin sayfası
│   │   ├── v/[slug]/randevu/    # Randevu alma
│   │   ├── layout.tsx           # Ana layout
│   │   └── page.tsx             # Ana sayfa
│   ├── components/              # React bileşenleri
│   └── lib/
│       └── supabase.ts          # Supabase client
├── public/                      # Statik dosyalar
├── next.config.ts
├── tailwind.config.ts
└── package.json
```

## Veritabanı

```
supabase_schema.sql — Tüm tablolar, indeksler, triggerlar, politikalar
```

Ana tablolar:
- `stores` — İşletme bilgileri (JSONB: products, gallery_items, product_categories)
- `vitrin_views` — Ziyaretçi takibi
- `bookings` — Randevular
- `notifications` — Bildirimler
