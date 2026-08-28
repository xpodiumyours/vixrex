import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

/**
 * SİLME SÖZLEŞMESİ (2026-08-28).
 *
 * Ölçüldü: `shelf-images` kovasındaki 328 dosyanın 328'i sahipsizdi —
 * 120 MB, deponun %77'si, hepsi silinmiş vitrinlerden kalma. Kod tabanında
 * vitrin/hesap silinirken depo temizleyen tek satır yoktu.
 *
 * Bu ayrıca hukuki bir taahhüt: yayındaki Veri Silme metni "hesap
 * silindiğinde galeri görselleriniz silinir" diyor. Aşağıdaki iddialar o
 * cümlenin karşılığının kodda kalmasını sağlıyor.
 */

const KOK = resolve(__dirname, "..");
const oku = (yol: string) => readFileSync(resolve(KOK, yol), "utf8");

describe("silinen vitrinin görselleri", () => {
  const rota = oku("src/app/api/account/route.ts");

  it("hesap/vitrin silme yolunda depo temizliği çağrılıyor", () => {
    expect(rota).toMatch(/vitrinGorsellerinisil\(/);
  });

  it("temizlenecek slug SİLMEDEN ÖNCE okunuyor", () => {
    // Hesap silindikten sonra bootstrap_owner_state vitrini bulamaz;
    // sıra bozulursa temizlik sessizce hiçbir şey silmez.
    const bootstrapYeri = rota.indexOf("bootstrap_owner_state");
    const silmeYeri = rota.indexOf("delete_user_account");
    expect(bootstrapYeri).toBeGreaterThan(-1);
    expect(bootstrapYeri).toBeLessThan(silmeYeri);
  });

  it("temizlik SİLME BAŞARILI olduktan sonra çalışıyor", () => {
    const hataDonusu = rota.indexOf("Hesap silinemedi.");
    const temizlik = rota.indexOf("vitrinGorsellerinisil(temizlenecekSlug)");
    expect(temizlik).toBeGreaterThan(hataDonusu);
  });

  it("temizlik yönetici istemcisi kullanıyor", () => {
    // Depo yazma service-role ister; kullanıcı jetonuyla silinemez.
    const kaynak = oku("src/lib/depoTemizle.ts");
    expect(kaynak).toMatch(/getSupabaseAdmin/);
    expect(kaynak).toMatch(/KOVA = "shelf-images"/);
    expect(kaynak).toMatch(/from\(KOVA\)\s*\.\s*remove\(/);
  });

  it("temizlik yalnız shelf-images kovasına dokunuyor", () => {
    // `category-templates` kullanımda (349 şablon kaydının 326'sı oradan).
    const kaynak = oku("src/lib/depoTemizle.ts");
    expect(kaynak).not.toMatch(/category-templates/);
  });

  it("slug temizleniyor — başka klasöre taşamaz", () => {
    const kaynak = oku("src/lib/depoTemizle.ts");
    expect(kaynak).toMatch(/replace\(\/\[\^a-zA-Z0-9-\]\/g, ""\)/);
  });
});
