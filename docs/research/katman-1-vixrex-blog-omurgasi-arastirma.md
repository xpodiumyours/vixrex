# Katman 1 Araştırma — Vixrex Blog Omurgası

Durum: **RESEARCH + UX-FIT başladı, BUILD başlamadı.**

Referans başlangıç: `main@95af697707e5f908b1f9b2aed95279f374557004`
Güvenli geri dönüş: `checkpoint/main-post-413-20260904`
Ana plan: `docs/kilitli-plan-blog-akilli-motor-dijital-carsi.md`

## 1. Mevcut gerçeklik — doğrulandı

### Vixrex blog yüzeyi
- `/blog` ve `/blog/[slug]` route'ları mevcut.
- Vixrex'in kendi yazıları `public_web/src/data/blogYazilari.ts` içinde kod verisi olarak tutuluyor.
- İki mevcut yazı taslak (`yayinda: false`).
- Hiç yayındaki Vixrex yazısı yoksa `/blog` bilinçli olarak 404 verir.
- Blog detay sayfasında canonical, OpenGraph, `BlogPosting` ve `BreadcrumbList` JSON-LD mevcut.
- Gövde `sanitizeHtml` üzerinden güvenli biçimde render ediliyor.
- Sitemap, Vixrex blog URL'lerini yalnız `blogYayindaMi()` true ise ekliyor.

### Esnaf blog sistemi
- Esnaf yazıları `store_articles` tablosunda tutuluyor.
- Canlı DB'de `store_articles` için 17 kolon, published index'i ve `(store_slug, slug)` unique index'i mevcut.
- Canlı tabloda araştırma anında 15 kayıt var.
- `store_slug` zorunlu; bu nedenle Vixrex'in platform blogunu bu tabloya sahte bir vitrinle bağlamak doğru değil.
- Public SELECT yalnız `status='published'`; owner CRUD politikaları ayrı.
- Vixrex platform yazıları için canlı DB'de ayrı merkezi blog tablosu yok. İlgili mevcut tablolar yalnız `store_articles` ve `article_reports`.

### Mevcut UX
- Blog liste sayfası mevcut Yardım sayfasıyla aynı `lp-*` tasarım tokenlarını kullanıyor.
- Mevcut liste `max-w-3xl` ve tek kolon kart listesi; küçük blog için uygun fakat günlük büyüyen büyük katalog hedefi için yeterli değil.
- Blog detay görünümü de `max-w-3xl`; okuma sayfası için uygun.
- `(site)/layout.tsx` içinde `SiteHeader` ve `SiteFooter` import ediliyor fakat render edilmiyor. Blog sayfasındaki "başlık ve altbilgi kendiliğinden geliyor" yorumu gerçek kodla uyuşmuyor.
- `SiteHeader` bileşeni mevcut ve Vixrex renk/token diline uyuyor; ancak global `(site)` layout'a yeniden eklemek Keşfet/landing davranışlarını etkileyebileceği için Katman 1'de global layout değişikliği güvenli kabul edilmedi.

## 2. Vixrex UX-FIT sonucu

Durum: **UYGUN AMA ŞARTLI**

Uygun olanlar:
- Mevcut Vixrex blog route'ları, tipografi, renk tokenları, kart/radius dili korunabilir.
- Blog detay sayfasının dar okuma genişliği korunmalı.
- Merkezi blog ana sayfası daha geniş katalog yüzeyine çıkarılabilir; bu mevcut Vixrex tasarım dilini bozmayı gerektirmiyor.
- Mevcut `SiteHeader` tasarım dili yeniden kullanılabilir.

Şartlar:
1. Büyük blog için liste sayfası `max-w-3xl` tek kolonda bırakılmamalı; masaüstünde daha geniş katalog düzeni gerekir.
2. Global `(site)/layout.tsx` değiştirilmemeli; blog için route-sınırlı shell/layout tercih edilmeli veya mevcut görünüm bilinçli korunmalı.
3. Blog detay sayfasındaki okuma genişliği genişletilmemeli; katalog genişliği yalnız liste/keşif yüzeyinde olmalı.
4. Yeni görsel dil icat edilmemeli; `lp-*` tokenları ve mevcut Vixrex CTA/kart desenleri kullanılmalı.

## 3. Veri modeli araştırması

### Seçenek A — `store_articles` kullanmak
**UYGUN DEĞİL.**
- `store_slug` zorunlu.
- Owner RLS/policy semantiği esnaf vitrini etrafında kurulmuş.
- Platform yazısı için sahte vitrin üretmek veri modelini bozar.

### Seçenek B — Kod dosyasında büyümeye devam etmek
**UYGUN DEĞİL.**
- Her yazı için kod commit/deploy gerekir.
- Günlük büyüme, 1000+ yazı, asistan sorgulaması ve ileride taksonomi için darboğaz oluşturur.

### Seçenek C — Ayrı merkezi platform blog tablosu
**ÖNERİLEN EN KÜÇÜK GÜVENLİ YAKLAŞIM.**

Katman 1 için minimum alanlar:
- `id`
- `slug` unique
- `title`
- `summary`
- `content`
- `cover_image_url`
- `status` (`draft` / `published`)
- `reading_minutes`
- `published_at`
- `created_at`
- `updated_at`

Katman 2'ye bırakılacak alanlar:
- sektör/kategori
- şehir/ilçe
- kullanım amacı
- etiketler
- provenance/kaynak sınıflandırması
- ilgili yazı ilişkileri

Bu ayrım Katman 1 kapsamının şişmesini engeller.

## 4. Güvenlik araştırması

Önerilen RLS davranışı:
- anon/authenticated: yalnız `status='published'` SELECT
- platform admin: taslak dahil yönetim
- public INSERT/UPDATE/DELETE yok

Mevcut `admins` altyapısı repoda var; daha önce privilege-escalation düzeltmeleri uygulanmış. Yeni merkezi tablo açılırsa admin yazma politikası mevcut güvenli admin modeline göre ayrıca doğrulanmalı.

Taslakların `/blog`, `/blog/[slug]`, sitemap ve metadata üzerinden sızmaması Katman 1 DoD'sinin zorunlu parçası.

## 5. Ölçek araştırması

- 1000+ yazı için Postgres tabanlı merkezi tablo teknik olarak uygun.
- Mevcut sitemap tek dosya kullanıyor. Google tek sitemap için 50.000 URL / 50 MB sınırı uyguluyor; Katman 1 hedefi bu sınırın çok altında. Daha ileri ölçekte sitemap index Katman 2+ konusu olabilir.
- Next.js sürümü `16.2.11`. Repo mevcut caching modelinde `unstable_cache` ve `revalidateTag` kullanıyor; merkezi blog sorguları aynı mevcut modelle uyumlu biçimde cache/revalidate edilebilir. Yeni cache mimarisi icat etmek Katman 1 için gereksiz.

## 6. SEO / yapılandırılmış veri doğrulaması

- Mevcut detay sayfasında `BlogPosting` JSON-LD zaten var ve korunmalı.
- Google, `Article` / `BlogPosting` yapılandırılmış verisinin sayfayı, başlık/tarih/yazar gibi bilgileri daha iyi anlamaya yardımcı olabileceğini belirtiyor; görünüm garantisi vermiyor.
- Yeni veri kaynağına geçerken canonical, published/modified dates ve JSON-LD davranışı korunmalı.

## 7. Dokunulacak yüzeyler — Katman 1 adayı

- Yeni Supabase migration: merkezi Vixrex blog tablosu + RLS + indexler
- `public_web/src/data/blogYazilari.ts` yerine/arkasına merkezi blog repository/data erişimi
- `public_web/src/app/(site)/blog/page.tsx`
- `public_web/src/app/(site)/blog/[slug]/page.tsx`
- `public_web/src/app/sitemap.xml/route.ts`
- Katman 1 testleri
- Gerekirse yalnız `/blog` altında route-sınırlı layout/shell

## 8. Dokunulmaması gereken yüzeyler

- `/v/[slug]` public vitrin
- `/v/[slug]/yazilar` esnaf blog görünümü
- `store_articles` mevcut şeması ve owner CRUD semantiği
- Vixrex Asistan 46 alan motoru
- Keşfet akışı
- Kirala/sahiplik akışı
- Flutter

## 9. Katman 1 için önerilen uygulama sırası

### 1.1 Veri omurgası
Yeni merkezi tablo + RLS + index + iki mevcut taslağın kontrollü taşınması.

### 1.2 Veri erişim katmanı
Yalnız published içerik public route'lara; taslak yönetimi public'ten ayrı.

### 1.3 Mevcut route geçişi
`/blog` ve `/blog/[slug]` kod dosyası yerine merkezi kaynaktan okunur. Canonical/JSON-LD/404 davranışı korunur.

### 1.4 Büyük blog liste UX'i
Vixrex tokenlarıyla geniş katalog görünümü; detay sayfası okuma genişliği korunur.

### 1.5 Sitemap + test + Preview
Taslak sızıntısı, published görünürlük, 404, metadata, sitemap ve mobil/masaüstü UX doğrulaması.

## 10. BUILD kapısı

Bu araştırma BUILD yetkisi değildir.

Kodlama başlamadan önce kullanıcıya şu karar sunulacak:
- **UYGUN:** devam
- **UYGUN AMA ŞARTLI:** şartlar kabul edilirse devam
- **UYGUN DEĞİL:** yeniden tasarla

Mevcut araştırma kararı: **UYGUN AMA ŞARTLI.**

Katman 1 için önerilen şartlar:
1. `store_articles` değiştirilmez.
2. Ayrı merkezi platform blog tablosu kullanılır.
3. Global site layout değiştirilmez.
4. Mevcut Vixrex `lp-*` tasarım dili korunur.
5. Taslak içerik hiçbir public yüzeyde görünmez.
6. Katman 2 taksonomisi Katman 1'e çekilmez.
