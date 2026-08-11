import { describe, expect, it } from "vitest";
import {
  ownerChatInitialMessages,
  parseAssistantHandoff,
} from "../src/lib/assistantHandoff";
import type { HazirlikRaporu } from "../src/lib/vitrinReadiness";

const rapor: HazirlikRaporu = {
  temelTamam: true,
  yuzde: 72,
  doluSayisi: 8,
  toplamSayisi: 11,
  eksikler: [],
  sonrakiAdim: "Hakkımızda metni eklerseniz vitriniz daha güçlü görünür.",
};

describe("Vixrex Asistan handoff devamı", () => {
  it("Flutter konuşmasını tekrar selamlamadan kaldığı yerden sürdürür", () => {
    const handoff = parseAssistantHandoff({
      version: 1,
      completed_steps: [
        "name",
        "category",
        "whatsapp",
        "location",
        "legal",
        "publishing",
      ],
      next_step: "done",
      messages: [
        { role: "assistant", text: "Vitrinin hazır. Birlikte açalım." },
        { role: "user", text: "Vitrinimi aç." },
      ],
    });

    expect(handoff).not.toBeNull();
    const messages = ownerChatInitialMessages(rapor, handoff);

    expect(messages.map(({ kimden, metin }) => ({ kimden, metin }))).toEqual([
      { kimden: "asistan", metin: "Vitrinin hazır. Birlikte açalım." },
      { kimden: "kullanici", metin: "Vitrinimi aç." },
      {
        kimden: "asistan",
        metin: "Hakkımızda metni eklerseniz vitriniz daha güçlü görünür.",
      },
      {
        kimden: "asistan",
        metin: "Değiştirmek istediğin yazıya vitrinde tıkla — buradan düzenleriz.",
      },
    ]);
    expect(messages.some((message) => message.metin.includes("Doluluk"))).toBe(false);
  });

  it("bozuk veya desteklenmeyen handoff'ta mevcut hazırlık akışına döner", () => {
    expect(
      parseAssistantHandoff({
        version: 2,
        completed_steps: [],
        next_step: "done",
        messages: [],
      })
    ).toBeNull();
    expect(
      parseAssistantHandoff({
        version: 1,
        completed_steps: [],
        next_step: "done",
        messages: [{ role: "user", text: "session_token=secret" }],
      })
    ).toBeNull();

    const messages = ownerChatInitialMessages(rapor, null);
    expect(messages[0]?.metin).toBe("Vitrinin yayına hazır görünüyor. Doluluk: %72.");
  });
});
