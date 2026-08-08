# VixRex — Durum

> Tek güncel durum belgesi. Eski plan/tur bulgusu dosyaları `docs/arsiv/`
> klasörüne kaldırıldı — geçmişe bakmak gerekirse orada durur, günlük işte
> kullanılmaz. Bundan sonra proje durumu **yalnız bu dosyada** tutulur.
> Her önemli değişiklikte bu dosya güncellenir.

---

## Giriş

VixRex, esnafın tek linkle dijital vitrin açmasını sağlıyor: Flutter
uygulaması kurulumu yapıyor, Next.js tarafı yayınlanan vitrini gösteriyor
ve sahibin düzenlemesine izin veriyor. Hedef: 100 hazır vitrin → kiralık →
satılık/B2B (bkz. hedef notu).

## Gelişme

- **İlk 13 adımlık plan tamamlandı ve yayına alındı.** (`docs/arsiv/implementation_plan.md`)
- Yayından sonra iki tur canlı test yapıldı, 18 bulgu çıktı; çoğu kapandı.
  (`docs/arsiv/canli-test-bulgulari-2026-08-06.md`,
  `docs/arsiv/tur-bulgulari-2026-08-06-aksam.md`)
- 6 Ağustos'ta geliştirme ortamı **yerelden canlı Supabase'e** geçti.
- Bugüne kadar `main`'e 64 PR indi.

## Sonuç — şu an açık olan / doğrulanması gereken

- **Sahip oturumu 15 dakikada düşüyor, yenilenmiyor.** (`ownerSession.ts`)
- **"İkinci vitrin yayınlanamıyor" düzeltmesi yazıldı**, canlı veritabanına
  gerçekten uygulandığı doğrulanmadı.
- **Vitrinler birbirine çok benziyor** (renk/düzen/logo aynı) — düzeltme
  bulunamadı.
- **`.env.local`'de görsel yükleme anahtarı hâlâ eski yerel test değeri**,
  canlı adresle uyuşmuyor — görsel yükleme bozuk çıkabilir.

---

*Son güncelleme: 2026-08-08.*
