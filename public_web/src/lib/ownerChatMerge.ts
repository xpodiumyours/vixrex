export interface OwnerChatMergeMessage {
  kimden: "asistan" | "kullanici";
  metin: string;
  serverSeq?: number;
  clientMessageId?: string | null;
}

function kaliciKimlik(mesaj: OwnerChatMergeMessage): string | null {
  if (mesaj.clientMessageId) return `client:${mesaj.clientMessageId}`;
  if (typeof mesaj.serverSeq === "number") return `seq:${mesaj.serverSeq}`;
  return null;
}

function ayniIcerik(a: OwnerChatMergeMessage, b: OwnerChatMergeMessage): boolean {
  return a.kimden === b.kimden && a.metin === b.metin;
}

/**
 * RPC penceresi dar olduğunda önceki geçmişi korur. Kalıcı kimliği olan yeni
 * mesaj, yalnız metni aynı olduğu için eski bir mesajla karıştırılmaz.
 * Yerel/kimliksiz mesajlar için eşleşme her oluşumu ayrı sayar.
 */
export function mergeOwnerChatHistory<T extends OwnerChatMergeMessage>(
  onceki: readonly T[],
  gelen: readonly T[],
  kimlikVer: (mesaj: T) => T,
): T[] {
  if (onceki.length <= gelen.length) return [...gelen];

  const kullanilanOnceki = new Set<number>();
  const yeniler: T[] = [];

  for (const aday of gelen) {
    const adayKimligi = kaliciKimlik(aday);
    let eslesmeIndex = -1;

    if (adayKimligi) {
      eslesmeIndex = onceki.findIndex(
        (eski, index) => !kullanilanOnceki.has(index) && kaliciKimlik(eski) === adayKimligi,
      );
    }

    if (eslesmeIndex < 0) {
      eslesmeIndex = onceki.findIndex((eski, index) => {
        if (kullanilanOnceki.has(index) || !ayniIcerik(eski, aday)) return false;
        // Farklı kalıcı kimlikli iki sunucu mesajı, metinleri aynı olsa da
        // birbirinin aynısı değildir. Kimliksiz yerel mesajlar ise bir kez
        // sunucu karşılığıyla eşleştirilebilir.
        return !adayKimligi || !kaliciKimlik(eski);
      });
    }

    if (eslesmeIndex >= 0) kullanilanOnceki.add(eslesmeIndex);
    else yeniler.push(aday);
  }

  if (yeniler.length === 0) return [...onceki];
  return [...onceki, ...yeniler.map(kimlikVer)];
}
