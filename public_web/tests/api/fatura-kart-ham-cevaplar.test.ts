import fs from "node:fs";
import { describe, expect, it } from "vitest";
import { kartYanitiniCoz } from "@/lib/faturaKartSozlesmesi";

const dizin = "tests/fixtures/fatura-kart";
const oku = (ad: string, uzanti: string): string => fs.readFileSync(`${dizin}/${ad}.${uzanti}`, "utf8");
const satirSayisi = (icerik: string): number => (icerik.match(/"row_id"\s*:/g) ?? []).length;

interface Kunye { dosya: string; job: string; hata: string | null; http: number | null; arac_calisti: number; model: string; json_gecerli: boolean; fatura_satir: number | null; }
const kunye = JSON.parse(oku("kaynak", "json")) as Kunye[];
const bul = (job: string): Kunye => kunye.find((k) => k.job === job) as Kunye;

describe("fatura kartı ham cevapları (gerçek koşulardan)", () => {
  it("künye dört gerçek koşuyu taşır", () => {
    expect(kunye.map((k) => k.job).sort()).toEqual(["12d7718a", "54ff6387", "73718906", "bba4a416"]);
    expect(kunye.every((k) => k.http === 200)).toBe(true);
  });

  it("araçların çalıştığı koşu 30 araç çağrısıyla kayıtlı", () => {
    expect(bul("12d7718a").arac_calisti).toBe(30);
  });

  it("ayrıştırıcı her ham gövdeden içindeki her satırı çıkarır", async () => {
    for (const k of kunye) {
      const icerik = oku(k.dosya, "icerik.txt");
      const { kartlar } = await kartYanitiniCoz(icerik);
      expect(kartlar).toHaveLength(satirSayisi(icerik));
      expect(new Set(kartlar.map((satir) => satir.rowId)).size).toBe(kartlar.length);
    }
  });

  it("eksiksiz koşu faturanın 20 satırının tamamını kartlar", async () => {
    const k = bul("12d7718a");
    const { kartlar } = await kartYanitiniCoz(oku(k.dosya, "icerik.txt"));
    expect(k.fatura_satir).toBe(20);
    expect(kartlar).toHaveLength(k.fatura_satir as number);
  });

  it("ham akış okuyucusu SSE gövdesini içeriğe çevirir", () => {
    const ham = oku("12d7718a-parse", "sse.txt");
    expect(ham).toContain("data: [DONE]");
    expect(ham).toContain('"tool_calls_executed":30');
  });

  it("her koşuda kart sayısı fatura satır sayısına eşit", async () => {
    for (const k of kunye) {
      const { kartlar } = await kartYanitiniCoz(oku(k.dosya, "icerik.txt"));
      expect(kartlar).toHaveLength(k.fatura_satir as number);
    }
  });
});
