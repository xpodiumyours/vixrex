import { describe, expect, it, vi } from "vitest";
import { globalCikisYap } from "../src/lib/cikis";

function sahteYonlendirici() {
  return { replace: vi.fn(), refresh: vi.fn() };
}

function sahteCerezTemizleyici() {
  return vi.fn().mockResolvedValue(new Response(null, { status: 200 }));
}

describe("globalCikisYap (tüm cihazlardan kalıcı çıkış)", () => {
  it("başarılı çıkışta scope global çağrılır, sahip çerezi silinir, ana sayfaya dönülür", async () => {
    const signOut = vi.fn().mockResolvedValue({ error: null });
    const yonlendirici = sahteYonlendirici();
    const cerez = sahteCerezTemizleyici();

    const sonuc = await globalCikisYap({ signOut }, yonlendirici, cerez);

    expect(signOut).toHaveBeenCalledTimes(1);
    expect(signOut).toHaveBeenCalledWith({ scope: "global" });
    expect(cerez).toHaveBeenCalledTimes(1);
    expect(sonuc).toEqual({ ok: true, hata: null });
    expect(yonlendirici.replace).toHaveBeenCalledWith("/");
    expect(yonlendirici.refresh).toHaveBeenCalledTimes(1);
  });

  it("hata durumunda YÖNLENDİRME YAPILMAZ, çerez de silinmez", async () => {
    const signOut = vi.fn().mockResolvedValue({ error: { message: "revoked" } });
    const yonlendirici = sahteYonlendirici();
    const cerez = sahteCerezTemizleyici();

    const sonuc = await globalCikisYap({ signOut }, yonlendirici, cerez);

    expect(sonuc.ok).toBe(false);
    expect(sonuc.hata).toBe("Çıkış yapılamadı. Lütfen tekrar deneyin.");
    expect(cerez).not.toHaveBeenCalled();
    expect(yonlendirici.replace).not.toHaveBeenCalled();
    expect(yonlendirici.refresh).not.toHaveBeenCalled();
  });

  it("signOut reddedilirse (ağ hatası) fırlatmaz, kullanıcı sayfada kalır", async () => {
    const signOut = vi.fn().mockRejectedValue(new Error("network"));
    const yonlendirici = sahteYonlendirici();
    const cerez = sahteCerezTemizleyici();

    const sonuc = await globalCikisYap({ signOut }, yonlendirici, cerez);

    expect(sonuc).toEqual({ ok: false, hata: "Çıkış yapılamadı. Lütfen tekrar deneyin." });
    expect(cerez).not.toHaveBeenCalled();
    expect(yonlendirici.replace).not.toHaveBeenCalled();
    expect(yonlendirici.refresh).not.toHaveBeenCalled();
  });

  it("çerez temizliği başarısız olsa bile çıkış tamamlanır", async () => {
    const signOut = vi.fn().mockResolvedValue({ error: null });
    const yonlendirici = sahteYonlendirici();
    const cerez = vi.fn().mockRejectedValue(new Error("offline"));

    const sonuc = await globalCikisYap({ signOut }, yonlendirici, cerez);

    expect(cerez).toHaveBeenCalledTimes(1);
    expect(sonuc).toEqual({ ok: true, hata: null });
    expect(yonlendirici.replace).toHaveBeenCalledWith("/");
  });
});
