import { describe, expect, it } from "vitest";
import { vixRexMesajlari } from "@/lib/vixrexMesajlari";

describe("landing hesap bağlama — gerçek mesaj kataloğu çözümleyicisi", () => {
  it("hesap bağlama panelinin üç temel metnini ortak katalogdan çözer", () => {
    expect(vixRexMesajlari.hesap_bagla_baslik).toBe("Vitrinini hesabına bağla");
    expect(vixRexMesajlari.hesap_bagla_aciklama).toBe(
      "Şu an vitrinin bu cihaza bağlı. Telefonunu değiştirirsen ya da tarayıcı verilerini silersen erişimini kaybedersin.",
    );
    expect(vixRexMesajlari.hesap_bagla_buton).toBe("Google ile bağla");
  });

  it("hesap bağlama metinleri boş veya çözümlenmemiş değildir", () => {
    for (const anahtar of [
      "hesap_bagla_baslik",
      "hesap_bagla_aciklama",
      "hesap_bagla_buton",
    ]) {
      expect(vixRexMesajlari[anahtar]?.trim().length).toBeGreaterThan(0);
    }
  });
});
