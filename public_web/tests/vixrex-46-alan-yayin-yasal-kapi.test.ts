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

  it("sunucu yayın sırasında yasal onayı DB seviyesinde yeniden denetler", () => {
    expect(publishRoute).toContain('rpc("publish_working_draft"');
    expect(publishRoute).toContain("PRIVACY_NOTICE_REQUIRED");
    expect(publishRoute).toContain("TERMS_ACCEPTANCE_REQUIRED");
    expect(publishRoute).toContain("PUBLICATION_CONSENT_REQUIRED");
    expect(publishRoute).toContain("PRIVACY_NOTICE_VERSION_INVALID");
    expect(publishRoute).toContain("TERMS_VERSION_INVALID");
    expect(publishRoute).toContain("PUBLICATION_CONSENT_VERSION_INVALID");
  });
});
