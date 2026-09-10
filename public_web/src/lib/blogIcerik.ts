/**
 * Kurumsal Vixrex blogu için sınırlı içerik ayrıştırma yardımcıları.
 * Ham HTML desteklenmez. React çıktı kaçışını kendi yaptığı için blog gövdesi
 * `dangerouslySetInnerHTML` kullanmadan render edilebilir.
 */

export type BlogGovdeBloku =
  | { tur: "paragraf"; metin: string }
  | { tur: "h2" | "h3"; metin: string; id: string }
  | { tur: "liste"; sirali: boolean; maddeler: string[] };

export type BlogIcindekilerMaddesi = {
  seviye: 2 | 3;
  baslik: string;
  id: string;
};

/**
 * Okuma süresi gövdeden hesaplanır; içerikte elle dakika tutulmaz.
 * 200 kelime/dakika burada yalnız deterministik hesaplama sabitidir,
 * SEO/okuma performansı iddiası değildir.
 */
const OKUMA_HIZI_KELIME_DAKIKA = 200;

export function okumaDakikasiHesapla(metin: string): number {
  const kelimeSayisi = metin
    .replace(/^#{2,3}\s+/gm, "")
    .replace(/^\s*(?:[-*]|\d+\.)\s+/gm, "")
    .trim()
    .split(/\s+/)
    .filter(Boolean).length;

  return Math.max(1, Math.ceil(kelimeSayisi / OKUMA_HIZI_KELIME_DAKIKA));
}

export function tarihiYaz(isoTarih: string): string {
  return new Date(`${isoTarih}T00:00:00Z`).toLocaleDateString("tr-TR", {
    timeZone: "UTC",
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

export function blogBaslikId(metin: string): string {
  return metin
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/ı/g, "i")
    .replace(/İ/g, "I")
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");
}

export function govdeyiBloklaraAyir(metin: string): BlogGovdeBloku[] {
  const satirlar = metin.replace(/\r\n/g, "\n").split("\n");
  const bloklar: BlogGovdeBloku[] = [];
  let paragraf: string[] = [];
  let liste: string[] = [];
  let listeSirali = false;
  const baslikIdSayaci = new Map<string, number>();

  const benzersizBaslikId = (baslik: string) => {
    const temel = blogBaslikId(baslik) || "bolum";
    const sira = (baslikIdSayaci.get(temel) || 0) + 1;
    baslikIdSayaci.set(temel, sira);
    return sira === 1 ? temel : `${temel}-${sira}`;
  };

  const paragrafiBitir = () => {
    const yazi = paragraf.join(" ").trim();
    if (yazi) bloklar.push({ tur: "paragraf", metin: yazi });
    paragraf = [];
  };

  const listeyiBitir = () => {
    if (liste.length > 0) {
      bloklar.push({ tur: "liste", sirali: listeSirali, maddeler: [...liste] });
    }
    liste = [];
  };

  for (const ham of satirlar) {
    const satir = ham.trim();

    if (!satir) {
      paragrafiBitir();
      listeyiBitir();
      continue;
    }

    const h3 = satir.match(/^###\s+(.+)$/);
    if (h3) {
      paragrafiBitir();
      listeyiBitir();
      bloklar.push({ tur: "h3", metin: h3[1], id: benzersizBaslikId(h3[1]) });
      continue;
    }

    const h2 = satir.match(/^##\s+(.+)$/);
    if (h2) {
      paragrafiBitir();
      listeyiBitir();
      bloklar.push({ tur: "h2", metin: h2[1], id: benzersizBaslikId(h2[1]) });
      continue;
    }

    const sirali = satir.match(/^\d+\.\s+(.+)$/);
    if (sirali) {
      paragrafiBitir();
      if (liste.length > 0 && !listeSirali) listeyiBitir();
      listeSirali = true;
      liste.push(sirali[1]);
      continue;
    }

    const sirasiz = satir.match(/^[-*]\s+(.+)$/);
    if (sirasiz) {
      paragrafiBitir();
      if (liste.length > 0 && listeSirali) listeyiBitir();
      listeSirali = false;
      liste.push(sirasiz[1]);
      continue;
    }

    listeyiBitir();
    paragraf.push(satir);
  }

  paragrafiBitir();
  listeyiBitir();
  return bloklar;
}

export function icindekileriCikar(metin: string): BlogIcindekilerMaddesi[] {
  return govdeyiBloklaraAyir(metin)
    .filter(
      (blok): blok is Extract<BlogGovdeBloku, { tur: "h2" | "h3" }> =>
        blok.tur === "h2" || blok.tur === "h3"
    )
    .map((blok) => ({
      seviye: blok.tur === "h2" ? 2 : 3,
      baslik: blok.metin,
      id: blok.id,
    }));
}
