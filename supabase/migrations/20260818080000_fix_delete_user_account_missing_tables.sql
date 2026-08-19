-- delete_user_account()'ın eksik 2 tablosu (Casper isteği, 2026-08-18 —
-- hesap silme kaskadı yerelde uçtan uca test edilirken bulundu).
--
-- BULGU: aktif temel şemadaki delete_user_account() şu iki tabloya DELETE
-- deniyor ama HİÇBİRİ ne aktif migration zincirinde ne production'da
-- vardı (doğrulandı: supabase db dump --linked, 2026-08-18):
--   - article_reports → mağazası VE en az bir yazısı olan kullanıcının
--     hesap silme isteği hata verirdi. Ayrıca /api/report-abuse
--     (public_web/src/app/api/report-abuse/route.ts) bu tabloya doğrudan
--     INSERT yapıyor — "yazıyı bildir" butonu da aynı sebeple çalışmıyordu.
--   - legal_acceptance_events → mağazası olan HERHANGİ bir kullanıcının
--     hesap silme isteği hata verirdi (bu satıra ulaşan her satır bu
--     tabloya da uğruyor).
--
-- Kaynak: supabase_schema.sql (derlenmiş referans) — tanımlar ve
-- politikalar oradan alındı, store_articles ile aynı desen (article_
-- reports: herkes bildirebilir, yalnız admin görebilir; legal_
-- acceptance_events: yalnız service_role, istemciden hiç erişilmez).

CREATE TABLE IF NOT EXISTS "public"."article_reports" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "article_id" uuid NOT NULL REFERENCES "public"."store_articles"("id") ON DELETE CASCADE,
  "reason" text NOT NULL CHECK (length(btrim(reason)) > 0),
  "reporter_ip" text,
  "created_at" timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE "public"."article_reports" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can report articles" ON "public"."article_reports";
CREATE POLICY "Anyone can report articles" ON "public"."article_reports" FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can view reports" ON "public"."article_reports";
CREATE POLICY "Admins can view reports" ON "public"."article_reports" FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM "public"."admins" WHERE "admins"."user_id" = auth.uid())
);

-- ── Eksik tablo 2: legal_acceptance_events ──────────────────────────
-- delete_user_account() bu tabloya da DELETE yapmaya çalışıyordu, ne
-- aktif migration zincirinde ne production'da vardı (aynı doğrulama
-- yöntemiyle kontrol edildi). Yasal onay/izin olaylarının denetim izi —
-- yalnız sunucu tarafı (service_role) yazar/okur, istemciden hiçbir
-- yoldan erişilmez (bkz. 20260815210000_default_privileges_ve_audit_log.sql
-- yorumundaki aynı desen).
CREATE TABLE IF NOT EXISTS "public"."legal_acceptance_events" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "store_slug" text NOT NULL,
  "user_id" uuid,
  "event_type" text NOT NULL CHECK (
    event_type IN (
      'privacy_notice_acknowledged',
      'terms_accepted',
      'publication_consent_granted',
      'publication_consent_withdrawn'
    )
  ),
  "document_type" text NOT NULL,
  "document_version" text NOT NULL,
  "document_hash" text NOT NULL,
  "occurred_at" timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE "public"."legal_acceptance_events" ENABLE ROW LEVEL SECURITY;
-- Politika yok = anon/authenticated için varsayılan olarak tümü kapalı.
REVOKE ALL ON TABLE "public"."legal_acceptance_events" FROM anon, authenticated;
GRANT SELECT ON TABLE "public"."legal_acceptance_events" TO service_role;
