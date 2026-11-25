import { describe, expect, it, vi } from "vitest";
import { globalCikisYap } from "../src/lib/cikis";

function sahteYonlendirici() {
  return { replace: vi.fn(), refresh: vi.fn() };
}

describe("globalCikisYap (tüm cihazlardan kalıcı çıkış)", () => {
  it("başarılı çıkışta scope global ile çağrılır, ana sayfaya dönülür", async () => {
    const signOut = vi.fn().mockResolvedValue({ error: null });
    const yonlendirici = sahteYonlendirici();

    const sonuc = await globalCikisYap({ signOut }, yonlendirici);

    expect(signOut).toHaveBeenCalledTimes(1);
    expect(signOut).toHaveBeenCalledWith({ scope: "global" });
    expect(sonuc).toEqual({ ok: true, hata: null });
    expect(yonlendirici.replace).toHaveBeenCalledWith("/");
    expect(yonlendirici.refresh).toHaveBeenCalledTimes(1);
  });

  it("hata durumunda YÖNLENDİRME YAPILMAZ, mesaj döner", async () => {
    const signOut = vi.fn().mockResolvedValue({ error: { message: "revoked" } });
    const yonlendirici = sahteYonlendirici();

    const sonuc = await globalCikisYap({ signOut }, yonlendirici);

    expect(sonuc.ok).toBe(false);
    expect(sonuc.hata).toBe("Çıkış yapılamadı. Lütfen tekrar deneyin.");
    expect(yonlendirici.replace).not.toHaveBeenCalled();
    expect(yonlendirici.refresh).not.toHaveBeenCalled();
  });

  it("signOut reddedilirse (ağ hatası) kullanıcı sayfada kalır", async () => {
    const signOut = vi.fn().mockRejectedValue(new Error("network"));
    const yonlendirici = sahteYonlendirici();

    await expect(globalCikisYap({ signOut }, yonlendirici)).rejects.toThrow("network");
    expect(yonlendirici.replace).not.toHaveBeenCalled();
    expect(yonlendirici.refresh).not.toHaveBeenCalled();
  });
});
