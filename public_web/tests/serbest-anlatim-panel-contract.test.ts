import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Serbest metinle alan doldurma (2026-09-02) — "esnaf 46 alanı tek tek
 * dolaşmasın" isteğinin panel bağlantısı. Kaynak-dizge sözleşme testleri,
 * faz-d3-otomatik-doldurma-tetigi.test.ts ile aynı üslup.
 */
describe("Serbest anlatım kartı — panel açılınca, tek-tek soru akışından önce doğrudan görünür", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("yalnız zorunlu alan eksikken ve oturum başına bir kez tetiklenir", () => {
    expect(panel).toContain(
      "if (!acik || anlatimSunulduRef.current || rapor.temelTamam) return;"
    );
    expect(panel).toContain("anlatimSunulduRef.current = true;");
    expect(panel).toContain("setAnlatimAcik(true);");
  });

  it("bir sohbet balonu + tıklama aracılığıyla DEĞİL, doğrudan görünür — göz zıplamasın diye", () => {
    // StepCard'ın 2026-08-22'de kaldırılma sebebiyle aynı hataya
    // düşülmediğinin kanıtı: davet mesajı için mesajEkle çağrısı yok.
    const idx = panel.indexOf("anlatimSunulduRef.current = true;");
    const efektSonu = panel.indexOf("}, [acik, rapor.temelTamam]);");
    const efektBlok = panel.slice(idx, efektSonu);
    expect(efektBlok).not.toContain("mesajEkle(");
  });

  it("'tek tek sor' çıkışı zaten var olan ilk_eksik_alana_git payload'ını kullanır — ayrı bir atlama mekanizması icat edilmedi", () => {
    expect(panel).toContain('if (payload === "ilk_eksik_alana_git")');
    expect(panel).toContain('handleHizliCevap("ilk_eksik_alana_git")');
  });
});

describe("Auto-select efekti serbest anlatım kartı açıkken ilerlemiyor", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("koruma koşulu anlatimAcik içerir", () => {
    expect(panel).toContain("if (!acik || seciliAlan || anlatimAcik) return;");
  });
});

describe("Serbest anlatım gönderimi — mevcut alan yazma yolunu kullanır, yeni API icat edilmedi", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("GPS ile aynı /api/owner-draft + taslakClientId zinciri", () => {
    expect(panel).toContain("serbestMetindenAlanlariCikar(metin)");
    expect(panel).toContain('fetch("/api/owner-draft"');
    expect(panel).toContain("taslakClientId()");
  });

  it("başarılı alanlar setAlan ile yerel taslağa yazılır", () => {
    expect(panel).toContain("basarili.forEach(({ kolon, deger }) => setAlan(kolon, deger));");
  });

  it("hiçbir şey çıkarılamazsa dürüstçe söyler — asla 'işledim' demez", () => {
    expect(panel).toContain("net bir bilgi çıkaramadım");
  });

  it("özet mesajı asla işletme adını doldurduğunu iddia etmez", () => {
    const idx = panel.indexOf("Anlattıklarından şunları anladım");
    expect(idx).toBeGreaterThan(-1);
    const ozetBlok = panel.slice(idx, idx + 300);
    expect(ozetBlok).not.toContain("işletme adını");
    expect(ozetBlok).toContain("İşletme adın gibi birkaç şeyi de senden almam gerekiyor");
  });
});

describe("IsletmeniAnlatKarti bileşeni", () => {
  const bilesen = oku("app/v/[slug]/components/IsletmeniAnlatKarti.tsx");

  it("düşük sürtünmeli bir 'tek tek sor' çıkışı var — asla zorlamaz", () => {
    expect(bilesen).toContain("Tek tek sormanı istiyorum");
    expect(bilesen).toContain("onVazgec");
  });

  it("boş/çok kısa girişte gönder pasif kalır", () => {
    expect(bilesen).toContain("MIN_UZUNLUK");
    expect(bilesen).toContain("disabled={!gonderilebilir}");
  });

  it("açıklama metni kartın kendisinde — aracı bir sohbet mesajına bağımlı değil", () => {
    expect(bilesen).toContain("İşletmeni anlat");
    expect(bilesen).toContain("bulabildiklerimi otomatik dolduruyorum");
  });
});
