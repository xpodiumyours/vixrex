export type FaturaBeklemeDurumu = {
  hazirlaniyor?: boolean;
  islemKimligi?: string;
};

const BEKLEME_ARALIGI_MS = 5_000;
const BEKLEME_ZAMAN_ASIMI_MS = 35 * 60 * 1_000;

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

function timeoutHatasi(): Error {
  return new Error("Fatura ürünleri 35 dakika içinde hazırlanamadı. Lütfen tekrar dene.");
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
  },
): Promise<T> {
  const baslangic = ilk as unknown;
  if (!kayitMi(baslangic) || baslangic.hazirlaniyor !== true) return ilk;

  const bekleyenKimlik = islemKimligi(baslangic);
  if (!bekleyenKimlik) {
    throw new Error("Fatura hazırlama yanıtında işlem kimliği eksik.");
  }

  const signal = options.signal;
  const fetcher = options.fetcher ?? fetch;
  const bekle = options.bekle ?? ((ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms)));
  const url = `/api/fatura-islem?slug=${encodeURIComponent(options.slug)}&islemKimligi=${encodeURIComponent(bekleyenKimlik)}`;
  const baslangicZamani = Date.now();
  let planlananBekleme = 0;

  while (true) {
    if (signal?.aborted) throw iptalHatasi(signal);
    const gecen = Date.now() - baslangicZamani;
    const kalan = BEKLEME_ZAMAN_ASIMI_MS - Math.max(gecen, planlananBekleme);
    if (kalan <= 0) throw timeoutHatasi();

    const aralik = Math.min(BEKLEME_ARALIGI_MS, kalan);
    await abortAwareDelay(aralik, signal, bekle);
    planlananBekleme += aralik;

    if (signal?.aborted) throw iptalHatasi(signal);
    if (Date.now() - baslangicZamani >= BEKLEME_ZAMAN_ASIMI_MS || planlananBekleme >= BEKLEME_ZAMAN_ASIMI_MS) {
      throw timeoutHatasi();
    }

    const yanit = await fetcher(url, { signal });
    if (!yanit.ok) throw await httpHatasi(yanit);
    const govde = await yanitGovdesi(yanit);

    if (kayitMi(govde) && govde.hazirlaniyor === true) {
      const donenKimlik = islemKimligi(govde);
      if (!donenKimlik) {
        throw new Error("Fatura hazırlama yanıtında işlem kimliği eksik.");
      }
      if (donenKimlik !== bekleyenKimlik) {
        throw new Error("Fatura hazırlama yanıtı beklenen işlem kimliğiyle eşleşmiyor.");
      }
      continue;
    }

    const donenKimlik = islemKimligi(govde);
    if (donenKimlik && donenKimlik !== bekleyenKimlik) {
      throw new Error("Fatura sonucu beklenen işlem kimliğiyle eşleşmiyor.");
    }
    return govde as T;
  }
}
