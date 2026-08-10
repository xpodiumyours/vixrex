# 0001 — VIXREX CORE: ortak omurga, uzman beyinler

## Durum

Kabul edildi (2026-08-10).

## Bağlam

Vixrex'in iki istemcisi var: Flutter (sahiplik/operasyon paneli) ve Next.js
(vitrin/public panel + "Vixrex Asistan" sohbet paneli). "Vixrex Asistan —
tek beyin, tek veri yolu" işi (Issue #91, Faz 1–5, `main`'e merge edildi)
sırasında bu iki istemcinin bazı alanlarda **gerçekten aynı işi iki kere
yaptığı** bulundu — en açık örnek: taslak güvenlik açığı (Faz 1), iki ayrı
RPC aynı "sırları temizle" mantığını bağımsız kopyalamıştı, biri
güncellenmiş biri unutulmuştu.

Bu bulgudan sonra soru şuydu: Flutter'ın rehberlik motoru
(`VixRexGuidanceService`) ile Next.js'in hazırlık motoru
(`vitrinReadiness.ts`) da aynı hastalığın bir örneği mi — yani "tek beyne"
indirilmesi mi gerekiyor?

Kullanıcının verdiği cevap ve bu ADR'nin temel kararı: **hayır, ikisi
farklı kategoride.** Bazı şeyler gerçekten tek yerde olmalı (omurga/core);
bazı şeyleri her istemcinin kendi uzmanlığına göre farklı yorumlaması
DOĞRU, hatta gerekli.

## Karar

```
VIXREX CORE
  sahiplik · yetki · veri modeli
  ürün · kategori · vitrin · yayın
  validasyon · audit log
        │
   ┌────┴────┐
   ↓         ↓
Flutter    Next.js
(operasyon) (vitrin/public)
```

**Kural:** iki istemci aynı çekirdek veriyi veya iş mantığını iki kere
YAZMAZ (aynı hesaplamayı, aynı doğrulamayı, aynı üretim algoritmasını
bağımsız olarak iki dilde yeniden icat etmez). Ama üstüne kurduğu
YORUM/SUNUM/CTA/akış farklı olabilir — olmalı bile, çünkü hedef kitleleri
farklı:

- **Flutter = işletme operasyonu uzmanı.** Toplu ürün ekleme, CSV/Excel
  içe aktarma, fotoğraf yükleme kuyruğu, kategori toplu düzenleme, sahiplik
  işlemleri, çevrimdışı/OCR akışları.
- **Next.js = vitrin sunumu uzmanı.** Tıkla-düzenle editörü, canlı önizleme,
  SEO/meta çıktısı, public URL, paylaşım görünümü.

"Aynı işi yapan 2 beyin" (örn. iki ayrı `ProductService`, iki ayrı slug
üretici) tehlikelidir — sessizce sapar, biri güncellenir diğeri unutulur.
"Aynı omurgayı kullanan 2 uzman beyin" (örn. ikisi de şemadaki `zorunlu`
alan listesini okur ama farklı CTA'lar gösterir) tehlikeli DEĞİLDİR, bu
zaten Vixrex'in amaçladığı mimari.

## Bugünkü kod ne durumda — denetim (2026-08-10)

Bu ilkeyle mevcut kod tarandı, üç bulgu:

1. **Zaten omurgadan besleniyor (iyi örnek):** Alan şeması
   (`public_web/src/lib/vitrinFieldSchema.ts` → `shared/vitrin_alanlari.json`
   → `lib/config/vitrin_alanlari.g.dart`, CI'da sapma kontrolüyle kilitli)
   ve "zorunlu alan" mantığı (`zorunluAlanlar`, her iki tarafta da şemadan
   türüyor — `public_web/src/lib/vitrinReadiness.ts`'teki `TEMEL_ALANLAR` ve
   Flutter'daki `lib/services/vixrex_profile_snapshot.dart`'taki
   `sonrakiEksikZorunluAlan`). Taslak sır temizleme de artık tek SQL
   fonksiyonunda (`strip_draft_secrets`, Faz 1). Bunlar omurga gibi
   davranıyor — değişmeyecek, örnek olarak referans alınacak.

2. **GERÇEK ihlal, bugün düşük etkili: slug üretimi iki kere yazılmış.**
   `lib/services/store_publish_slug_generator.dart` (`generateSlug`, Dart)
   ve `public_web/src/lib/products.ts` (`slugifyTR`, TypeScript) aynı
   algoritmayı bağımsız yeniden yazmış — ve zaten sapmışlar: TS sürümü
   `â/î/û` karakterlerini de normalize ediyor, Dart sürümü etmiyor. Etki
   bugün sınırlı çünkü Flutter YAZMA anında slug'ı belirleyip kaydediyor
   (`_resolveProductSlug`), Next.js SADECE okuyor ve önce kayıtlı
   `product.slug`'ı kullanıyor (`getProductUrlSlug`) — kendi algoritmasını
   yalnız slug'sız eski/legacy ürünlerde devreye sokuyor. Aktif çift-yazma
   yok ama tam yukarıdaki "iki ProductService" deseninin küçük bir örneği.
   **Karar: bu turda birleştirilmiyor** (Postgres'te tek kaynak mı yoksa
   cross-language contract test mi — ayrı bir tasarım kararı gerektirir).
   Gelecekte biri buna dokunacaksa: iki algoritmayı birleştirmeden önce bu
   ADR'ye bakıp aynı hataya düşmediğini doğrulasın.

3. **Henüz ihlal değil ama "core" şeklinde değil: SEO/şema üretimi.**
   `generateMetadata`/JSON-LD üretimi (`productJsonLd`, `breadcrumbJsonLd`)
   her Next.js sayfa dosyasında ayrı ayrı, ad-hoc yazılmış — merkezi bir
   `SeoService` yok. Flutter bugün public sayfa render etmediği için şu an
   kopya riski yok. **Karar: bu turda dokunulmuyor**, ama Flutter'ın public
   sayfa render eden bir özelliği (örn. önizleme) SEO/meta üretmeye
   başlarsa, önce merkezi bir modül tasarlanmalı — o zamana kadar ad-hoc
   kalması kabul edilebilir.

4. **Meşru uzmanlaşma olarak KALDI, birleştirilmedi:** Flutter'ın rehberlik
   motoru (`VixRexGuidanceService`, 405 satır) ile Next.js'in hazırlık
   motoru (`vitrinReadiness.ts`) FARKLI kavramlar. Flutter'ın 5 "kalite
   kalemi" (kapak, açıklama, galeri, katalog, kategori-görseli) şemadaki 7
   `kalite` alanıyla (Faz 5, Issue #101) birebir örtüşmüyor — örtüşmesi de
   gerekmiyor: galeri/katalog/kategori-görseli vitrin İÇERİK alanı değil,
   Flutter'a özgü OPERASYONEL durumlar (yükleme kuyruğu, kategori-şablon
   eşleşmesi). Ayrıca Flutter'ın `descriptionCompleted`'i şemanın kısa
   `description` (hero) alanına bakıyor, `hakkindaMetin` (kalite, uzun
   "hakkımızda" metni) alanına DEĞİL — ilk bakışta "aynı şey" sanılabilecek
   iki alan aslında farklı. Bu yüzden `kaliteAlanlari`'nı
   `VixRexGuidanceService.qualityItems()`'a bağlamak basit bir "listeyi
   değiştir" işi değil, hangi kalemin hangi şema alanına (veya hiçbirine)
   karşılık geldiğine dair ayrı bir tasarım kararı gerektirir. **Bilinçli
   olarak bu turda da yapılmadı** — Faz 5'in kendi sınırıyla aynı yerde
   duruyor.

## Sonuçlar

- Yeni bir çekirdek kavram (ürün, kategori, doğrulama kuralı, üretim
  algoritması — slug gibi) eklenirken önce şu soru sorulur: bu Flutter'a
  mı, Next.js'e mi, yoksa ikisine de mi ait? İkisine de aitse, TEK yerde
  yazılıp diğer tarafa oradan (şema/JSON üretim hattı, paylaşılan SQL
  fonksiyonu, ya da en azından bir cross-language contract test) taşınır —
  iki dilde bağımsız yeniden yazılmaz.
- Rehberlik/CTA/mesaj metni gibi SUNUM mantığı iki tarafta farklı
  olabilir; birleştirme zorlanmaz. Ölçüt: aynı ÇIKTI (aynı veri/karar) mı
  üretiliyor, yoksa aynı GİRDİYİ farklı yorumluyor mu? İkincisi meşrudur.
- Bu ADR'nin listelediği açık maddeler (slug birleşimi, SEO merkezileştirme,
  rehberlik motoru veri bağlama) kapatılmadı — bilinçli olarak gelecek işe
  bırakıldı. Biri bunlardan birine dokunacaksa önce burayı okusun.
