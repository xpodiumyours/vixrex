import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

const ownerActions = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
  "utf8",
);
const publishBar = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/components/PublishBar.tsx"),
  "utf8",
);
const publishRoute = readFileSync(
  resolve(__dirname, "../src/app/api/owner-publish/route.ts"),
  "utf8",
);
const legalGuardMigration = readFileSync(
  resolve(
    __dirname,
    "../../supabase/migrations/20260910001000_restore_publish_legal_guard.sql",
  ),
  "utf8",
);

function functionSlice(source: string, startMarker: string, endMarker: string): string {
  const start = source.indexOf(startMarker);
  const end = source.indexOf(endMarker, start + startMarker.length);
  expect(start).toBeGreaterThanOrEqual(0);
  expect(end).toBeGreaterThan(start);
  return source.slice(start, end);
}

describe("Vixrex Assistant yayın/yasal güvenlik kapısı", () => {
  it("serbest doğal dil yasal onay veya yayın işlemini doğrudan çalıştırmaz", async () => {
    for (const metin of [
      "Vitrini yayınla",
      "Şartları kabul ediyorum",
      "Yasal onayı ver ve yayınla",
    ]) {
      const sonuc = await handleVixrexNluMessage(metin);
      expect(sonuc.outcome, metin).not.toBe("handled");
      expect(sonuc.tumu, metin).toBeUndefined();
    }
  });

  it("serbest-metin gonder yolu yalnız taslak yazma kapısına gider", () => {
    const gonder = functionSlice(
      ownerActions,
      "const gonder = useCallback",
      "const alanAtla = useCallback",
    );

    expect(gonder).toContain('/api/owner-draft-batch');
    expect(gonder).not.toContain('/api/owner-publish');
    expect(gonder).not.toContain('/api/owner-accept-legal');
  });

  it("yasal onay yalnız kullanıcı checkboxı gerçekten işaretlediğinde çağrılır", () => {
    expect(publishBar).toMatch(/type="checkbox"[\s\S]*onChange=\{\(e\) => \{[\s\S]*if \(e\.target\.checked\) void onayVer\(\)/);
    expect(publishBar).toContain("Aydınlatma Metni");
    expect(publishBar).toContain("Kullanım Şartları");
    expect(publishBar).toContain("Açık Rıza Beyanı");
  });

  it("yayın düğmesi yasal onay yokken istemci tarafında kapalıdır", () => {
    expect(publishBar).toMatch(/disabled=\{[\s\S]*!yasalOnayli/);
  });

  it("sunucu yalnız publish_working_draft RPC'sine delege eder; yasal karar route metnine bırakılmaz", () => {
    expect(publishRoute).toContain('rpc("publish_working_draft"');
  });

  it("gerçek DB yayın kapısı üç yasal onayı yeniden zorunlu tutar", () => {
    expect(legalGuardMigration).toContain(
      "create or replace function public.assert_store_publish_ready(p_store jsonb)",
    );
    expect(legalGuardMigration).toContain("PRIVACY_NOTICE_REQUIRED");
    expect(legalGuardMigration).toContain("TERMS_ACCEPTANCE_REQUIRED");
    expect(legalGuardMigration).toContain("PUBLICATION_CONSENT_REQUIRED");
  });

  it("eski onayı yeni belgeye taşımaz; aktif sürüm ve hash birebir eşleşir", () => {
    expect(legalGuardMigration).toContain("from public.legal_documents d");
    expect(legalGuardMigration).toContain("d.document_type = 'privacy'");
    expect(legalGuardMigration).toContain("d.document_type = 'terms'");
    expect(legalGuardMigration).toContain("d.document_type = 'consent'");
    expect(legalGuardMigration.match(/d\.is_active = true/g)).toHaveLength(3);

    for (const hata of [
      "PRIVACY_NOTICE_VERSION_INVALID",
      "TERMS_VERSION_INVALID",
      "PUBLICATION_CONSENT_VERSION_INVALID",
    ]) {
      expect(legalGuardMigration).toContain(hata);
    }

    expect(legalGuardMigration).toContain(
      "d.version = p_store ->> 'privacy_notice_version'",
    );
    expect(legalGuardMigration).toContain(
      "d.content_hash = p_store ->> 'privacy_notice_hash'",
    );
    expect(legalGuardMigration).toContain(
      "d.version = p_store ->> 'terms_version'",
    );
    expect(legalGuardMigration).toContain(
      "d.content_hash = p_store ->> 'terms_hash'",
    );
    expect(legalGuardMigration).toContain(
      "d.version = p_store ->> 'publication_consent_version'",
    );
    expect(legalGuardMigration).toContain(
      "d.content_hash = p_store ->> 'publication_consent_hash'",
    );
  });
});
