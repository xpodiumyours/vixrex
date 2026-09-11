import { beforeEach, describe, expect, it, vi } from "vitest";

const { rpcMock } = vi.hoisted(() => ({ rpcMock: vi.fn() }));

vi.mock("../src/lib/supabase", () => ({
  supabase: { rpc: rpcMock },
}));

import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

function pending(
  anahtar: string,
  etiket: string,
  tip: string,
  eylem?: "kaldir",
) {
  rpcMock.mockImplementation(async (name: string, params?: unknown) => {
    if (name === "get_assistant_pending_slot") {
      return { data: { anahtar, etiket, tip, ...(eylem ? { eylem } : {}) }, error: null };
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

  it("bağlam yokken 'telefonu değiştirme' yazma isteği sayılmaz", async () => {
    rpcMock.mockResolvedValue({ data: null, error: null });
    const sonuc = await handleVixrexNluMessage("telefonu değiştirme");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.tumu).toBeUndefined();
    expect(sonuc.message).toContain("değişiklik yapmıyorum");
  });

  it("telefon beklenirken 'değiştirme' işlemi iptal eder ve bekleyen soruyu temizler", async () => {
    pending("telefon", "Arama Numarası", "telefon");
    const sonuc = await handleVixrexNluMessage("değiştirme");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.tumu).toBeUndefined();
    expect(sonuc.message).toContain("bu değişikliği yapmıyorum");
    const clearCall = rpcMock.mock.calls.find(
      ([name, args]) => name === "set_assistant_pending_slot" && (args as { p_slot?: unknown })?.p_slot === null,
    );
    expect(clearCall).toBeTruthy();
  });

  it("telefon beklenirken 'evet' cevabını telefon değeri diye yazmaz ve bağlamı silmez", async () => {
    pending("telefon", "Arama Numarası", "telefon");
    const sonuc = await handleVixrexNluMessage("evet");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.anahtar).toBe("telefon");
    expect(sonuc.message).toBe("Arama Numarası için ne yazayım?");
    const clearCalls = rpcMock.mock.calls.filter(
      ([name, args]) => name === "set_assistant_pending_slot" && (args as { p_slot?: unknown })?.p_slot === null,
    );
    expect(clearCalls).toHaveLength(0);
  });

  it("aç/kapa sorusunda 'evet' cevabını önceki soruyla birlikte true olarak çözer", async () => {
    pending("puanGoster", "Puan Görünsün", "acikKapali");
    const sonuc = await handleVixrexNluMessage("evet");
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.anahtar).toBe("puanGoster");
    expect(sonuc.deger).toBe(true);
  });

  it("'onu kaldır' cevabında kaldırma onayı bağlamını saklar", async () => {
    pending("telefon", "Arama Numarası", "telefon");
    const sonuc = await handleVixrexNluMessage("onu kaldır");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.message).toBe("Arama Numarası bilgisini kaldırmamı mı istiyorsun?");
    const saveCall = rpcMock.mock.calls.find(
      ([name, args]) =>
        name === "set_assistant_pending_slot" &&
        (args as { p_slot?: { eylem?: string } })?.p_slot?.eylem === "kaldir",
    );
    expect(saveCall).toBeTruthy();
  });

  it("kaldırma onayı beklenirken 'evet' alanı temizleme sonucuna dönüşür", async () => {
    pending("telefon", "Arama Numarası", "telefon", "kaldir");
    const sonuc = await handleVixrexNluMessage("evet");
    expect(sonuc.outcome).toBe("handled");
    expect(sonuc.anahtar).toBe("telefon");
    expect(sonuc.deger).toBeNull();
    expect(sonuc.tumu).toEqual([{ anahtar: "telefon", kolon: "phone", deger: null }]);
    expect(sonuc.message).toBe("Arama Numarası bilgisini kaldırdım.");
  });

  it("çalışma saati beklenirken yalnız kapanış saati verilirse tam saat diye kaydetmez", async () => {
    pending("calismaSaatleri", "Açılış Saatleri", "metin");
    const sonuc = await handleVixrexNluMessage("akşam yedi");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.message).toContain("kaçta açıp kaçta kapandığınızı");
    expect(sonuc.tumu).toBeUndefined();
  });

  it("açık adres beklenirken yalnız ilçe verilirse tam adres diye kaydetmez", async () => {
    pending("adres", "İşletme Adresi", "uzunMetin");
    const sonuc = await handleVixrexNluMessage("Bağcılar");
    expect(sonuc.outcome).toBe("needsClarification");
    expect(sonuc.message).toBe("Açık adresi biraz daha ayrıntılı yazar mısın?");
    expect(sonuc.tumu).toBeUndefined();
  });
});
