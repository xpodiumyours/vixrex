import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Faz D3 (Tek Asistan planı, 2026-09-02) — kiralanan bir şablon ilk kez
 * açıldığında otomatik doldurmanın gerçekten tetiklenmesi.
 *
 * Sinyal: get_working_draft_for_session'ın `created` alanı — bu taslak
 * İLK KEZ şu çağrıda oluşturulduysa true. Kiralanan şablonda kategori
 * zaten dolu; sıfırdan kurulumda kategori boş olduğu için otomatikDeger()
 * null döner ve hiçbir şey olmaz — aynı sinyal iki senaryoda da doğru
 * çalışır, ayrı bir "bu bir kiralama mı" kontrolü gerekmez.
 */
describe("draft.created sinyali OwnerAssistantPanel'e kadar taşınır", () => {
  const shell = oku("app/v/[slug]/OwnerWorkspaceShell.tsx");
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("OwnerWorkspaceShell draft.created'ı draftYeniOlusturuldu olarak geçirir", () => {
    expect(shell).toContain("draftYeniOlusturuldu={Boolean(draft?.created)}");
  });

  it("OwnerAssistantPanel yalnız kategori doluyken ve bir kez tetikler", () => {
    expect(panel).toContain("if (!draftYeniOlusturuldu || otomatikDoldurmaBasladiRef.current) return;");
    expect(panel).toContain("otomatikDoldurmaBasladiRef.current = true;");
  });
});

describe("otomatik doldurma yalnız BOŞ alanları doldurur, otomatikDoldurulabilir dışını asla yazmaz", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("VITRIN_FIELDS'ten yalnız otomatikDoldurulabilir + görsel-olmayan alanlar seçilir", () => {
    expect(panel).toContain(
      "(alan) => alan.otomatikDoldurulabilir && alan.tip !== \"gorsel\""
    );
  });

  it("mevcut değer doluysa alan atlanır — üzerine yazmaz", () => {
    expect(panel).toContain(
      'if (typeof mevcut === "string" && mevcut.trim().length > 0) continue;'
    );
  });

  it("mevcut owner-draft yazma yolunu kullanır — yeni bir API icat edilmedi", () => {
    expect(panel).toContain('fetch("/api/owner-draft"');
    expect(panel).toContain("taslakClientId()");
  });

  it("en az bir alan hazırlandıysa asistan yaptığı işi tek satırda bildirir", () => {
    expect(panel).toContain("hazirlananEtiketler.length > 0");
    expect(panel).toContain("${hazirlananEtiketler.length} alan kategorine göre dolduruldu.");
  });

  it("rapor tek cümledir — işaretli liste ve yönlendirme metni dökülmez", () => {
    expect(panel).not.toContain("Şimdi senden gerçek bilgiler almam gerekiyor");
    expect(panel).not.toContain('[{ label: "Başlayalım", payload: "ilk_eksik_alana_git" }]');
  });

  it("hiçbir alan hazırlanmadıysa (kategori boş/sıfırdan kurulum) sessiz kalır — yalan mesaj yazmaz", () => {
    // hazirlananEtiketler.length > 0 kontrolü olmadan mesajEkle çağıran koşulsuz bir dal yok.
    const otomatikBlok = panel.slice(
      panel.indexOf("otomatikDoldurmaBasladiRef"),
      panel.indexOf("// Faz E (Tek Asistan planı")
    );
    const mesajEkleCagrilari = (otomatikBlok.match(/mesajEkle\(/g) ?? []).length;
    expect(mesajEkleCagrilari).toBe(1); // yalnız hazirlananEtiketler.length>0 dalında
  });
});
