/**
 * Serbest metinden il/ilçe çıkarımı — "esnaf tek paragraf yazsın, asistan
 * anlasın" motorunun (serbestMetinCikarim.ts) bir parçası. Yer adları
 * sıradan kelimelerle (businessCategories.ts'teki kategori terimlerinden
 * çok daha sık) çakıştığı için kelime SINIRLI eşleşme kullanılır — bir alt
 * dizge değil, tam bir kelime aranır.
 *
 * turkeyCities.ts'teki `turkeyDistricts` il KODUYLA anahtarlanmış ("07" →
 * Antalya'nın ilçeleri); burada kod→isim eşlemesi `turkeyProvinces`
 * üzerinden yapılıp ilçe→il(ler) ters haritası kurulur.
 */
import { turkeyProvinces, turkeyDistricts } from "./turkeyCities";
import { normalizeBusinessCategoryTerm as normalizeTr } from "./businessCategories";

export interface YerSonucu {
  il: string;
  ilce: string | null;
}

interface IlceAdayi {
  il: string;
  ilce: string;
}

const MERKEZ = "Merkez";

const KOD_TO_IL = new Map(turkeyProvinces.map((p) => [p.code, p.name]));

// normalize(ilçe adı) → o adı taşıyan il(ler) — birden fazlaysa gerçek
// belirsizlik var demektir (ör. "Kemer" hem Antalya hem Burdur'da).
// "Merkez" ilçesi çoğu ilde var ve hiçbir ayrım sağlamadığı için hariç.
const ILCE_ADAYLARI = new Map<string, IlceAdayi[]>();
for (const [kod, ilceler] of Object.entries(turkeyDistricts)) {
  const il = KOD_TO_IL.get(kod);
  if (!il) continue;
  for (const ilce of ilceler) {
    if (ilce === MERKEZ) continue;
    const anahtar = normalizeTr(ilce);
    const liste = ILCE_ADAYLARI.get(anahtar) ?? [];
    liste.push({ il, ilce });
    ILCE_ADAYLARI.set(anahtar, liste);
  }
}

// normalize(il adı) → kanonik il adı
const IL_ADAYLARI = new Map(turkeyProvinces.map((p) => [normalizeTr(p.name), p.name]));

function kaciril(terim: string): string {
  return terim.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Bir terim haritasındaki her terimin normalize metinde geçip geçmediğini
 * kelime-sınırlı arar; bulunanları pozisyona göre (sonra uzunluğa göre,
 * businessCategories.ts'teki `resolveBusinessCategory` ile aynı sıralama
 * ilkesiyle) sıralı döner. */
function eslesenleriBul<T>(
  normalizedMetin: string,
  terimHaritasi: Map<string, T>,
): Array<{ terim: string; pos: number; deger: T }> {
  const sonuclar: Array<{ terim: string; pos: number; deger: T }> = [];
  for (const [terim, deger] of terimHaritasi) {
    if (!terim) continue;
    const eslesme = normalizedMetin.match(new RegExp(`\\b${kaciril(terim)}\\b`));
    if (eslesme && eslesme.index !== undefined) {
      sonuclar.push({ terim, pos: eslesme.index, deger });
    }
  }
  sonuclar.sort((a, b) => a.pos - b.pos || b.terim.length - a.terim.length);
  return sonuclar;
}

function ilAdiMetindeGeciyorMu(il: string, normalizedMetin: string): boolean {
  return new RegExp(`\\b${kaciril(normalizeTr(il))}\\b`).test(normalizedMetin);
}

export function ilIlceCikar(paragraf: string): YerSonucu | null {
  const normalize = normalizeTr(paragraf);
  const ilEslesmeleri = eslesenleriBul(normalize, IL_ADAYLARI);
  const acikIl = ilEslesmeleri.length === 1 ? ilEslesmeleri[0].deger : null;

  const ilceEslesmeleri = eslesenleriBul(normalize, ILCE_ADAYLARI);
  for (const { deger: adaylar } of ilceEslesmeleri) {
    if (adaylar.length === 1) {
      const aday = adaylar[0];
      // Metinde tek bir il açıkça yazılmışsa benzersiz ilçe de o ile ait
      // olmalıdır. Çelişkili "Mamak, Erzurum" gibi girdide Ankara/Mamak
      // üretmek yerine ilçeyi atla; aşağıdaki il fallback'i Erzurum/null
      // döndürür ve caller special-flow netleştirmesine gider.
      if (acikIl !== null && aday.il !== acikIl) continue;
      return { il: aday.il, ilce: aday.ilce };
    }
    // Belirsiz ilçe (birden fazla ilde var) — paragrafta illerden TAM BİR
    // tanesi de geçiyorsa o çift kullanılır. Sıfır ya da birden fazlası
    // doğrulanırsa bu eşleşme tamamen atlanır — tahmin yok, sıradaki
    // eşleşmeye geçilir.
    const dogrulananlar = adaylar.filter((a) => ilAdiMetindeGeciyorMu(a.il, normalize));
    if (dogrulananlar.length === 1) {
      return { il: dogrulananlar[0].il, ilce: dogrulananlar[0].ilce };
    }
  }

  if (ilEslesmeleri.length > 0) {
    return { il: ilEslesmeleri[0].deger, ilce: null };
  }

  return null;
}
