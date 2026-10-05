import { GORU_MODELI } from "@/lib/faturaGoru";
import type { UreticiUrunu } from "@/lib/ureticiKatalog";
import { alanAdiTemizle } from "@/lib/ureticiKatalog";

const ADRES = "https://openrouter.ai/api/v1/chat/completions";

const PAZAR = [
  "sahibinden.com",
  "trendyol.com",
  "hepsiburada.com",
  "amazon.",
  "n11.com",
  "ciceksepeti.com",
  "facebook.com",
  "instagram.com",
  "linkedin.com",
  "youtube.com",
  "x.com",
  "twitter.com",
  "tiktok.com",
  "wikipedia.org",
];

export interface FirmaKesifGirdisi {
  tedarikci: string;
  vergiNo: string;
  adres: string;
  markalar: string[];
  urunAdlari: string[];
}

export interface FirmaKesifSonucu {
  firma: string;
  site: string;
}

function jsonCikar(ham: string): unknown {
  const bas = ham.indexOf("{");
  const son = ham.lastIndexOf("}");
  if (bas < 0 || son <= bas) return null;
  try {
    return JSON.parse(ham.slice(bas, son + 1));
  } catch {
    return null;
  }
}

function metin(deger: unknown): string {
  return typeof deger === "string" ? deger.trim() : "";
}

function resmiSite(alan: string): boolean {
  const kucuk = alan.toLowerCase();
  return !PAZAR.some((kalip) => kucuk === kalip || kucuk.endsWith(`.${kalip}`) || kucuk.includes(kalip));
}

async function modeleSor(soru: string): Promise<unknown> {
  const anahtar = process.env.OPENROUTER_API_KEY;
  if (!anahtar) return null;

  const cevap = await fetch(ADRES, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${anahtar}`,
    },
    body: JSON.stringify({
      model: GORU_MODELI,
      temperature: 0,
      messages: [{ role: "user", content: soru }],
    }),
  });
  if (!cevap.ok) return null;
  const govde = await cevap.json().catch(() => null);
  const ham = govde?.choices?.[0]?.message?.content;
  if (typeof ham !== "string" || !ham.trim()) return null;
  return jsonCikar(ham);
}

export async function firmaSitesiniModeldenBul(
  girdi: FirmaKesifGirdisi,
): Promise<FirmaKesifSonucu | null> {
  const tedarikci = girdi.tedarikci.trim();
  const markalar = [...new Set(girdi.markalar.map((ad) => ad.trim()).filter(Boolean))].slice(0, 8);
  if (tedarikci.length < 3 && markalar.length === 0) return null;

  const kok = await modeleSor(
    [
      "Toptan faturadan okunan firma. Resmi internet sitesinin alan adini bul. Yalniz JSON don.",
      '{"firma":"","site":""}',
      "site = hostname, ornek voltaj.com.tr. http yazma.",
      "Bilmiyorsan bos birak. Uydurma yok. Pazaryeri, sosyal ag, wikipedia yazma.",
      `tedarikci: ${tedarikci}`,
      `vergi_no: ${girdi.vergiNo.trim()}`,
      `adres: ${girdi.adres.trim()}`,
      `markalar: ${markalar.join(", ")}`,
      `urunler: ${girdi.urunAdlari.filter(Boolean).slice(0, 12).join(" | ")}`,
    ].join("\n"),
  );
  if (!kok || typeof kok !== "object") return null;
  const kayit = kok as { firma?: unknown; site?: unknown };
  const site = alanAdiTemizle(metin(kayit.site));
  if (!site || !resmiSite(site)) return null;
  return { firma: metin(kayit.firma) || tedarikci || site, site };
}

function urunOzeti(urun: UreticiUrunu, sira: number): string {
  return `${sira}. kod=${urun.kod} barkod=${urun.barkod} marka=${urun.marka} ad=${urun.ad}`.slice(0, 220);
}

export async function satirlariModeldenEslestir(
  satirlar: Array<{ model: string; ad: string; barkod: string; marka?: string }>,
  urunler: UreticiUrunu[],
): Promise<Array<number[] | null>> {
  const bos = satirlar.map(() => null);
  if (satirlar.length === 0 || urunler.length === 0) return bos;

  const kok = await modeleSor(
    [
      "Fatura satirlari ile firmanin sitesinden alinan urun listesini esle. Yalniz JSON don.",
      '{"eslesmeler":[{"satir":0,"urunler":[0]}]}',
      "satir ve urunler 0 tabanli indeks. Sitede olmayan urunu yazma.",
      "Emin degilsen o satiri hic yazma. Birden fazla aday varsa urunler dizisine yaz.",
      "Fatura:",
      satirlar
        .map(
          (satir, sira) =>
            `${sira}. model=${satir.model} barkod=${satir.barkod} marka=${satir.marka ?? ""} ad=${satir.ad}`,
        )
        .join("\n"),
      "Site urunleri:",
      urunler.slice(0, 80).map((urun, sira) => urunOzeti(urun, sira)).join("\n"),
    ].join("\n"),
  );
  if (!kok || typeof kok !== "object") return bos;
  const liste = (kok as { eslesmeler?: unknown }).eslesmeler;
  if (!Array.isArray(liste)) return bos;

  const sonuc = [...bos];
  for (const ham of liste) {
    const kayit = (ham ?? {}) as { satir?: unknown; urunler?: unknown };
    const satirNo = Number(kayit.satir);
    if (!Number.isInteger(satirNo) || satirNo < 0 || satirNo >= satirlar.length) continue;
    const indeksler = (Array.isArray(kayit.urunler) ? kayit.urunler : [])
      .map((deger) => Number(deger))
      .filter((no) => Number.isInteger(no) && no >= 0 && no < Math.min(urunler.length, 80));
    const tekil = [...new Set(indeksler)];
    if (tekil.length > 0) sonuc[satirNo] = tekil;
  }
  return sonuc;
}
