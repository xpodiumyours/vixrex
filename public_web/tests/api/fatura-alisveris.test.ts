import { describe, expect, it } from "vitest";
import {
  alisverisKarari,
  belgeTarihiIso,
  type AlisverisBelgesi,
} from "@/lib/faturaAlisveris";

function belge(kismi: Partial<AlisverisBelgesi["kimlik"]>, satirlar: AlisverisBelgesi["satirlar"]): AlisverisBelgesi {
  return {
    kimlik: {
      tur: "e-arsiv",
      no: "",
      tarih: "",
      saticiVergiNo: "1234567890",
      saticiAd: "Glisa Tekstil",
      ...kismi,
    },
    satirlar,
  };
}

describe("aynı alışveriş kararı", () => {
  it("Işılay örneği: bilgi fişi ve e-Arşiv aynı firma, tarih ve adetle olası aynı alışveriştir", () => {
    const efatura = belge({ tarih: "29.09.2026", no: "GLS2026000123" }, [{ kod: "16747", adet: 8 }]);
    const bilgiFisi = belge({ tur: "bilgi fisi", tarih: "29.09.2026", no: "" }, [
      { kod: "16747", adet: 8 },
    ]);

    const karar = alisverisKarari(bilgiFisi, efatura);

    expect(karar.iliski).toBe("olasi");
  });

  it("aynı firma ve aynı belge numarası kesin aynı alışveriştir", () => {
    const a = belge({ no: "GLS 2026-000123" }, [{ kod: "16747", adet: 8 }]);
    const b = belge({ no: "gls2026000123" }, []);

    expect(alisverisKarari(a, b).iliski).toBe("ayni");
  });

  it("farklı firma hiçbir zaman aynı alışveriş sayılmaz", () => {
    const a = belge({ tarih: "29.09.2026" }, [{ kod: "16747", adet: 8 }]);
    const b = belge({ tarih: "29.09.2026", saticiVergiNo: "9999999999" }, [{ kod: "16747", adet: 8 }]);

    expect(alisverisKarari(a, b).iliski).toBe("farkli");
  });

  it("adetler tutmuyorsa ya da tarih farklıysa ayrı alışveriş sayılır", () => {
    const eski = belge({ tarih: "29.09.2026" }, [{ kod: "16747", adet: 8 }]);

    expect(
      alisverisKarari(belge({ tarih: "29.09.2026" }, [{ kod: "16747", adet: 4 }]), eski).iliski,
    ).toBe("farkli");
    expect(
      alisverisKarari(belge({ tarih: "01.10.2026" }, [{ kod: "16747", adet: 8 }]), eski).iliski,
    ).toBe("farkli");
  });

  it("firma kimliği okunamadıysa tahminle eşleştirilmez", () => {
    const a = belge({ saticiVergiNo: "", saticiAd: "", tarih: "29.09.2026" }, [{ kod: "16747", adet: 8 }]);
    const b = belge({ tarih: "29.09.2026" }, [{ kod: "16747", adet: 8 }]);

    expect(alisverisKarari(a, b).iliski).toBe("farkli");
  });

  it("tarih yazımları tek biçime çevrilir, geçersiz tarih boş kalır", () => {
    expect(belgeTarihiIso("29.09.2026")).toBe("2026-09-29");
    expect(belgeTarihiIso("1/10/2026")).toBe("2026-10-01");
    expect(belgeTarihiIso("2026-09-29")).toBe("2026-09-29");
    expect(belgeTarihiIso("31.13.2026")).toBe("");
    expect(belgeTarihiIso("dün")).toBe("");
  });
});
