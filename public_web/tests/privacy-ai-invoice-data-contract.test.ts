import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const base = resolve(__dirname, "..");
const privacy = readFileSync(resolve(base, "src/app/privacy/page.tsx"), "utf8");
const auth = readFileSync(resolve(base, "../.github/scripts/check_auth_policy.py"), "utf8");
const invoice = readFileSync(resolve(base, "src/app/api/fatura-oku/route.ts"), "utf8");
const vision = readFileSync(resolve(base, "src/lib/faturaGoru.ts"), "utf8");
const priz = readFileSync(resolve(base, "src/lib/faturaPriz.ts"), "utf8");
const provider = readFileSync(resolve(base, "src/lib/faturaArkaPlanIslemi.ts"), "utf8");

describe("R02-GIZ-01: yayımlanan veri envanteri gerçek fatura ve hesap akışını açıklar", () => {
  it("kalıcı Google hesabını ve anonim denemeyi doğru tanımlar; şifre topladığını iddia etmez", () => {
    expect(auth).toContain("Kalıcı hesap = Google");
    expect(auth).toContain("anonim/misafir");
    expect(privacy).toContain("Google girişi");
    expect(privacy).toContain("anonim/misafir");
    expect(privacy).not.toContain("şifre (şifrelenmiş)");
  });

  it("gerçek fatura yüklemesini ve işlenen belge alanlarını açıklar", () => {
    expect(invoice).toContain("application/pdf");
    expect(invoice).toContain('form.getAll("dosya")');
    expect(privacy).toContain("Fatura ve yapay zekâ işleme verileri");
    expect(privacy).toContain("vergi numarası");
    expect(privacy).toContain("fatura satırları");
  });

  it("fatura işlem amacı ile gerçek OpenRouter çağrısı tutarlıdır", () => {
    expect(priz).toContain("https://openrouter.ai/api/v1/chat/completions");
    expect(vision).toContain("faturaPrizIstegiGonder");
    expect(provider).toContain("faturaIstekGovdesi");
    expect(privacy).toContain("OpenRouter ve seçilen yapay zekâ model sağlayıcıları");
    expect(privacy).toContain("ürün kartı");
  });

  it("kullanılan araştırma araçlarını ve yurt dışı aktarımı görünür tutar", () => {
    expect(privacy).toContain("web arama/erişim araçları");
    expect(privacy).toContain("OpenRouter ve model sağlayıcıları");
    expect(privacy).toContain("yurt");
  });

  it("yalnız tek depoda saklama veya imzalanmamış DPA güvencesi iddiası yapmaz", () => {
    expect(privacy).not.toContain("tüm verileriniz burada barındırılır");
    expect(privacy).not.toContain("her sağlayıcıyla ayrı bir veri işleme");
    expect(privacy).toContain("KVKK&apos;nın 9. maddesindeki şartların");
    expect(privacy).toContain("tek başına kanıtlamaz");
  });
});
