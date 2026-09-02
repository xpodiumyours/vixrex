import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Faz C2 (Tek Asistan planı, 2026-09-02) — ChatBubble hızlı cevap desteği.
 *
 * Flutter paritesi: `VixRexQuickReplies`/`ChatPill` (lib/widgets/
 * vixrex_quick_replies.dart) ile aynı fikir — {label, onTap} ilk seçenek
 * vurgulu. Flutter'ın `VixRexAction` enum'ı kasıtlı olarak taşınmadı:
 * OCR/XML/scrollTo gibi yalnız Flutter'a özgü aksiyonlar owner panelinde
 * anlamsız; `payload` serbest string, anlamı çağıran tarafta.
 *
 * Şu an hiçbir yer `mesajEkle`yi 3. argümanla çağırmıyor — bu tamamen
 * kullanılmayan, hazır bekleyen bir yetenek. İlk gerçek kullanım Faz C3
 * ("Google ile devam et" sohbet balonunda).
 */
describe("QuickReply tipi mevcut mesaj sözleşmesini bozmadan eklendi", () => {
  const handoffKaynak = oku("lib/assistantHandoff.ts");

  it("QuickReply {label, payload} tanımlı", () => {
    expect(handoffKaynak).toContain("export interface QuickReply {\n  label: string;\n  payload: string;\n}");
  });

  it("OwnerChatMessage.hizliCevaplar opsiyonel", () => {
    expect(handoffKaynak).toContain("hizliCevaplar?: QuickReply[];");
  });
});

describe("useOwnerChat.mesajEkle geriye uyumlu genişledi", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerChat.ts");

  it("3. argüman opsiyonel — 30'dan fazla mevcut çağrı yeri etkilenmez", () => {
    expect(kaynak).toContain(
      "hizliCevaplar?: Mesaj[\"hizliCevaplar\"]"
    );
  });

  it("hızlı cevaplar DB'ye yazılmıyor — yalnız oturum belleği", () => {
    expect(kaynak).toContain("p_catalog_snapshot: null");
  });

  it("15sn poll, önceki mesajdaki hızlı cevabı metin eşleşirse korur", () => {
    expect(kaynak).toContain("const zenginlestir = (hedef: Mesaj[]) =>");
    expect(kaynak).toContain("prev[i]?.hizliCevaplar && prev[i].metin === msg.metin");
  });
});

describe("ChatBubble hızlı cevap düğmelerini çizer", () => {
  const kaynak = oku("app/v/[slug]/components/ChatBubble.tsx");

  it("onHizliCevap opsiyonel, payload + label ile çağrılır", () => {
    expect(kaynak).toContain(
      "onHizliCevap?: (payload: string, label: string) => void;"
    );
    expect(kaynak).toContain(
      "onClick={() => onHizliCevap?.(secenek.payload, secenek.label)}"
    );
  });

  it("ilk seçenek vurgulu (primary), diğerleri değil — Flutter ChatPill deseni", () => {
    expect(kaynak).toContain("i === 0");
    expect(kaynak).toContain("bg-blue-600");
  });

  it("hızlı cevap yoksa hiçbir şey çizilmez (boş dizi güvenli)", () => {
    expect(kaynak).toContain("hizliCevaplar.length > 0 ? (");
  });
});
