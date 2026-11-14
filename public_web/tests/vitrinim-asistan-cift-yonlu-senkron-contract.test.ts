import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

describe("Vitrinim <-> Asistan çift yönlü anlık senkron sözleşmesi", () => {
  const route = oku("app/api/owner-structured-field/route.ts");
  const editor = oku("components/owner/VitrinimEditor.tsx");
  const appPage = oku("app/app/page.tsx");

  it("structured-field route başarılı kayıt sonrası broadcastTaslakGuncellendi çağırır", () => {
    expect(route).toContain("broadcastTaslakGuncellendi");
    expect(route).toContain("broadcastTaslakGuncellendi(slug, clientId)");
  });

  it("VitrinimEditor 5 yapılandırılmış editöre onSaved geçirir ve canlı senkronu bağlar", () => {
    expect(editor).toContain("useCanliVitrinSenkron");
    expect(editor).toContain("AboutEditor");
    expect(editor).toContain("CampaignEditor");
    expect(editor).toContain("FaqEditor");
    expect(editor).toContain("MarketplaceEditor");
    expect(editor).toContain("GalleryEditor");
    expect(editor.match(/onSaved=/g)?.length ?? 0).toBeGreaterThanOrEqual(5);
  });

  it("app/page.tsx yedek bootstrap yolunda working_draft koruması bulunur", () => {
    expect(appPage).toContain("/api/owner-workspace/current");
    expect(appPage).toContain("draft_data");
    expect(appPage).toContain("magazaDetayiniGetir");
  });
});