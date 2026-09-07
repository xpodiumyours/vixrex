# Tek Kaynak Geçiş — PR7 + F0 Contract Freeze

## PR7 — Tamamlandı
- `owner_sessions` artık yalnız yetki (kısa ömürlü), konuşma `assistant_conversations`'ta.
- Eski `assistant_handoff` bir kez `migrate_handoff_to_conversation_once` ile taşınır, sonra `_migrated` işaretli.
- Yayında olmayan yerel taslak `LocalDraftMigrationService` ile kullanıcı onayıyla buluta aktarılır; çakışmada seçim yaptırılır.
- Ortak kaynak: `stores` (sahiplik), `store_working_drafts` (taslak), `owner_flow_states` (akış), `assistant_conversations/messages` (konuşma).
- Geri dönüş: migration'lar `supabase db reset` ile geri alınır, kod `feat/tek-kaynak-pr*` dallarında.

## F0 — Contract Freeze (2026-09-01) — VERİ SÖZLEŞMESİ OLARAK KORUNUR
**Karar:**
- Tek veri kaynağı `shared/vitrin_alanlari.json` (46 alan, 6 zorunlu) + `supabase/migrations` olarak korunur. `VitrinFormSection` 5 akordeon (`Kimlik/İletişim/Konum ve saatler/Görseller/İçerik ve SEO` + `YasalYayinBolumu`) ve `SECTION_ORDER hero→contact` sırası veri/form sözleşmesi olarak korunur.
- Modal korunuyor: `AboutEditor/CampaignEditor/GalleryEditor/MarketplaceEditor` şimdilik modal kalacak (risk düşük). Backlog not edildi.
- Logo/GPS (logo, enlem/boylam, mahalle vb.) ortak veri sözleşmesinde kalır; ürün ayrı kuyrukta.

> 2026-09-07 düzeltmesi: Eski “Flutter doğru, Next.js hizalanacak” yaklaşımı UI için geçersizdir. İki ayrı renderer'ı görsel olarak birbirine benzetmek tek UI kaynağı değildir.

## F0-A — Tek UI Sahipliği (2026-09-07) — YENİ MİMARİ SINIR

**Uygulama kabuğunun tek sahibi Flutter'dır.** Android ve Flutter Web aynı ekran kaynağını kullanır:
- Vitrinim
- uygulama içi Keşfet
- Vixrex
- Profil
- kurulum ve yönetim ekranları

**Next.js'in tek sahibi olduğu yüzeyler:**
- ana sayfa / SEO girişleri
- public Keşfet ve kategori sayfaları
- public vitrin `/v/:slug`
- blog ve arama motorunun okuyacağı public içerik
- public vitrinin üzerinde çalışan sahip/asistan katmanı; bu katman yeni bir uygulama kabuğu değildir

**Geçiş kuralı:**
- `public_web/src/app/app/*` mevcut kullanıcıları bir anda kırmamak için geçici uyumluluk yüzeyidir.
- Bu dizinde yeni Flutter-parite ekranı geliştirilmez.
- Public web'den yeni uygulama girişleri yerel Next `/app` kopyasına değil `getAppUrl()` üzerinden Flutter Web'e gider.
- Next `/app/*` tamamen kaldırılmadan önce Next → Flutter oturum/hesap devamlılığı kanıtlanır; kullanıcıyı yeniden girişe veya sahipsiz vitrine düşürecek yönlendirme yapılmaz.
- Aynı ekranın Flutter ve Next.js'te ayrı ayrı yeniden çizilmesi kabul edilmez.

**Backlog — TODO(F2b): modal → tek akordeon**
- Bu iş yalnız Flutter uygulama kabuğunda devam eder. Next.js'te ikinci bir form/akordeon kopyası üretilmez.

**ADR — Ayrı kuyruk niye güvenli ve net?**
- Vitrin alanları (`store_working_drafts.draft_data` JSONB) ile ürünler (`products` tablosu, `product_storage_version=2`) farklı transaction/RLS'lerde. Tek kuyrukta ürün image upload takılsa tüm vitrin draft'ı bloklanır. Ayrı kuyruk: `queue:draft` (owner-draft) ve `queue:products` (products/reorder/image-upload) ayrı retry, ayrı kullanıcı mesajı (“Vitrin kaydedildi” vs “Ürün kuyrukta”). Debug net, destekte ayırmak kolay. Flutter'da da `ProductCatalogSyncService` ayrı.

**Kapsam dışı:** Bu ilk kesimde Next `/app/*` silinmez ve mevcut oturum akışı zorla taşınmaz. Önce yeni girişler tek UI'ye çevrilir; sonra oturum aktarımı çözülüp legacy yüzey kaldırılır.
