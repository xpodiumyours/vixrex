import { describe, expect, it } from "vitest";
import {
  isDisplayableAssistantMessage,
  selectDisplayableMessages,
  type SharedAssistantMessage,
} from "../src/lib/assistantConversation";

const base: SharedAssistantMessage = {
  id: "x",
  seq: 0,
  role: "assistant",
  message_text: "",
};

// Canlıda görülen katalog-öncesi iç-durum dökümü (damgasız).
const dump: SharedAssistantMessage = {
  ...base,
  id: "dump",
  message_text:
    "✓ Blog Üst Başlık\n✓ SSS Bölüm Başlığı\nŞimdi senden gerçek bilgiler almam gerekiyor",
  message_key: null,
};

describe("yalnız katalog damgalı asistan satırları çizilir", () => {
  it("kullanıcı satırı her zaman geçer", () => {
    expect(
      isDisplayableAssistantMessage({ role: "user", message_key: null }),
    ).toBe(true);
  });

  it("damgalı asistan satırı geçer", () => {
    expect(
      isDisplayableAssistantMessage({
        role: "assistant",
        message_key: "setup_invite",
      }),
    ).toBe(true);
  });

  it("damgasız asistan dökümü elenir", () => {
    expect(isDisplayableAssistantMessage(dump)).toBe(false);
  });

  it("karışık geçmişten yalnız çizilebilir olanlar kalır", () => {
    const keyed: SharedAssistantMessage = {
      ...base,
      id: "k",
      message_key: "setup_invite",
      message_text: "Merhaba",
    };
    const user: SharedAssistantMessage = {
      ...base,
      id: "u",
      role: "user",
      message_text: "selam",
      message_key: null,
    };
    expect(selectDisplayableMessages([dump, keyed, user]).map((m) => m.id)).toEqual([
      "k",
      "u",
    ]);
  });

  it("geçmiş boşalırsa karşılama kataloğa düşer (boş liste döner)", () => {
    expect(selectDisplayableMessages([dump])).toEqual([]);
  });
});
