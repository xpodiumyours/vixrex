import { describe, expect, it, vi } from "vitest";

const { rpcMock } = vi.hoisted(() => ({ rpcMock: vi.fn() }));

vi.mock("../src/lib/supabase", () => ({
  supabase: { rpc: rpcMock },
}));

import { vixrexGeneralFallback } from "../src/lib/vixrexGeneralFallback";
import { vixRexMesajlari } from "../src/lib/vixrexMesajlari";
import { handleVixrexNluMessage } from "../src/lib/vixrexNluPipeline";

describe("Vixrex genel rehber Flutter ↔ Next parity", () => {
  it("sabit rehber niyetlerini ortak mesaj kataloğundan üretir", () => {
    expect(vixrexGeneralFallback("Vixrex nedir?")?.message).toBe(
      vixRexMesajlari.vixrex_info,
    );
    expect(vixrexGeneralFallback("hesabımı güvenceye almak istiyorum")?.message).toBe(
      vixRexMesajlari.hesap,
    );
    expect(vixrexGeneralFallback("XML ile toplu ürün yükleyebilir miyim?")?.message).toBe(
      vixRexMesajlari.xml_upload,
    );
    expect(vixrexGeneralFallback("OCR ile fatura taramak istiyorum")?.message).toBe(
      vixRexMesajlari.ocr_scan,
    );
  });

  it("yayın durumu bilinmeyen QR ve kişisel karşılama için tahmin yapmaz", () => {
    expect(vixrexGeneralFallback("QR kodumu göster")).toBeNull();
    expect(vixrexGeneralFallback("merhaba")).toBeNull();
  });

  it("QR durumu kesin verilirse ortak katalogdaki doğru mesajı seçer", () => {
    expect(
      vixrexGeneralFallback("QR kodumu göster", { isPublished: true })?.message,
    ).toBe(vixRexMesajlari.qr_yayinda);
    expect(
      vixrexGeneralFallback("QR kodumu göster", { isPublished: false })?.message,
    ).toBe(vixRexMesajlari.qr_yayinda_degil);
  });

  it("Next pipeline genel rehber cevabında notUnderstood kalır ve alan yazmaz", async () => {
    rpcMock.mockResolvedValue({ data: null, error: null });

    const sonuc = await handleVixrexNluMessage(
      "hesabımı güvenceye almak istiyorum",
    );

    expect(sonuc.outcome).toBe("notUnderstood");
    expect(sonuc.message).toBe(vixRexMesajlari.hesap);
    expect(sonuc.anahtar).toBeUndefined();
    expect(sonuc.tumu).toBeUndefined();
  });

  it("gerçekten bilinmeyen cümlede doğal genel soru korunur", async () => {
    rpcMock.mockResolvedValue({ data: null, error: null });

    const sonuc = await handleVixrexNluMessage("bunu biraz daha iyi yap");

    expect(sonuc.outcome).toBe("notUnderstood");
    expect(sonuc.message).toBe("Vitrininde neyi farklı görmek istersin?");
  });
});
