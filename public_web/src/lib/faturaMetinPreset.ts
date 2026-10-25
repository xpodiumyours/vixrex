import { faturaIstekGovdesi, faturaYanitMetniniOku, katalogJsonunuOku, type GoruSonucu } from "@/lib/faturaGoru";

export const METIN_OKUMA_PRESET = "@preset/vixrex-fatura-okuma-metin-v1";

const SATIR_ALANLARI = ["HAM_SATIR", "AD", "MODEL", "BARKOD", "MARKA", "URETICI", "VARYANT", "BEDEN", "GRAMAJ", "ADET", "BIRIM", "BIRIM_FIYAT", "TUTAR", "OKUMA_GUVENI"];
const BELGE_ALANLARI: Record<string, string> = {
  TEDARIKCI: "tedarikci", TEDARIKCI_VERGI_NO: "tedarikci_vergi_no", TEDARIKCI_ADRES: "tedarikci_adres",
  BELGE_TURU: "belge_turu", BELGE_NO: "belge_no", BELGE_TARIHI: "belge_tarihi",
  TOPLAM_ADET: "toplam_adet", TOPLAM_TUTAR: "toplam_tutar", MAL_BEDELI: "mal_bedeli",
  KDV_TUTARI: "kdv_tutari", INDIRIM_TUTARI: "indirim_tutari", ODENECEK_TOPLAM: "odenecek_toplam",
};

export function metinPresetIstekGovdesi(goruntu: string | string[]): Record<string, unknown> {
  const eski = faturaIstekGovdesi(goruntu);
  const messages = eski.messages as Array<{ content: unknown[] }>;
  return {
    model: METIN_OKUMA_PRESET, stream: true,
    messages: [{ role: "user", content: [{ type: "text", text: "Ekli faturayı yalnız presetindeki VIXREX_FATURA_OKUMA_V1 düz metin protokolüyle oku. Her ürün satırını ve SATIR_ID değerini koru. Araştırma veya kart üretme." }, ...messages[0].content.slice(1)] }],
  };
}

export function faturaMetniniOku(icerik: string): GoruSonucu {
  const lines = icerik.trim().split(/\r?\n/);
  if (lines.shift() !== "VIXREX_FATURA_OKUMA_V1") throw new Error("OKUMA_COZULEMEDI");
  const rows = new Map<number, Record<string, string>>();
  const belge: Record<string, unknown> = {};
  const uyarilar: string[] = [];
  let row: Record<string, string> | undefined;
  for (const line of lines) {
    if (!line.trim()) continue;
    const match = /^([A-Z_]+):\s*(.*)$/.exec(line.trim());
    if (!match) throw new Error("OKUMA_COZULEMEDI");
    const [, key, raw] = match;
    const value = raw.trim() === "--" ? "" : raw.trim();
    if (key === "SATIR_ID") {
      if (!/^[1-9]\d*$/.test(value)) throw new Error("OKUMA_COZULEMEDI");
      const id = Number(value);
      if (!Number.isSafeInteger(id) || rows.has(id)) throw new Error("OKUMA_COZULEMEDI");
      row = {};
      rows.set(id, row);
    } else if (key === "GRUP") {
      row = undefined;
    } else if (key === "UYARI") {
      if (value) uyarilar.push(value);
    } else if (Object.hasOwn(BELGE_ALANLARI, key)) {
      const alan = BELGE_ALANLARI[key];
      if (Object.hasOwn(belge, alan)) throw new Error("OKUMA_COZULEMEDI");
      belge[alan] = value;
    } else if (SATIR_ALANLARI.includes(key) && row && !Object.hasOwn(row, key)) {
      row[key] = value;
    } else {
      throw new Error("OKUMA_COZULEMEDI");
    }
  }
  const ordered = [...rows.entries()].sort(([a], [b]) => a - b);
  const satirlar = ordered.map(([id, s], index) => {
    if (id !== index + 1 || SATIR_ALANLARI.some((key) => !Object.hasOwn(s, key)) || !s.HAM_SATIR) {
      throw new Error("OKUMA_COZULEMEDI");
    }
    return Object.fromEntries([
      ["satir_no", id], ...SATIR_ALANLARI.map((key) => [key.toLowerCase(), s[key]]),
    ]);
  });
  const sonuc = katalogJsonunuOku(JSON.stringify({ ...belge, satirlar, uyarilar }));
  return { ...sonuc, okumaMetni: icerik.trim() };
}

export async function faturaOkumaYanitiniOku(cevap: Response): Promise<GoruSonucu> {
  const { icerik, ...kullanim } = await faturaYanitMetniniOku(cevap);
  const sonuc = icerik.trim().startsWith("VIXREX_FATURA_OKUMA_V1")
    ? faturaMetniniOku(icerik) : katalogJsonunuOku(icerik);
  return { ...sonuc, ...kullanim };
}
