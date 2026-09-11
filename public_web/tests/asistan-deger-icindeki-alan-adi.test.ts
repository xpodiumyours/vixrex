import { describe, expect, it, vi } from "vitest";

const { rpcMock } = vi.hoisted(() => ({ rpcMock: vi.fn() }));
vi.mock("../src/lib/supabase", () => ({ supabase: { rpc: rpcMock } }));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

rpcMock.mockImplementation(async (ad: string, params?: unknown) => {
  if (ad === "get_assistant_pending_slot") return { data: null, error: null };
  if (ad === "set_assistant_pending_slot") return { data: params ?? null, error: null };
  return { data: null, error: null };
});

describe("Değerin içinde geçen alan adı komut sayılmaz", () => {
  it("işletme adı başka bir alanın adını taşıyabilir", async () => {
    const sonuc = await handleVixrexNluMessage("işletme adımı Telefon Dünyası yap");
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.tumu?.[0]?.anahtar).toBe("isletmeAdi");
    expect(sonuc.tumu?.[0]?.deger).toBe("Telefon Dünyası");
  });

  it("düz cümle içindeki alan sözcüğü kaydı engellemez", async () => {
    const sonuc = await handleVixrexNluMessage(
      "kısa tanıtım 20 yıldır telefon ve bilgisayar tamiri yapıyoruz",
    );
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.tumu?.[0]?.anahtar).toBe("kisaTanitim");
  });

  it("rozet metninde adres sözcüğü geçebilir", async () => {
    const sonuc = await handleVixrexNluMessage("rozete adrese yakın park var yaz");
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.tumu?.[0]?.anahtar).toBe("heroRozet");
  });

  it("gerçekten iki alan söylendiyse ikisi de kaydedilir", async () => {
    const sonuc = await handleVixrexNluMessage(
      "whatsapp numaram 05321112233, instagramım kayateknik",
    );
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.tumu?.length).toBe(2);
  });

  it("özel akış isteyen alan varken kısmi kayıt yapılmaz", async () => {
    const sonuc = await handleVixrexNluMessage("Telefonu 0212 123 45 67 yap, ili İstanbul yap");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.tumu).toBeUndefined();
  });

  it("hiçbir alan geçerli değer üretmezse hiçbir şey yazılmaz", async () => {
    const sonuc = await handleVixrexNluMessage("telefonumu 12 yap");
    expect(sonuc.outcome).not.toBe("handled");
    expect(sonuc.tumu).toBeUndefined();
  });
});
