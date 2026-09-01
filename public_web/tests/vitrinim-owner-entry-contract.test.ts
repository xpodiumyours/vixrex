import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";
const oku = (path: string) => readFileSync(resolve(__dirname, path), "utf-8");
const sidebar = oku("../src/components/kesfet/KesfetYanMenu.tsx");
const page = oku("../src/app/vitrinim/page.tsx");
const client = oku("../src/app/vitrinim/VitrinimClient.tsx");
describe("Vitrinim Flutter eşitlik geçişi", () => {
  it("sidebar sahiplik çözücü rotaya gider", () => expect(sidebar).toContain('etiket: "Vitrinim", href: "/vitrinim"'));
  it("misafir sahip çerezini doğrular", () => {
    expect(page).toContain("verifyOwnerSession(");
    expect(page).toContain('"get_working_draft_for_session"');
    expect(page).toContain('.eq("id", ownerSession.storeId)');
  });
  it("hesaplı kullanıcı için mevcut paneli korur", () => expect(page).toContain('redirect("/app")'));
  it("mevcut manuel editörü kullanır", () => expect(client).toContain("<VitrinimEditor"));
});
