import { describe, expect, it } from "vitest";
import {
  ownerChatInitialMessages,
  parseAssistantHandoff,
} from "@/lib/assistantHandoff";
import {
  vixRexAsistanAdimiForAlan,
  vixRexAsistanAkisi,
  vixRexHizliSecenekler,
  vixRexMesajlari,
} from "@/lib/vixrexMesajlari";
import { VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";

describe("asistan / NLU — gerçek katalog ve handoff davranışı", () => {
  it("46 alan şemasını gerçek modülden yükler ve anahtarları benzersizdir", () => {
    expect(VITRIN_FIELDS).toHaveLength(46);
    expect(new Set(VITRIN_FIELDS.map((alan) => alan.anahtar)).size).toBe(46);
  });

  it("kurulum alanlarını gerçek mesaj akışında doğru adımlara çözer", () => {
    expect(vixRexAsistanAdimiForAlan("isletmeAdi")?.id).toBe("name");
    expect(vixRexAsistanAdimiForAlan("kategori")?.id).toBe("category");
    expect(vixRexAsistanAdimiForAlan("whatsapp")?.id).toBe("whatsapp");
    expect(vixRexAsistanAdimiForAlan("olmayan_alan")).toBeNull();

    expect(vixRexAsistanAkisi.slice(0, 6).map((adim) => adim.id)).toEqual([
      "name",
      "category",
      "whatsapp",
      "location",
      "legal",
      "publish",
    ]);
  });

  it("hızlı seçenek ve mesaj kataloğunu gerçek JSON çözümleyicisinden üretir", () => {
    expect(vixRexHizliSecenekler.map((secenek) => secenek.id)).toEqual([
      "hazir_vitrin_sec",
      "sifirdan_olustur",
      "bakiniyorum",
    ]);
    expect(vixRexMesajlari.welcome_baslik).toBeTruthy();
    expect(vixRexMesajlari.setup_name_baslik).toBeTruthy();
    expect(vixRexMesajlari.setup_category_baslik).toBeTruthy();
  });

  it("handoff parser geçerli konuşmayı kabul eder, gizli anahtar içeren veriyi reddeder", () => {
    const gecerli = parseAssistantHandoff({
      version: 1,
      completed_steps: ["name"],
      next_step: "category",
      messages: [
        { role: "assistant", text: "  İşletme adını aldım.  " },
        { role: "user", text: "Aymira" },
      ],
    });

    expect(gecerli).toEqual({
      version: 1,
      completed_steps: ["name"],
      next_step: "category",
      messages: [
        { role: "assistant", text: "İşletme adını aldım." },
        { role: "user", text: "Aymira" },
      ],
    });

    expect(
      parseAssistantHandoff({
        version: 1,
        completed_steps: [],
        next_step: "name",
        messages: [{ role: "assistant", text: "Devam" }],
        session_token: "gizli",
      }),
    ).toBeNull();
  });

  it("owner konuşması handoff mesajlarını gerçekten taşır ve sonraki adıma devam eder", () => {
    const handoff = parseAssistantHandoff({
      version: 1,
      completed_steps: ["name"],
      next_step: "category",
      messages: [
        { role: "assistant", text: "Merhaba" },
        { role: "user", text: "Aymira" },
      ],
    });
    expect(handoff).not.toBeNull();

    const rapor = {
      yuzde: 25,
      temelTamam: false,
      sonrakiAdim: "Eksik alan var",
    } as Parameters<typeof ownerChatInitialMessages>[0];

    const mesajlar = ownerChatInitialMessages(rapor, handoff);
    expect(mesajlar.slice(0, 2).map((mesaj) => mesaj.metin)).toEqual([
      "Merhaba",
      "Aymira",
    ]);
    expect(mesajlar.map((mesaj) => mesaj.metin)).toContain(
      "İşletme kategorisi adımından kaldığımız yerden devam edelim.",
    );
    expect(mesajlar.at(-1)?.metin).toContain("vitrinde tıkla");
  });
});
