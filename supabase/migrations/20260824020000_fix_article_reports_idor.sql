-- ============================================================================
-- V-54 Fix: Article reports IDOR — validate article_id on INSERT
-- ============================================================================
-- SORUN: "Anyone can report articles" politikası WITH CHECK (true) ile
-- herhangi bir article_id (var olmayan, yayınlanmamış, silinmiş) için
-- rapor INSERT edilmesine izin veriyordu. Bu spam/bogus report riski yaratıyor.
--
-- ÇÖZÜM: Politika, article_id'nin store_articles'ta var olduğunu VE
-- published (status='published') olduğunu doğrulamalı.
-- Ayrıca reporter_ip'yi anon'dan alıp authenticated kullanıcıya zorunlu yapıyoruz.
-- ============================================================================

BEGIN;

-- ── 1) article_reports INSERT politikasını düzelt ──────────────────────────
DROP POLICY IF EXISTS "Anyone can report articles" ON "public"."article_reports";

CREATE POLICY "Anyone can report articles" ON "public"."article_reports"
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM "public"."store_articles" sa
      WHERE sa.id = article_reports.article_id
        AND sa.status = 'published'
    )
  );

-- ── 2) reporter_ip: anon INSERT'te zorunlu olsun (IP başına rate limit için)
-- authenticated kullanıcılar IP'yi manuel göndermez (report-abuse route.ts
-- zaten getClientIp ile alıp gönderiyor). Anon için zorunlu.
ALTER TABLE "public"."article_reports"
  ALTER COLUMN "reporter_ip" SET NOT NULL;

-- Eski satırlarda NULL olanları temizle (idempotent)
UPDATE "public"."article_reports"
SET "reporter_ip" = '0.0.0.0'
WHERE "reporter_ip" IS NULL;

-- ── 3) İndeks: rapor sorgularında article_id filtresi için ────────────────
CREATE INDEX IF NOT EXISTS "idx_article_reports_article_id"
  ON "public"."article_reports" ("article_id");

COMMIT;