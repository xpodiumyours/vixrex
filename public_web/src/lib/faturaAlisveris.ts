export interface BelgeKimligi {
  tur: string;
  no: string;
  tarih: string;
  saticiVergiNo: string;
  saticiAd: string;
}

export interface AlisverisSatiri {
  kod: string;
  adet: number | null;
}

export interface AlisverisBelgesi {
  kimlik: BelgeKimligi;
  satirlar: AlisverisSatiri[];
}

export type AlisverisIliskisi = "ayni" | "olasi" | "farkli";

export interface AlisverisKarari {
  iliski: AlisverisIliskisi;
  sebep: string;
}

export function vergiNoTemizle(ham: string): string {
  return ham.replace(/\D/g, "");
}

export function belgeNoTemizle(ham: string): string {
  return ham.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

export function saticiAdiTemizle(ham: string): string {
  return ham
    .toLocaleLowerCase("tr-TR")
    .replace(/[^a-z0-9çğıöşü]/g, "");
}

export function belgeTarihiIso(ham: string): string {
  const metin = ham.trim();
  const gunAy = metin.match(/^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$/);
  if (gunAy) {
    const gun = Number(gunAy[1]);
    const ay = Number(gunAy[2]);
    if (gun < 1 || gun > 31 || ay < 1 || ay > 12) return "";
    return `${gunAy[3]}-${String(ay).padStart(2, "0")}-${String(gun).padStart(2, "0")}`;
  }
  const iso = metin.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (iso) {
    const ay = Number(iso[2]);
    const gun = Number(iso[3]);
    if (gun < 1 || gun > 31 || ay < 1 || ay > 12) return "";
    return metin;
  }
  return "";
}

export function kodTemizle(ham: string): string {
  return ham.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

function saticiAyniMi(a: BelgeKimligi, b: BelgeKimligi): boolean | null {
  const vergiA = vergiNoTemizle(a.saticiVergiNo);
  const vergiB = vergiNoTemizle(b.saticiVergiNo);
  if (vergiA && vergiB) return vergiA === vergiB;
  const adA = saticiAdiTemizle(a.saticiAd);
  const adB = saticiAdiTemizle(b.saticiAd);
  if (adA && adB) return adA === adB;
  return null;
}

function ortakSatirlar(a: AlisverisSatiri[], b: AlisverisSatiri[]): {
  ortak: number;
  adetUyumlu: number;
} {
  const kodlar = new Map<string, number | null>();
  for (const satir of b) {
    const kod = kodTemizle(satir.kod);
    if (kod) kodlar.set(kod, satir.adet);
  }
  let ortak = 0;
  let adetUyumlu = 0;
  for (const satir of a) {
    const kod = kodTemizle(satir.kod);
    if (!kod || !kodlar.has(kod)) continue;
    ortak += 1;
    const adetB = kodlar.get(kod);
    if (satir.adet !== null && adetB !== null && adetB !== undefined && satir.adet === adetB) {
      adetUyumlu += 1;
    }
  }
  return { ortak, adetUyumlu };
}

export function alisverisKarari(yeni: AlisverisBelgesi, eski: AlisverisBelgesi): AlisverisKarari {
  const satici = saticiAyniMi(yeni.kimlik, eski.kimlik);
  if (satici === false) {
    return { iliski: "farkli", sebep: "Belgeyi kesen firma farklı." };
  }

  const noYeni = belgeNoTemizle(yeni.kimlik.no);
  const noEski = belgeNoTemizle(eski.kimlik.no);
  if (satici === true && noYeni && noEski && noYeni === noEski) {
    return { iliski: "ayni", sebep: "Aynı firma ve aynı belge numarası." };
  }

  const tarihYeni = belgeTarihiIso(yeni.kimlik.tarih);
  const tarihEski = belgeTarihiIso(eski.kimlik.tarih);
  if (satici === true && tarihYeni && tarihEski && tarihYeni === tarihEski) {
    const { ortak, adetUyumlu } = ortakSatirlar(yeni.satirlar, eski.satirlar);
    if (ortak > 0 && adetUyumlu === ortak) {
      return {
        iliski: "olasi",
        sebep: "Aynı firma, aynı tarih ve aynı ürün kodları aynı adetlerle geçiyor.",
      };
    }
  }

  return { iliski: "farkli", sebep: "Ortak belge numarası veya ürün-adet eşleşmesi yok." };
}
