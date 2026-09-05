# Katman 4 — Vixrex Asistan Blog Komutları Araştırması

Durum: **RESEARCH TAMAMLANDI — UYGUN AMA ŞARTLI. BUILD YOK.**

Başlangıç: `feat/vitrine-yazi-cekme-katman-3@ec9e34bc507399502bbfa321c703a960a9e57447`
Araştırma branch'i: `research/asistan-blog-komutlari-katman-4`

## 1. Hedef

Mevcut 46 vitrin alanı motorunu değiştirmeden Vixrex Asistan'a ayrı bir blog eylem alanı eklemek:

- “vitrinime kuaförlerle ilgili bir yazı ekle”
- “Google’da görünürlükle ilgili yazı bul”
- “İzmir için uygun bir yazı öner”
- “bunu taslak olarak ekle”

Asistan yeni yazı üretmez, doğrudan yayın yapmaz ve Katman 3'te kurulmuş güvenli published → draft import hattını yeniden kullanır.

## 2. Mevcut gerçeklik — doğrulanan akış

### Next.js Asistan

`public_web/src/app/v/[slug]/hooks/useOwnerActions.ts` içinde kullanıcı hiçbir alan seçmeden mesaj gönderdiğinde akış doğrudan `handleVixrexNluMessage(metin)` çağrısına gider. Çözülen 46 alan `/api/owner-draft` üzerinden kaydedilir; mevcut “Doğru / Geri al” onay kartı, `router.refresh()` ve `vixrex-asistan-isliyor` davranışı bu hattın çevresindedir.

Sonuç: Blog komutunun en güvenli giriş noktası **46 alan NLU çağrısından hemen önce ayrı bir domain yönlendirmesi**dir. Blog komutu değilse mevcut kod aynı 46 alan hattına düşmelidir.

### 46 alan NLU

`public_web/src/lib/vixrexNluPipeline.ts` yalnız `VIXREX_NIYET_SOZLUGU` alanlarını çözer. Kalıcı `assistant_conversations.pending_slot` yapısı da `{anahtar, etiket, tip}` biçiminde vitrin alanı netleştirmesi için kullanılır.

Sonuç: Blog komutları mevcut 46 alan sözlüğüne veya `pending_slot` içine karıştırılmamalıdır.

### Flutter Asistan

`lib/widgets/vixrex/vixrex_companion_chat.dart` içindeki `_gonder()` da aynı ürün mantığında önce alan NLU/pending alan çözümüne gider. Katman 4 Flutter tarafında da blog domain yönlendirmesi mevcut alan NLU'sunun önünde ve fail-safe fallback ile kurulabilir.

## 3. Katman 3'ten hazır olan güvenli işlem

Yeni import backend'i gerekmiyor.

- Next.js: `/api/articles/import-vixrex`
- Flutter: `ArticleService.importVixrexBlogArticle`
- DB: `import_vixrex_blog_article_to_store`

DB tekrar hedef vitrin yetkisini doğruluyor, yalnız `published` merkezi yazıyı kabul ediyor, sonucu daima `draft` oluşturuyor ve aynı kaynak/vitrin çiftinde idempotent davranıyor.

Katman 4 yalnız **bulma → seçme → açık kullanıcı onayı → mevcut import hattını çağırma** katmanı olmalıdır.

## 4. Merkezi kütüphane ve sınıflandırma kaynakları

Yeni sektör/konu/şehir sözlüğü kurmaya gerek yok.

### Konu ve amaç

Kanonik kaynak: `shared/blog_taxonomy.json`.

7 konu:

1. `google-yerel-gorunurluk`
2. `dijital-vitrin-web`
3. `urun-hizmet-fiyat`
4. `musteri-iletisim-satis`
5. `randevu-isletme-yonetimi`
6. `vixrex-kullanimi`
7. `dijital-carsi-baglantilar`

7 amaç:

1. `gorunurluk-artirma`
2. `musteri-kazanma`
3. `guven-artirma`
4. `iletisim-satis`
5. `isletme-yonetimi`
6. `vixrex-kullanimi`
7. `yerel-isbirligi`

### Sektör

Kanonik kaynak: `shared/business_categories.json`.

Next.js `resolveBusinessCategory`, Flutter `resolveBusinessCategoryId` aynı 19 kategori sözleşmesini ve alias'ları kullanıyor. Katman 4 yeni sektör listesi üretmemelidir.

### Konum

Next.js'te `public_web/src/lib/turkeyCities.ts`, Flutter'da `lib/config/turkey_cities_config.dart` mevcut 81 il/ilçe eşlemesini taşıyor. Örnek olarak İzmir = `35`.

Katman 4 bu mevcut eşlemeleri kullanabilir; konum datasını collateral refactor ile yeniden tasarlamamalıdır.

## 5. Merkezi yazının kullanılabilir metadata'sı

`vixrex_blog_articles` şu seçim sinyallerini zaten taşıyor:

- `primary_topic`
- `purpose`
- `sector_ids`
- `location_scope`
- `province_codes`
- `district_targets`
- `tags`
- `status`
- `published_at`

`district_targets` biçimi admin doğrulamasında `{ province_code, district_name }` olarak sabitlenmiş durumda.

Canlı DB'de araştırma anında iki merkezi yazı var ve ikisi de hâlâ `draft`; public/Asistan seçimine girecek `published` yazı sayısı 0. Bu durum Katman 4 kod tasarımını engellemiyor fakat final E2E öncesinde en az bir merkezi yazının kontrollü yayınlanması gerekecek.

## 6. Mevcut kütüphane seçim davranışının sınırı

Mevcut Blog Yönetimi kütüphanesi `status='published'` yazılardan son 20 kaydı getiriyor. Konu/sektör/konum uygunluğuna göre bir öneri sıralaması yapmıyor.

Sonuç: Asistan için “uygun yazı seçimi”ni varmış gibi kabul etmek yanlış olur. Katman 4'te ayrıca deterministik bir seçim sözleşmesi gerekir.

## 7. Önerilen deterministik seçim modeli

AI/fuzzy karar yerine makine-okur metadata kullanılmalı.

1. Kaynak yalnız `published` olur.
2. Kullanıcı açık konu veya amaç söylediyse bunlar kanonik ID'ye çözülür ve **zorunlu eşleşme** olur.
3. Kullanıcı sektör söylediyse o sektöre özel yazılar genel (`sector_ids=[]`) yazılardan önce gelir; ikisi de aday olabilir.
4. Kullanıcı il/ilçe söylediyse tam ilçe > tam il > `national` sırası uygulanır; uygun olmayan başka il/ilçe yazısı aday olmaz.
5. Kullanıcı sektör/konum söylemediyse mevcut vitrinin kanonik sektör ve konumu yalnız sıralama yardımı olarak kullanılabilir; kullanıcının açık kriterinin önüne geçmez.
6. Serbest ve belirsiz kelimelerde görünmez tahmin yapılmaz; tanınan konu/amaç/sektör/konum yoksa Asistan netleştirme sorar.
7. Eşit uygunlukta son deterministik bağlayıcı `published_at desc` olur.
8. Kullanıcıya en fazla 3 aday gösterilir; yüzlerce yazı sohbet içine dökülmez.

Bu sıralamanın Flutter ve Next.js'te iki ayrı algoritma olarak kopyalanması yerine **tek bir read-only seçim sözleşmesinin/RPC'nin** iki istemci tarafından kullanılması daha güvenlidir. Böylece tek veri + tek seçim davranışı korunur.

## 8. Niyet domain'i — 46 alanla çakışmama

Blog domain yalnız açık blog nesnesi + blog eylemi varsa devreye girmelidir.

Blog nesnesi örnekleri: `blog`, `blog yazısı`, `yazı`, `makale`, `rehber`.
Blog eylemi örnekleri: `bul`, `öner`, `ekle`, `taslak`, `kısa sürüm`, `uyarlanabilir`.

Örneğin “tanıtım yazısını değiştir” mevcut vitrin alanı komutudur; `değiştir` blog eylemi olmadığı için blog domain'ine kaçmamalıdır.

Blog resolver sonucu `not_blog` ise çağıran hiçbir yan etki üretmeden mevcut `handleVixrexNluMessage` / Flutter alan NLU hattına aynen devam etmelidir.

## 9. Çok turlu konuşma ve kalıcı seçim problemi

Next.js hızlı cevap payload'ları yalnız oturum belleğinde tutuluyor; DB'de mesaj metni kalıcı olsa da hızlı cevap payload'ı kalıcı değil. Bu nedenle:

`“Google görünürlüğüyle ilgili yazı bul” → yazı önerildi → sayfa yenilendi → “bunu taslak olarak ekle”`

akışı yalnız UI belleğine bırakılamaz.

Mevcut `pending_slot` da 46 alan netleştirmesine aittir ve blog için kullanılmamalıdır.

En küçük güvenli çözüm: `assistant_conversations` içinde **ayrı `pending_blog_action` JSON durumu** ve dar get/set RPC'leri. Durum yalnız blog domain'ine ait olur; örneğin hedef store bağlamı, en fazla 3 aday ID'si, seçilen kaynak ID'si ve beklenen aşama tutulur. Import anında bu hafızaya güvenilmez; Katman 3 owner/import yetkisi tekrar çalışır.

## 10. Onay UX'i

Planın “kullanıcı hangi yazının seçildiğini ve ne olacağını bilmeden işlem yok” kuralı nedeniyle ilk “ekle” cümlesi doğrudan DB yazımı için yeterli değildir; kullanıcı henüz seçilecek merkezi yazıyı görmemiştir.

Güvenli sohbet akışı:

`komut → uygun yazı(lar) → başlık/özet göster → kullanıcı yazıyı seçer → Kısa sürüm / Uyarlanabilir taslak modu seçilir → Asistan hangi yazıyı hangi modda taslak ekleyeceğini tekrar açıkça gösterir → kullanıcı onaylar → Katman 3 import çağrılır`

Hiçbir `bul/öner` adımı write yapmaz. Mod da görünmez varsayılan seçilmez.

Mevcut `ChatBubble` hızlı cevap düğmeleri bu UX için yeterlidir; yeni Asistan ekranı veya yeni modal gerekmiyor.

## 11. Feature-flag gerçeği

Canlı DB'de `feature_flags` altyapısı var. Araştırma anındaki flag'ler arasında `blog_enabled=true` var fakat **Asistan blog komutlarına özel flag yok**.

Flutter'da `FeatureFlagService` ve `get_feature_flags` RPC kullanımı için servis mevcut; servis yüklenemezse default değere düşüyor. Next.js owner Asistan tarafında eşdeğer aktif bir feature-flag adapter'ı doğrulanmadı.

Katman 4 için mevcut genel `blog_enabled` flag'ini geniş anlamda kullanmak güvenli değil; bu flag tüm blog özelliğini temsil ediyor. En dar kapı ayrı `assistant_blog_commands` flag'idir.

Öneri: yeni flag **default false** oluşturulur. Flag false/yüklenemiyor ise blog resolver hiç çalışmaz ve mevcut 46 alan davranışı aynen devam eder. Böylece rollout geri dönüşü migration/rollback gerektirmeden yapılabilir.

## 12. Güvenlik ve regresyon sınırları

- Blog önerisi yalnız owner Asistan bağlamında çalışır.
- Öneri read-only olsa da gerçek yazım yalnız mevcut Katman 3 import API/RPC'si üzerinden yapılır.
- `sourceArticleId`, hedef slug ve mode tekrar doğrulanır.
- `published` kontrolü DB'de yeniden yapılır.
- Direkt `published` üretme yolu eklenmez.
- `store_articles` için yeni ikinci yazma yolu açılmaz.
- 46 alan `shared/vixrex_niyet_sozlugu.json` değiştirilmez.
- 46 alan `pending_slot` anlamı değiştirilmez.
- `OwnerAssistantPanel`, `useFieldSelection` ve `vixrex-asistan-isliyor` compaction/işlem davranışı korunur.
- Yeni ayrı Asistan ekranı kurulmaz.
- Katman 5 Dijital Çarşı bu BUILD'e girmez.

## 13. Teknik VERIFY planı

Katman 4 BUILD onaylanırsa teknik kapı en az şunları kanıtlamalıdır:

- feature flag OFF → mevcut 46 alan blog öncesi davranışına düşer
- mevcut 46 alan NLU contract/baseline testleri yeşil
- blog domain komutları 46 alan sözlüğüne eklenmemiş
- belirsiz komut write üretmiyor
- taslak/draft merkezi yazı önerilemiyor/import edilemiyor
- seçim state'i ayrı `pending_blog_action`; `pending_slot` değişmiyor
- sayfa yenilemesi/cihaz değişimi sonrasında seçilen blog bağlamı kaybolmuyor
- kullanıcı onayı olmadan import RPC çağrılmıyor
- import yalnız Katman 3 yolundan ve daima draft
- duplicate/idempotency korunuyor
- Next.js + Flutter aynı seçim sonucu/sözleşmesini kullanıyor
- TypeScript, production build, değişen Dart format/analyze ve gerçek DB allow/deny testleri yeşil
- gerçek kullanıcı ekran kabul testi bu katmanda yapılmıyor; plan gereği Katman 1–5 final E2E'de yapılacak

## 14. BUILD öncesi önerilen LOCK şartları

Aşağıdaki maddeler kullanıcı onayı olmadan kilitli sayılmaz ve BUILD başlamaz:

1. Katman 4 ayrı `assistant_blog_commands` feature flag'iyle gelir; başlangıç değeri false.
2. Blog intent ayrı domain olur; mevcut 46 alan niyet sözlüğü/pipeline'ı değiştirilmez.
3. Blog domain yalnız açık blog nesnesi + blog eylemi veya mevcut `pending_blog_action` bağlamında devreye girer; aksi halde eski 46 alan hattına birebir fallback olur.
4. Konu/amaç `shared/blog_taxonomy.json`, sektör `shared/business_categories.json`, konum mevcut 81 il/ilçe kaynaklarından çözülür; yeni paralel taksonomi kurulmaz.
5. İnsan dilindeki blog konu/amaç eşanlamları gerekiyorsa yeni ID üretmek yerine mevcut kanonik blog taxonomy kayıtlarına alias olarak eklenir.
6. Merkezi öneri yalnız `published` içerikten yapılır ve Flutter/Next.js için tek deterministik read-only seçim sözleşmesi kullanılır.
7. Seçim sırası: açık konu/amaç zorunlu; sektör özel > genel; konum ilçe > il > national; son bağlayıcı published_at; en fazla 3 aday.
8. Tanınmayan/belirsiz kriterde görünmez tahmin veya write yok; netleştirme sorusu var.
9. Çok turlu “bunu” bağlamı mevcut 46 alan `pending_slot`'una değil ayrı `pending_blog_action` durumuna yazılır.
10. Kullanıcı seçilen yazıyı ve import modunu görmeden import yapılmaz; `linked_excerpt` ve `adaptable_draft` arasında gizli varsayılan yoktur.
11. Gerçek write yalnız Katman 3 `/api/articles/import-vixrex` / aynı DB RPC üzerinden yapılır; sonuç daima draft ve owner yetkisi DB'de tekrar doğrulanır.
12. Mevcut Vixrex Asistan paneli/ChatBubble/işlem-compaction davranışı yeniden kullanılır; yeni Asistan ekranı kurulmaz.
13. Flutter ve Next.js davranış paritesi teknik contract testine bağlanır; feature flag off parity ve PR #413 Asistan regresyonları zorunlu VERIFY kapısı olur.
14. Katman 4'te ekran kabul testi yapılmaz; Katman 5 tamamlandıktan sonra tek final E2E uygulanır.

## 15. Araştırma sonucu

**UYGUN AMA ŞARTLI.**

Katman 3'te gereken güvenli import omurgası zaten var. Katman 4 için temel eksikler yeni yazma altyapısı değil; ayrı blog intent yönlendirmesi, deterministik merkezi seçim, kalıcı çok-turlu blog hafızası ve dar rollout flag'idir.

Bu 14 şart LOCK olmadan BUILD başlamamalıdır.