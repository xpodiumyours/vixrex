---
name: vixrex-dev
description: >
  VixRex projesinde kod geliştirme, hata düzeltme, özellik ekleme.
  Kullanım: VixRex ile ilgili herhangi bir kod değişikliği, hata düzeltme,
  yeni özellik ekleme, veritabanı değişikliği, deployment, veya teknik
  karar gerektiğinde bu skill'i kullan.
---

# VixRex Geliştirme Kuralları

## Proje Özeti

Küçük işletmeler için dijital vitrin + müşteri yönetim platformu.

| Katman | Teknoloji | Amaç |
|--------|-----------|------|
| Yönetim Paneli | Flutter Web/Mobil | İşletme sahibi vitrini yönetir |
| Müşteri Vitrini | Next.js App Router | /v/:slug ile SEO uyumlu vitrin |
| Veritabanı | Supabase (PostgreSQL) | Veri + Auth + Storage |
| Deploy | Vercel (2 ayrı uygulama) | vixrex-app + vixrex-public |

## Kesinlikle Yapılmayacaklar

1. **Dosya silme** — rm, delete, silme komutu kullanma. Önce kullanıcıya sor.
2. **Toplu değişiklik** — Tek seferde 3'ten fazla dosya değiştirme.
3. **Veritabanı düşürme** — DROP TABLE, ALTER TABLE yapma.
4. **Otomatik deploy** — Vercel'e push etme. Önce local test.
5. **Plan olmadan kodlama** — Planı yaz, onay bekle, sonra uygula.

## Çalışma Akışı

```
1. Oku → İlgili dosyaları anla
2. Planla → 3-5 maddede ne yapacağını yaz
3. Onay Al → Kullanıcıya göster, "devam" de
4. Uygula → 1-2 dosya değiştir
5. Test Et → Çalıştığını doğrula
6. Onay Al → Sonucu göster
```

## Dosya Yapısı

Referans: `references/file-structure.md`

Önemli dizinler:
- `lib/screens/` — 25 ekran (Flutter)
- `lib/services/` — API servisleri
- `lib/models/` — Veri modelleri
- `public_web/src/` — Next.js kaynak kodu
- `supabase_schema.sql` — Veritabanı şeması (1783 satır)

## Veritabanı Kuralları

Referans: `references/database.md`

- Sadece `CREATE TABLE IF NOT EXISTS` kullan
- JSONB alanları: `products`, `gallery_items`, `product_categories`
- RLS aktif, politikaları `supabase_schema.sql`'e ekle
- Mevcut tabloları asla silme veya yeniden adlandırma

## Hata Durumunda

```bash
# Son değişiklikleri gör
git log --oneline -10

# Geri al
git revert <commit-hash>

# Asla yapma
git push --force
rm -rf
```

##Flutter Kuralları

- State management: Controller pattern (lib/controllers/)
- Routing: go_router (lib/config/app_router.dart)
- API: Supabase client (lib/services/)
- Tema: lib/theme/app_colors.dart

## Next.js Kuralları

- App Router kullan (src/app/)
- Tailwind CSS
- Supabase JS client (src/lib/)
- SEO: generateMetadata, sitemap.ts

## Prompt Kuralları

Kullanıcıya plan sunarken:
- 3-5 madde olsun
- Her madde 1 cümle
- Teknik terim kullanma
- "Ne yapacağım" de, "Nasıl yapacağım" değil

## Bu Dosyayı Kimler Okur

Bu dosya tüm AI araçları tarafından okunur:
- Cursor (.cursor/rules)
- GitHub Copilot (.github/copilot-instructions.md)
- Codex, Gemini, Claude (VIXREX_RULES.md)
