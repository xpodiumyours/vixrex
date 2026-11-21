export type FaturaBeklemeDurumu = {
  hazirlaniyor?: boolean;
  islemKimligi?: string;
  asama?: string;
};

const BEKLEME_ARALIGI_MS = 5_000;
const YAVASLAMA_SONRASI_DENEME = 12;
const YAVAS_BEKLEME_ARALIGI_MS = 10_000;
const COK_YAVASLAMA_SONRASI_DENEME = 36;
const COK_YAVAS_BEKLEME_ARALIGI_MS = 20_000;
const BEKLEME_ZAMAN_ASIMI_MS = 70 * 60 * 1_000;
const YENIDEN_DENEME_ALT_SINIRI_MS = 1_000;
const YENIDEN_DENEME_UST_SINIRI_MS = 60_000;
const YENIDEN_DENEME_VARSAYILAN_MS = 5_000;
const YENIDEN_DENEME_SAPMA_MS = 250;

type Kayit = Record<string, unknown>;

function kayitMi(deger: unknown): deger is Kayit {
  return typeof deger === "object" && deger !== null;
}

function islemKimligi(deger: unknown): string | null {
  if (!kayitMi(deger) || typeof deger.islemKimligi !== "string") return null;
  const kimlik = deger.islemKimligi.trim();
  return kimlik || null;
}

function iptalHatasi(signal: AbortSignal): Error {
  const neden = signal.reason;
  if (neden instanceof Error) return neden;
  const hata = new Error("Fatura hazırlama beklemesi iptal edildi.");
  hata.name = "AbortError";
  return hata;
}

async function abortAwareDelay(
  ms: number,
  signal: AbortSignal | undefined,
  bekle: (ms: number) => Promise<void>,
): Promise<void> {
  if (!signal) {
    await bekle(ms);
    return;
  }
  if (signal.aborted) throw iptalHatasi(signal);

  let temizle: () => void = () => undefined;
  const iptal = new Promise<never>((_, reject) => {
    const abort = () => reject(iptalHatasi(signal));
    signal.addEventListener("abort", abort, { once: true });
    temizle = () => signal.removeEventListener("abort", abort);
  });

  try {
    await Promise.race([bekle(ms), iptal]);
  } finally {
    temizle();
  }
}

async function yanitGovdesi(yanit: Response): Promise<unknown> {
  try {
    return await yanit.json();
  } catch {
    throw new Error("Sunucudan geçerli bir fatura cevabı alınamadı.");
  }
}

async function httpHatasi(yanit: Response): Promise<Error> {
  let govde: unknown = null;
  try {
    const okunacak = typeof yanit.clone === "function" ? yanit.clone() : yanit;
    govde = await okunacak.json();
  } catch {
    try {
      govde = await yanit.text();
    } catch {
      govde = null;
    }
  }

  let mesaj: string | null = null;
  if (typeof govde === "string" && govde.trim()) {
    mesaj = govde.trim();
  } else if (kayitMi(govde)) {
    for (const alan of ["hata", "error", "message"]) {
      if (typeof govde[alan] === "string" && govde[alan].trim()) {
        mesaj = govde[alan].trim();
        break;
      }
    }
  }

  return new Error(
    mesaj ||
      `Fatura hazırlama isteği başarısız oldu${yanit.status ? ` (HTTP ${yanit.status})` : ""}.`,
  );
}

function yenidenDenenebilirDurum(status: number): boolean {
  return status === 408 || status === 429 || status >= 500;
}

function saniyeVeyaTarih(deger: string | null): number | null {
  if (!deger) return null;
  const ham = deger.trim();
  if (!ham) return null;
  const saniye = Number(ham);
  if (Number.isFinite(saniye) && saniye >= 0) return saniye * 1_000;
  const tarih = Date.parse(ham);
  if (Number.isFinite(tarih)) return Math.max(0, tarih - Date.now());
  return null;
}

function yenidenDenemeBeklemesi(yanit: Response, rastgele: () => number): number {
  const istenen = saniyeVeyaTarih(yanit.headers.get("retry-after")) ?? YENIDEN_DENEME_VARSAYILAN_MS;
  const sinirli = Math.min(Math.max(istenen, YENIDEN_DENEME_ALT_SINIRI_MS), YENIDEN_DENEME_UST_SINIRI_MS);
  const sapma = Math.round(Math.min(Math.max(rastgele(), 0), 1) * YENIDEN_DENEME_SAPMA_MS);
  return sinirli + sapma;
}

function sorgulamaAraligi(deneme: number): number {
  if (deneme >= COK_YAVASLAMA_SONRASI_DENEME) return COK_YAVAS_BEKLEME_ARALIGI_MS;
  if (deneme >= YAVASLAMA_SONRASI_DENEME) return YAVAS_BEKLEME_ARALIGI_MS;
  return BEKLEME_ARALIGI_MS;
}

function timeoutHatasi(): Error {
  return new Error("Fatura ürünleri bekleme süresi içinde hazırlanamadı. Aynı işlemden devam edebilirsin.");
}

/**
 * 202 kuyruğa alınmış fatura yanıtını aynı işlem kimliğiyle tamamlanana kadar okur.
 * Hazır görünen gövdeyi, satır sayısını doğrulamadan aynen geri verir; satır kontrolü
 * ve eksik cevap davranışı çağıranın mevcut akışında kalır.
 */
export async function faturaSonucunuBekle<T>(
  ilk: T,
  options: {
    slug: string;
    signal?: AbortSignal;
    fetcher?: typeof fetch;
    bekle?: (ms: number) => Promise<void>;
    rastgele?: () => number;
    onDurum?: (durum: FaturaBeklemeDurumu) => void;
  },
): Promise<T> {
  const baslangic = ilk as unknown;
  if (!kayitMi(baslangic) || baslangic.hazirlaniyor !== true) return ilk;

  const bekleyenKimlik = islemKimligi(baslangic);
  if (!bekleyenKimlik) {
    throw new Error("Fatura hazırlama yanıtında işlem kimliği eksik.");
  }
  options.onDurum?.({
    hazirlaniyor: true,
    islemKimligi: bekleyenKimlik,
    asama: typeof baslangic.asama === "string" ? baslangic.asama : undefined,
  });

  const signal = options.signal;
  const fetcher = options.fetcher ?? fetch;
  const bekle = options.bekle ?? ((ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
  const url = `/api/fatura-islem?slug=${encodeURIComponent(options.slug)}&islemKimligi=${encodeURIComponent(bekleyenKimlik)}`;
  const baslangicZamani = Date.now();
  const rastgele = options.rastgele ?? Math.random;
  let planlananBekleme = 0;
  let deneme = 0;
  let hemenSorgula = false;

  while (true) {
    if (signal?.aborted) throw iptalHatasi(signal);
    const gecen = Date.now() - baslangicZamani;
    const kalan = BEKLEME_ZAMAN_ASIMI_MS - Math.max(gecen, planlananBekleme);
    if (kalan <= 0) throw timeoutHatasi();

    if (!hemenSorgula) {
      const aralik = Math.min(sorgulamaAraligi(deneme), kalan);
      await abortAwareDelay(aralik, signal, bekle);
      planlananBekleme += aralik;
    }
    hemenSorgula = false;

    if (signal?.aborted) throw iptalHatasi(signal);
    if (Date.now() - baslangicZamani >= BEKLEME_ZAMAN_ASIMI_MS || planlananBekleme >= BEKLEME_ZAMAN_ASIMI_MS) {
      throw timeoutHatasi();
    }

    const yanit = await fetcher(url, { signal });
    if (!yanit.ok) {
      if (!yenidenDenenebilirDurum(yanit.status)) throw await httpHatasi(yanit);
      const beklenecek = yenidenDenemeBeklemesi(yanit, rastgele);
      if (Date.now() - baslangicZamani + beklenecek >= BEKLEME_ZAMAN_ASIMI_MS) throw await httpHatasi(yanit);
      await abortAwareDelay(beklenecek, signal, bekle);
      planlananBekleme += beklenecek;
      hemenSorgula = true;
      continue;
    }
    const govde = await yanitGovdesi(yanit);

    if (kayitMi(govde) && govde.hazirlaniyor === true) {
      const donenKimlik = islemKimligi(govde);
      if (!donenKimlik) {
        throw new Error("Fatura hazırlama yanıtında işlem kimliği eksik.");
      }
      if (donenKimlik !== bekleyenKimlik) {
        throw new Error("Fatura hazırlama yanıtı beklenen işlem kimliğiyle eşleşmiyor.");
      }
      options.onDurum?.({
        hazirlaniyor: true,
        islemKimligi: donenKimlik,
        asama: typeof govde.asama === "string" ? govde.asama : undefined,
      });
      deneme += 1;
      continue;
    }

    const donenKimlik = islemKimligi(govde);
    if (donenKimlik && donenKimlik !== bekleyenKimlik) {
      throw new Error("Fatura sonucu beklenen işlem kimliğiyle eşleşmiyor.");
    }
    return govde as T;
  }
}
