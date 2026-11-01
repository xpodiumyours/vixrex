import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const ui = readFileSync(resolve(__dirname, "../src/components/owner/InvoiceToProducts.tsx"), "utf8");
const route = readFileSync(resolve(__dirname, "../src/app/api/fatura-oku/route.ts"), "utf8");
const provider = readFileSync(resolve(__dirname, "../src/lib/faturaArkaPlanIslemi.ts"), "utf8");

describe("R02-AI-01: fatura dosyası dış AI sağlayıcısına aktarılmadan önce aydınlatma", () => {
  it("dosya seçimi erişilebilir veri aktarım bilgilendirmesine bağlanır", () => {
    expect(ui).toContain('aria-describedby="fatura-veri-aktarim-bilgisi"');
    expect(ui).toContain('id="fatura-veri-aktarim-bilgisi"');
    expect(ui).toContain("OpenRouter ve işlemde seçilen yapay zekâ model sağlayıcılarına iletilir");
  });

  it("belgede üçüncü kişilerin bilgilerinin bulunabileceğini belirtir", () => {
    expect(ui).toContain("tedarikçi veya diğer kişilere ait bilgiler");
    expect(ui).toContain("yalnız bu işlem için gerekli belgeyi yükleyin");
  });

  it("bilgilendirme gerçekten çalışan belge gönderim yolundadır", () => {
    expect(route).toContain('form.getAll("dosya")');
    expect(route).toContain("faturayiArkaPlanaGonder");
    expect(provider).toContain("faturaIstekGovdesi");
    expect(provider).toContain("enqueue_invoice_provider_job");
  });
});
