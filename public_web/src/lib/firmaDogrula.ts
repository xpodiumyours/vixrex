import { hamGet, varsayilanCoz } from "@/lib/faturaDijitalIz";

export interface FirmaKimligi {
  ad: string;
  vergiNo: string;
  adres: string;
}

export type DogrulamaGucu = "guclu" | "orta" | "zayif" | "dogrulanamadi" | "celisiyor";

export interface FirmaDogrulamasi {
  guc: DogrulamaGucu;
  kanitlar: string[];
  bagliHesaplar: string[];
  katalogDosyalari: string[];
}

export interface FirmaDogrulaBagimliliklari {
  fetcher?: (input: string, init?: RequestInit) => Promise<Response>;
  resolveHost?: (hostname: string) => Promise<string[]>;
}

const SAYFA_YOLLARI = ["/", "/iletisim", "/contact", "/hakkimizda", "/about-us", "/kurumsal"];
const SOSYAL_ALANLAR = ["instagram.com", "facebook.com", "linkedin.com", "youtube.com", "x.com", "twitter.com"];
const ADRES_DURAKLARI = new Set([
  "mahallesi", "mahalle", "mah", "caddesi", "cadde", "cad", "sokak", "sok", "bulvari", "bulvar",
  "blok", "kat", "no", "daire", "istanbul", "turkiye", "turkey",
]);

function sadelestir(ham: string): string {
  return ham
    .toLocaleLowerCase("tr-TR")
    .replace(/ç/g, "c")
    .replace(/ğ/g, "g")
    .replace(/ı/g, "i")
    .replace(/ö/g, "o")
    .replace(/ş/g, "s")
    .replace(/ü/g, "u")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function adresAnahtarlari(adres: string): string[] {
  return [
    ...new Set(
      sadelestir(adres)
        .split(" ")
        .filter((parca) => parca.length >= 4 && !/^\d+$/.test(parca) && !ADRES_DURAKLARI.has(parca)),
    ),
  ];
}

function firmaJetonlari(ad: string): string[] {
  const duraklar = new Set(["ltd", "sti", "tic", "san", "ve", "anonim", "sirketi", "limited", "as", "a"]);
  return sadelestir(ad)
    .split(" ")
    .filter((parca) => parca.length >= 3 && !duraklar.has(parca));
}

function metneCevir(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ");
}

function baslikVeSiteAdi(html: string): string {
  const baslik = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] ?? "";
  const siteAdi = html.match(/<meta[^>]+property=["']og:site_name["'][^>]+content=["']([^"']+)["']/i)?.[1] ?? "";
  return `${baslik} ${siteAdi}`;
}

function baglantilariBul(html: string, alan: string): { hesaplar: string[]; dosyalar: string[] } {
  const hesaplar = new Set<string>();
  const dosyalar = new Set<string>();
  const desen = /href=["']([^"'#]+)["']/gi;
  let eslesme: RegExpExecArray | null;
  while ((eslesme = desen.exec(html)) !== null) {
    let adres: URL;
    try {
      adres = new URL(eslesme[1], `https://${alan}`);
    } catch {
      continue;
    }
    if (adres.protocol !== "https:") continue;
    const host = adres.hostname.toLowerCase().replace(/^www\./, "");
    if (SOSYAL_ALANLAR.some((sosyal) => host === sosyal || host.endsWith(`.${sosyal}`))) {
      hesaplar.add(`https://${host}${adres.pathname}`.replace(/\/$/, ""));
      continue;
    }
    if (/\.pdf$/i.test(adres.pathname) && /katalog|catalog|urun|product|fiyat/i.test(adres.pathname)) {
      if (host === alan || host.endsWith(`.${alan}`)) dosyalar.add(adres.toString());
    }
  }
  return { hesaplar: [...hesaplar].slice(0, 8), dosyalar: [...dosyalar].slice(0, 8) };
}

export async function siteFirmayaAitMi(
  alan: string,
  kimlik: FirmaKimligi,
  bagimliliklar: FirmaDogrulaBagimliliklari = {},
): Promise<FirmaDogrulamasi> {
  const fetcher = bagimliliklar.fetcher ?? fetch;
  const resolveHost = bagimliliklar.resolveHost ?? varsayilanCoz;

  const kanitlar: string[] = [];
  const hesaplar = new Set<string>();
  const dosyalar = new Set<string>();
  const vergiNo = kimlik.vergiNo.replace(/\D/g, "");
  const adresParcalari = adresAnahtarlari(kimlik.adres);
  const jetonlar = firmaJetonlari(kimlik.ad);
  let ulasilan = 0;
  let vergiBulundu = false;
  const bulunanAdres = new Set<string>();
  let adBulundu = false;

  for (const yol of SAYFA_YOLLARI) {
    const sayfa = await hamGet(`https://${alan}${yol}`, fetcher, resolveHost);
    if (!sayfa || sayfa.durum !== 200) continue;
    ulasilan += 1;

    const duz = sadelestir(metneCevir(sayfa.govde));
    if (vergiNo.length >= 10 && metneCevir(sayfa.govde).replace(/\D/g, "").includes(vergiNo)) {
      vergiBulundu = true;
    }
    for (const parca of adresParcalari) {
      if (duz.includes(parca)) bulunanAdres.add(parca);
    }
    if (jetonlar.length > 0) {
      const baslik = sadelestir(baslikVeSiteAdi(sayfa.govde));
      if (jetonlar.every((jeton) => baslik.includes(jeton))) adBulundu = true;
    }
    const baglar = baglantilariBul(sayfa.govde, alan);
    baglar.hesaplar.forEach((hesap) => hesaplar.add(hesap));
    baglar.dosyalar.forEach((dosya) => dosyalar.add(dosya));
  }

  if (vergiBulundu) kanitlar.push("vergi_no");
  const adresUyumu = adresParcalari.length > 0 && bulunanAdres.size >= Math.min(2, adresParcalari.length);
  if (adresUyumu) kanitlar.push("adres");
  if (adBulundu) kanitlar.push("ad");

  const bagli = { bagliHesaplar: [...hesaplar], katalogDosyalari: [...dosyalar] };
  if (ulasilan === 0) return { guc: "dogrulanamadi", kanitlar, ...bagli };
  if (vergiBulundu) return { guc: "guclu", kanitlar, ...bagli };
  if (adresUyumu && adBulundu) return { guc: "guclu", kanitlar, ...bagli };
  if (adresUyumu || adBulundu) return { guc: "orta", kanitlar, ...bagli };

  const faturadaKimlikVar = vergiNo.length >= 10 || adresParcalari.length > 0;
  return { guc: faturadaKimlikVar ? "celisiyor" : "zayif", kanitlar, ...bagli };
}
