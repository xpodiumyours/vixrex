import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";

const privacy = readFileSync(resolve(__dirname, "../src/app/privacy/page.tsx"), "utf-8");
const contact = readFileSync(resolve(__dirname, "../src/app/(site)/iletisim/page.tsx"), "utf-8");
const about = readFileSync(resolve(__dirname, "../src/app/(site)/hakkimizda/page.tsx"), "utf-8");
const mobile = readFileSync(resolve(__dirname, "../../lib/config/legal_config.dart"), "utf-8");
const operator = "Furkan Aksakal";
const tradeName = "Aksakal Ticaret";
const email = "destek@vixrex.com";
const postalAddress = "Esenevler Mah. Lokman Hekim Cad. No:18 İç Kapı No:10 Ümraniye/İstanbul";
const phone = "0542 180 25 73";

describe("R-02 / KVKK-01 — veri sorumlusu ve iletişim tutarlılığı", () => {
  it("resmi veri sorumlusu kimliği web ve mobilde eşleşir", () => {
    for (const source of [privacy, contact, about, mobile]) {
      expect(source).toContain(operator);
      expect(source).toContain(tradeName);
    }
    expect(privacy).toContain("Veri sorumlusu:");
  });

  it("web ve mobil aynı fiziksel iletişim adresini kullanır", () => {
    for (const source of [privacy, contact, mobile]) {
      expect(source).toContain(postalAddress);
    }
  });

  it("tüm KVKK temas noktaları kanonik e-postayı kullanır", () => {
    for (const source of [privacy, contact, mobile, about]) {
      expect(source).toContain(email);
    }
    expect(privacy).toContain('href="mailto:destek@vixrex.com"');
    expect(mobile).toContain("defaultValue: 'destek@vixrex.com'");
    for (const source of [privacy, mobile]) {
      expect(source).not.toContain("vixrex.app@gmail.com");
      expect(source).not.toContain("Xpodiumyours@gmail.com");
    }
  });

  it("telefon numarası hem gizlilik hem iletişim yüzeyinde aynı kalır", () => {
    expect(privacy).toContain(phone);
    expect(contact).toContain(phone);
    expect(privacy).toContain("tel:+905421802573");
  });

  it("KVKK e-posta başvurularında kayıtlı gönderici koşulunu açıklar", () => {
    expect(contact).toContain("daha önce bildirdiğiniz ve sistemimizde kayıtlı");
    expect(contact).toContain("KEP, güvenli elektronik imza ve mobil imza");
    expect(contact).toContain("30 gün");
    expect(privacy).toContain('href="/iletisim"');
  });

  it("mobil uygulama derleme zamanı hukuki kimlik ayarlarını korur", () => {
    expect(mobile).toContain("'LEGAL_DATA_CONTROLLER_TITLE'");
    expect(mobile).toContain("'LEGAL_DATA_CONTROLLER_ADDRESS'");
    expect(mobile).toContain("'LEGAL_PRIVACY_EMAIL'");
    expect(mobile).toContain("static const String companyName = ownerName;");
  });

  it("genel gizlilik sayfasının diğer konu başlıkları korunur", () => {
    expect(privacy).toContain("2. Toplanan Veriler");
    expect(privacy).toContain("3. Verilerin Kullanım Amacı");
    expect(privacy).toContain("4. Verilerin Paylaşılması");
    expect(privacy).toContain("5. Veri Saklama");
    expect(privacy).toContain("6. Haklarınız (KVKK)");
  });
});
