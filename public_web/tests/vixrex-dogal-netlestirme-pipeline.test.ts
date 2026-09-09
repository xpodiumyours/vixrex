import { beforeEach, describe, expect, it, vi } from "vitest";

const { rpcMock } = vi.hoisted(() => ({ rpcMock: vi.fn() }));

vi.mock("../src/lib/supabase", () => ({
  supabase: { rpc: rpcMock },
}));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

function pending(anahtar: string, etiket: string, tip: string) {
  rpcMock.mockImplementation(async (name: string, params?: unknown) => {
    if (name === "get_assistant_pending_slot") {
      return { data: { anahtar, etiket, tip }, error: null };
    }
    if (name === "set_assistant_pending_slot") {
      return { data: params ?? null, error: null };
    }
    return { data: null, error: null };
  });
}

describe("Vixrex doğal netleştirme gerçek Next pipeline", () => {
  beforeEach(() => {
    rpcMock.mockReset();
  });

  it("bağlam yok ve cümle anlaşılmıyorsa teknik alan adı sormaz", async () => {
    rpcMock.mockResolvedValue({ data: null, error: null });
    const sonuc = await handleVixrexNluMessage("bunu farklı yap");
    expect(sonuc.outcome).toBe("notUnderstood");
    expect(sonuc.message).toBe("Vitrininde neyi farklı görmek istersin?");
    expect(sonuc.message.toLocaleLowerCase("tr-TR")).not.toContain("hangi alan");
  });

  it("telefon beklenirken 'evet' cevabını telefon değeri diye yazmaz ve bağlamı silmez", async () => {
    pending("telefon", "Telefon", "telefon");
    const sonuc = await handleVixrexNluMessage("evet");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.anahtar).toBe("telefon");
    expect(sonuc.message).toBe("Telefon için ne yazayım?");
    const clearCalls = rpcMock.mock.calls.filter(
      ([name, args]) => name === "set_assistant_pending_slot" && (args as { p_slot?: unknown })?.p_slot === null,
    );
    expect(clearCalls).toHaveLength(0);
  });

  it("aç/kapa sorusunda 'evet' cevabını önceki soruyla birlikte true olarak çözer", async () => {
    pending("puanGoster", "Değerlendirme Puanını Göster", "acikKapali");
    const sonuc = await handleVixrexNluMessage("evet");
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.anahtar).toBe("puanGoster");
    expect(sonuc.deger).toBe(true);
  });

  it("çalışma saati beklenirken yalnız kapanış saati verilirse tam saat diye kaydetmez", async () => {
    pending("calismaSaatleri", "Çalışma Saatleri", "metin");
    const sonuc = await handleVixrexNluMessage("akşam yedi");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.message).toContain("kaçta açıp kaçta kapandığınızı");
    expect(sonuc.tumu).toBeUndefined();
  });

  it("açık adres beklenirken yalnız ilçe verilirse tam adres diye kaydetmez", async () => {
    pending("adres", "Açık Adres", "uzunMetin");
    const sonuc = await handleVixrexNluMessage("Bağcılar");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.message).toBe("Açık adresi biraz daha ayrıntılı yazar mısın?");
    expect(sonuc.tumu).toBeUndefined();
  });
});
