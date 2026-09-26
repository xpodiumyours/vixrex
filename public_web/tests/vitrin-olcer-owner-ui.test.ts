import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const editor = readFileSync(resolve(__dirname, "../src/components/owner/VitrinimEditor.tsx"), "utf8");
const metrics = readFileSync(resolve(__dirname, "../src/components/owner/OwnerDashboardMetrics.tsx"), "utf8");
const route = readFileSync(resolve(__dirname, "../src/app/api/owner-dashboard/summary/route.ts"), "utf8");

describe("Vitrin Ölçer sahip yüzeyi", () => {
  it("ölçer yalnız mevcut vitrinde yönetim yüzeyine bağlanır", () => {
    expect(editor).toContain("store.is_published && !isCreationMode");
    expect(editor).toContain("<OwnerDashboardMetrics");
  });

  it("ham ziyaretçi kimliği sahip paneline taşınmaz", () => {
    expect(metrics).not.toContain("session_key");
    expect(route).not.toContain("session_key");
  });

  it("yorum moderasyonu sahip RPC'sine gider", () => {
    expect(metrics).toContain('supabase.rpc("set_product_comment_status"');
    expect(metrics).toContain('p_status: "hidden"');
  });

  it("şema deploy sırası geçici farklıysa mevcut pano çalışmaya devam eder", () => {
    expect(route).toContain("Vitrin Ölçer henüz hazır değil");
    expect(route).toContain("olcer,");
  });
});
