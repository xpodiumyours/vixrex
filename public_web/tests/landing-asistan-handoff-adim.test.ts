import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { asistanHandoffOlustur } from "@/lib/landingAsistanAkisi";

// Canlıda (11:45) görülen hata: "Vitrin hesabına bağlandı ama asistan
// konuşması aktarılamadı." Bu iki test, sanitize_assistant_handoff'in
// reddettiği iki payload hatasını canlıdaki gerçek akış üzerinden
// yakalar.

const RPC_DOSYASI = resolve(
  __dirname,
  "../../supabase/migrations/20260811180000_assistant_handoff_core.sql",
);

/** DB'deki gerçek izin listesi (sanitize_assistant_handoff). */
function dbIzinliAdimlar(): string[] {
  const kaynak = readFileSync(RPC_DOSYASI, "utf8");
  const bas = kaynak.indexOf("v_step = any (array[");
  if (bas < 0) throw new Error("izin listesi bulunamadı");
  const son = kaynak.indexOf("])) then", bas);
  if (son < 0) throw new Error("izin listesi sonu bulunamadı");
  return [...kaynak.slice(bas, son).matchAll(/'([a-z]+)'/g)].map((m) => m[1]);
}

describe("landing asistanı handoff yükü DB sözleşmesine uyar", () => {
  const cevaplar = {
    name: "Levent Kahve",
    kategori: "Kafe & Lokanta",
    whatsapp: "905421802573",
    province_name: "İstanbul",
    district_name: "Çekmeköy",
    address: "Çatalmeşe Mahallesi, 207. Sokak",
    location_source: "manual" as const,
  };

  it("tamamlanan adımların hepsi DB izin listesinde", () => {
    const handoff = asistanHandoffOlustur(cevaplar);
    const izinli = dbIzinliAdimlar();

    for (const adim of handoff.completed_steps) {
      expect(
        izinli,
        `"${adim}" DB izin listesinde değil — RPC bunu reddeder`,
      ).toContain(adim);
    }
  });

  it("hiçbir kullanıcı mesajı boş değil (RPC boş metni reddeder)", () => {
    const handoff = asistanHandoffOlustur(cevaplar);

    for (const mesaj of handoff.messages) {
      if (mesaj.role !== "user") continue;
      expect(
        mesaj.text.trim(),
        "boş kullanıcı metni → INVALID_ASSISTANT_HANDOFF_MESSAGE",
      ).not.toBe("");
    }
  });

  it("mesaj sayısı DB sınırının altında", () => {
    const handoff = asistanHandoffOlustur(cevaplar);
    expect(handoff.messages.length).toBeLessThanOrEqual(24);
  });
});