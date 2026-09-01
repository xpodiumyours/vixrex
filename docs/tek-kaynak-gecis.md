# Tek Kaynak Geçiş — PR7 + F0 Contract Freeze

## PR7 — Tamamlandı
- `owner_sessions` artık yalnız yetki (kısa ömürlü), konuşma `assistant_conversations`'ta.
- Eski `assistant_handoff` bir kez `migrate_handoff_to_conversation_once` ile taşınır, sonra `_migrated` işaretli.
- Yayında olmayan yerel taslak `LocalDraftMigrationService` ile kullanıcı onayıyla buluta aktarılır; çakışmada seçim yaptırılır.
- Ortak kaynak: `stores` (sahiplik), `store_working_drafts` (taslak), `owner_flow_states` (akış), `assistant_conversations/messages` (konuşma).
- Geri dönüş: migration'lar `supabase db reset` ile geri alınır, kod `feat/tek-kaynak-pr*` dallarında.

## F0 — Contract Freeze (2026-09-01) — KİLİTLENDİ
**Karar:**
- Flutter doğru, Next.js hizalanacak. Tek kaynak `shared/vitrin_alanlari.json` (46 alan, 6 zorunlu) + `supabase/migrations` korunacak. `VitrinFormSection` 5 akordeon (`Kimlik/İletişim/Konum ve saatler/Görseller/İçerik ve SEO` + `YasalYayinBolumu`) ve `SECTION_ORDER hero→contact` sırası donduruldu.
- Modal korunuyor: `AboutEditor/CampaignEditor/GalleryEditor/MarketplaceEditor` şimdilik modal kalacak (risk düşük). Backlog not edildi.
- Logo/GPS (logo, enlem/boylam, mahalle vb.) Next.js’e taşınacak; ürün ayrı kuyrukta.

**Backlog — TODO(F2b): modal → tek akordeon**
- `VitrinimEditor`’deki modal editörler tek ekranda 5 akordeona yayılacak. Şimdilik dondurmada kapsam dışı, ayrı PR’de taşınacak. Test `vitrin-field-schema-render.test.ts` şemadaki her kolonun `PUBLIC_STORE_SELECT`’te olduğunu kilitler.

**ADR — Ayrı kuyruk niye güvenli ve net?**
- Vitrin alanları (`store_working_drafts.draft_data` JSONB) ile ürünler (`products` tablosu, `product_storage_version=2`) farklı transaction/RLS’te. Tek kuyrukta ürün image upload takılsa tüm vitrin draft’ı bloklanır. Ayrı kuyruk: `queue:draft` (owner-draft) ve `queue:products` (products/reorder/image-upload) ayrı retry, ayrı kullanıcı mesajı (“Vitrin kaydedildi” vs “Ürün kuyrukta”). Debug net, destekte ayırmak kolay. Flutter’da da `ProductCatalogSyncService` ayrı.

**Kapsam dışı:** Yeni veri kaynağı/route açılmayacak, mevcut Supabase oturumu `/app`/`/kesfet`/`/app/profil` akışları korunacak.
