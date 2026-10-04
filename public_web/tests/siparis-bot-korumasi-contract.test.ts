import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

function kaynak(yol: string): string {
  return readFileSync(resolve(__dirname, yol), "utf-8");
}

const panel = kaynak("../src/components/SiparisPaneli.tsx");
const saglayici = kaynak("../src/components/recaptcha/RecaptchaProvider.tsx");
const ucnokta = kaynak("../src/app/api/orders/route.ts");
const goc = kaynak(
  "../../supabase/migrations/20260926090000_siparis_ve_tahsilat.sql"
);

describe("sipariş formu bot koruması", () => {
  it("panel order_create eylemiyle jeton istiyor", () => {
    expect(panel).toContain('executeRecaptcha("order_create")');
  });

  it("jetonu /api/orders gövdesine koyuyor", () => {
    expect(panel).toMatch(
      /const recaptchaToken = await executeRecaptcha\("order_create"\)/
    );
    expect(panel).toContain("recaptchaToken,");
  });

  it("sağlayıcı order_create eylemi için Google betiğini yüklüyor", () => {
    const gercekEylemler = saglayici.match(/GERCEK_EYLEMLER = new Set\(\[([\s\S]*?)\]\)/);
    expect(gercekEylemler).not.toBeNull();
    expect(gercekEylemler![1]).toContain('"order_create"');
  });

  it("uç nokta sir varsa jetonu istiyor ve doğruluyor", () => {
    expect(ucnokta).toContain("RECAPTCHA_SECRET_KEY");
    expect(ucnokta).toContain('verifyRecaptchaToken(token, "order_create")');
  });

  it("jetonsuz istek sir varsa reddediliyor", () => {
    expect(ucnokta).toContain("Güvenlik doğrulaması eksik");
  });
});

describe("sipariş oran sınırı", () => {
  it("vitrin başına saatte 30 sipariş", () => {
    expect(goc).toContain("'order:' || v_store.id::text, 30, 3600");
  });
});
