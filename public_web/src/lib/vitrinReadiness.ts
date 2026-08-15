// Vitrin hazırlık raporu (implementation_plan.md Commit 9).
//
// "Hangi alanlar boş?" sorusunu ŞEMADAN hesaplar. Alan başına kontrol
// yazılmaz — referans sablonlar/hedef-vitrin.html'deki getReadiness() beş
// kontrolü elle sayıyordu ve o yüzden yalnız beş şeyi görebiliyordu.
//
// Yeni alan eklendiğinde bu dosya değişmez.

import {
  VITRIN_FIELDS,
  type VitrinField,
  type VitrinSection,
} from "./vitrinFieldSchema";

/** Vitrinin ayakta durması için doldurulması beklenen alanlar. */
// TEK DOĞRU KAYNAK: şemadaki `zorunlu` işareti.
//
// Burada eskiden elle yazılmış ayrı bir liste vardı ve üç yerde üç farklı
// "zorunlu" tanımı oluşmuştu: şema yalnız işletme adını, bu liste beş
// alanı, Flutter'ın kendi mantığı dört şeyi zorunlu sayıyordu. Kategoriyi
// yalnız bu liste sayıyordu — Flutter hiç sormadığı için sohbetle açılan
// her vitrin "Diğer" kalıyordu.
//
// Artık zorunluluk yalnız şemada tanımlanır; buraya ve Flutter'a oradan
// gelir. Yeni bir alanı zorunlu yapmak = şemaya tek satır.
const TEMEL_ALANLAR = new Set(
  VITRIN_FIELDS.filter((alan) => alan.zorunlu).map((alan) => alan.anahtar),
);

// Vitrini web sitesi kalitesine çıkaran, ama şart olmayan alanlar — artık
// yalnız burada elle tutulmuyor, şemadaki `kalite` işaretinden gelir
// (TEMEL_ALANLAR'ın `zorunlu`'dan gelmesiyle aynı desen).
const KALITE_ALANLARI = new Set(
  VITRIN_FIELDS.filter((alan) => alan.kalite).map((alan) => alan.anahtar),
);

export type EksikOnem = "temel" | "kalite" | "istege-bagli";

export interface EksikAlan {
  anahtar: string;
  etiket: string;
  bolum: VitrinSection;
  onem: EksikOnem;
}

export interface HazirlikRaporu {
  /** Temel alanların tamamı dolu mu? */
  temelTamam: boolean;
  /** 0–100. Temel ve kalite alanlarının doluluk oranı. */
  yuzde: number;
  doluSayisi: number;
  toplamSayisi: number;
  eksikler: EksikAlan[];
  /** Kullanıcıya söylenecek tek cümlelik sıradaki adım. */
  sonrakiAdim: string | null;
}

export function alanOnemi(alan: VitrinField): EksikOnem {
  if (TEMEL_ALANLAR.has(alan.anahtar)) return "temel";
  if (KALITE_ALANLARI.has(alan.anahtar)) return "kalite";
  return "istege-bagli";
}

function doluMu(deger: unknown, bosDegerler?: readonly string[]): boolean {
  if (deger === null || deger === undefined) return false;
  if (typeof deger === "string") {
    const kirpilmis = deger.trim();
    if (kirpilmis.length === 0) return false;
    // Faz F (Tek Asistan planı): bazı değerler teknik olarak dolu ama
    // işlevsel olarak eksik — ör. kategori "Diğer" seçilirse kategoriye
    // bağlı hiçbir şey (butonlar, hazır görseller) çalışmaz. Flutter'ın
    // categoryCompleted getter'ıyla aynı kural, artık şemadan okunuyor.
    if (bosDegerler?.some((v) => v.toLowerCase() === kirpilmis.toLowerCase())) {
      return false;
    }
    return true;
  }
  if (typeof deger === "boolean") return true; // açık/kapalı her hâlde karar verilmiştir
  if (typeof deger === "number") return Number.isFinite(deger);
  return true;
}

/**
 * Taslak verisine bakarak hazırlık raporu üretir.
 * @param draftData store_working_drafts.draft_data — kolon adına göre değerler
 * @param atlanmislar "boş geç" denen isteğe bağlı alanlar (ADR 0002, 3. alt-faz).
 *   Dolu SAYILMAZ ama doluluk yüzdesinde "işlem görmüş" sayılır — hiç
 *   sorulmamış olandan bu şekilde ayrılır.
 */
export function hazirlikRaporu(
  draftData: Record<string, unknown>,
  atlanmislar: ReadonlySet<string> = new Set(),
): HazirlikRaporu {
  const eksikler: EksikAlan[] = [];
  // "İşlem görmüş" = dolu VEYA (isteğe bağlıysa) bilerek atlanmış. Yüzde
  // artık toplam VITRIN_FIELDS.length alan üstünden — önceden yalnız temel+kalite (~11)
  // üstündendi, isteğe bağlının 32'si hiç sayılmıyordu.
  let islemGormus = 0;

  for (const alan of VITRIN_FIELDS) {
    const onem = alanOnemi(alan);
    const dolu = doluMu(draftData[alan.kolon], alan.bosDegerler);
    const atlanmisMi = onem === "istege-bagli" && atlanmislar.has(alan.anahtar);

    if (dolu || atlanmisMi) {
      islemGormus += 1;
      continue;
    }

    // İsteğe bağlı ama henüz atlanmamış/doldurulmamış alanlar "eksik"
    // sayılmaz (vitrin bunlarsız da yayına hazır) — yalnız temel/kalite
    // eksikler listede.
    if (onem === "istege-bagli") continue;

    eksikler.push({
      anahtar: alan.anahtar,
      etiket: alan.etiket,
      bolum: alan.bolum,
      onem,
    });
  }

  // Önce temel eksikler, sonra kalite eksikleri.
  eksikler.sort((a, b) =>
    a.onem === b.onem ? 0 : a.onem === "temel" ? -1 : 1,
  );

  const temelTamam = !eksikler.some((e) => e.onem === "temel");
  const ilk = eksikler[0];

  return {
    temelTamam,
    yuzde: Math.round((islemGormus / VITRIN_FIELDS.length) * 100),
    doluSayisi: islemGormus,
    toplamSayisi: VITRIN_FIELDS.length,
    eksikler,
    sonrakiAdim: ilk
      ? ilk.onem === "temel"
        ? `${ilk.etiket} eksik — vitrinin yayına hazır olması için gerekli.`
        : `${ilk.etiket} eklerseniz vitriniz daha güçlü görünür.`
      : null,
  };
}

export interface OnemDolulugu {
  dolu: number;
  toplam: number;
}

/** Üç önem sınıfının doluluğu — Faz G3 (Tek Asistan planı) `StageMeter` için.
 * Sayılar ŞEMADAN hesaplanır, elle yazılmaz (`hazirlikRaporu` ile aynı
 * `alanOnemi`/`doluMu` kuralını kullanır — iki fonksiyon aynı taramayı iki
 * biçimde yapıyor, kural tek yerde: `alanOnemi`). */
export function asamaDolulugu(
  draftData: Record<string, unknown>,
  atlanmislar: ReadonlySet<string> = new Set(),
): Record<EksikOnem, OnemDolulugu> {
  const sayaclar: Record<EksikOnem, OnemDolulugu> = {
    temel: { dolu: 0, toplam: 0 },
    kalite: { dolu: 0, toplam: 0 },
    "istege-bagli": { dolu: 0, toplam: 0 },
  };

  for (const alan of VITRIN_FIELDS) {
    const onem = alanOnemi(alan);
    sayaclar[onem].toplam += 1;
    const dolu = doluMu(draftData[alan.kolon], alan.bosDegerler);
    const atlanmisMi = onem === "istege-bagli" && atlanmislar.has(alan.anahtar);
    if (dolu || atlanmisMi) sayaclar[onem].dolu += 1;
  }

  return sayaclar;
}

/** Tüm alanlar (VITRIN_FIELDS.length adet), temel → kalite → isteğe bağlı sırasıyla (her grup kendi şema sırasında). */
export function tumAlanlarSirali(): VitrinField[] {
  const gruplar: Record<EksikOnem, VitrinField[]> = {
    temel: [],
    kalite: [],
    "istege-bagli": [],
  };
  for (const alan of VITRIN_FIELDS) {
    gruplar[alanOnemi(alan)].push(alan);
  }
  return [...gruplar.temel, ...gruplar.kalite, ...gruplar["istege-bagli"]];
}

/**
 * Rehberli akışta bir sonraki alanı bulur — Vixrex Asistan rehberli
 * tamamlama (ADR 0002): sıra öner, kullanıcı istediği alana atlarsa da
 * kaldığı yerden devam eder (`suankiAnahtar`'ın sıradaki konumundan arar).
 * İsteğe bağlı bir alan `atlanmislar`'daysa (kullanıcı "boş geç" dediyse)
 * bir daha ÖNERİLMEZ; tıklanarak yine de düzenlenebilir (yasak değil,
 * yalnız otomatik akışta atlanır).
 */
export function sonrakiRehberAlan(
  draftData: Record<string, unknown>,
  suankiAnahtar: string | null,
  atlanmislar: ReadonlySet<string>,
): VitrinField | null {
  return sonrakiRehberAlanlar(draftData, suankiAnahtar, atlanmislar, 1)[0] ?? null;
}

/**
 * `sonrakiRehberAlan`'ın çoğulu — Faz G3 (Tek Asistan planı) "Sırada"
 * listesi için: sonraki [adet] eksik alanı, aynı sıralama ve atlama
 * kurallarıyla döner. Tek alan bulan tarama mantığını tekrar yazmaz,
 * yalnız [adet]'e ulaşana kadar biriktirir.
 */
export function sonrakiRehberAlanlar(
  draftData: Record<string, unknown>,
  suankiAnahtar: string | null,
  atlanmislar: ReadonlySet<string>,
  adet: number = 3,
): VitrinField[] {
  const sirali = tumAlanlarSirali();
  const suankiIndeks = suankiAnahtar
    ? sirali.findIndex((a) => a.anahtar === suankiAnahtar)
    : -1;

  const sonuc: VitrinField[] = [];
  for (let i = suankiIndeks + 1; i < sirali.length && sonuc.length < adet; i++) {
    const alan = sirali[i];
    if (atlanmislar.has(alan.anahtar)) continue;
    if (!doluMu(draftData[alan.kolon], alan.bosDegerler)) sonuc.push(alan);
  }
  return sonuc;
}
