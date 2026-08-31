# Tek Kaynak Geçiş — PR7

- `owner_sessions` artık yalnız yetki (kısa ömürlü), konuşma `assistant_conversations`'ta.
- Eski `assistant_handoff` bir kez `migrate_handoff_to_conversation_once` ile taşınır, sonra `_migrated` işaretli.
- Yayında olmayan yerel taslak `LocalDraftMigrationService` ile kullanıcı onayıyla buluta aktarılır; çakışmada seçim yaptırılır.
- Ortak kaynak: `stores` (sahiplik), `store_working_drafts` (taslak), `owner_flow_states` (akış), `assistant_conversations/messages` (konuşma).
- Geri dönüş: migration'lar `supabase db reset` ile geri alınır, kod `feat/tek-kaynak-pr*` dallarında.
