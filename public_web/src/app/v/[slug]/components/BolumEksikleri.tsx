import {
  SECTION_DOM_ID,
  SECTION_LABELS,
  fieldsOfSection,
  type VitrinField,
  type VitrinSection,
} from "@/lib/vitrinFieldSchema";
import { doluMu } from "@/lib/vitrinReadiness";
import { editableProps } from "@/lib/vitrinEditableProps";

// 2026-08-22 — "her alanın sayfada bir yeri olsun" (Faz 1).
//
// SORUN: rehber balonu hedefini `[data-vixrex-editable="<anahtar>"]` ile
// arıyor (SpotlightGuide). Ama o işaret bugün yalnız alan DOLUYSA DOM'a
// giriyordu: bölümler yalnız içi doluysa çiziliyor, alan işaretleri de
// çoğu yerde `{deger && (...)}` içinde. Yani rehber tam da doldurmak
// istediğimiz boş alanlara ulaşamıyordu — balon hiç açılmıyordu. 46
// alandan 9'unun (il, ilçe dahil, ikisi de YAYIN İÇİN ZORUNLU) sayfada
// hiç yeri yoktu.
//
// ÇÖZÜM: bölüm başına tek bir şerit. Gösterilecek alanları ŞEMADAN bulur,
// her biri için gerçek bir `data-vixrex-editable` işareti çizer. Alan
// başına kod yoktur; şemaya yeni satır eklenince kendiliğinden çıkar.
//
// Bu bir FORM DEĞİLDİR (VIXREX_RULES §1 — "ikinci form paneli açılmaz"):
// buradaki düğmeler hiçbir şey kaydetmez, yalnız mevcut seçim akışını
// tetikler. Tıklamayı `useFieldSelection`'daki tek global dinleyici
// yakalar; bu dosya kendi dinleyicisini kurmaz.
//
// MÜŞTERİ GÖRÜNÜMÜ HİÇ DEĞİŞMEZ: `ownerMode` kapalıyken null döner,
// DOM'a tek öznitelik bile girmez (vitrinEditableProps.ts ile aynı sınır).

/**
 * Vitrinde KENDİ görünen öğesi hiç olmayan alanlar.
 *
 * Bu bir SAYFA bilgisidir, şema bilgisi değil — o yüzden şemaya değil
 * buraya yazılır. Değerleri sayfada ya hiç görünmez (enlem/boylam), ya
 * dolaylı kullanılır (il/ilçe yalnız hero konum metni boşken birleşik
 * gösterilir; instagram bir ikon linki; galeriAksiyonLinki bir href;
 * yolTarifiGoster bir düğmeyi açıp kapatır).
 *
 * Bunlar DOLDUKTAN SONRA da şeritte kalır — yoksa esnaf yanlış yazdığı
 * ilçeyi bir daha düzeltemez (2026-08-22'de ölçülerek bulundu).
 *
 * Listenin doğruluğunu `tests/her-alanin-sayfada-yeri.test.ts` bekçiler:
 * dolu bir vitrinde bile 46 alanın hepsi erişilebilir olmalı. Sayfaya
 * yeni bir işaret eklenirse alan bu listeden çıkarılır, test söyler.
 */
const SAYFADA_KENDI_YERI_OLMAYANLAR: ReadonlySet<string> = new Set([
  "isletmeTuru",
  "il",
  "ilce",
  "mahalle",
  "instagram",
  "enlem",
  "boylam",
  "galeriAksiyonLinki",
  "yolTarifiGoster",
  // Aç/kapa alanları `doluMu` için HER HÂLDE doludur ("karar verilmiş"
  // sayılır), ama kapalıyken sayfada gösterecek bir şeyleri de yoktur —
  // yani kapatan esnaf bir daha açamazdı. `puanGoster` bunu gerçek bir
  // vitrinde yaptı (2026-08-22, yerel test): puan kapalı + puan değeri
  // yok → ne rozet çizildi ne şeritte çıktı, alan tamamen kayboldu.
  "puanGoster",
]);

interface Props {
  bolum: VitrinSection;
  /** Sahip modundaki çalışma taslağı (`draft_data`). Ziyaretçide undefined. */
  taslak?: Record<string, unknown>;
  ownerMode?: boolean;
}

/** Şeritte yer alacak alanlar — sıra şemadaki sıradır. */
function seritAlanlari(
  bolum: VitrinSection,
  taslak: Record<string, unknown>,
): VitrinField[] {
  return fieldsOfSection(bolum).filter(
    (alan) =>
      !doluMu(taslak[alan.kolon], alan.bosDegerler) ||
      SAYFADA_KENDI_YERI_OLMAYANLAR.has(alan.anahtar),
  );
}

/** Dolu bir alanın şeritte gösterilecek kısa değeri. */
function kisaDeger(deger: unknown): string | null {
  if (deger === null || deger === undefined) return null;
  if (typeof deger === "boolean") return deger ? "Açık" : "Kapalı";
  const metin = String(deger).trim();
  if (!metin) return null;
  return metin.length > 24 ? `${metin.slice(0, 24)}…` : metin;
}

/** Bölümün altındaki soluk "buraya eklenebilir" şeridi. */
export function BolumEksikleri({
  bolum,
  taslak,
  ownerMode,
  sade = false,
}: Props & { sade?: boolean }) {
  if (!ownerMode || !taslak) return null;

  const alanlar = seritAlanlari(bolum, taslak);
  if (alanlar.length === 0) return null;

  return (
    <div
      className={
        sade
          ? "mt-2"
          : "mt-6 rounded-xl border border-white/[0.06] bg-white/[0.02] px-4 py-3"
      }
    >
      {!sade && (
        <p className="mb-2 text-[11px] font-semibold uppercase tracking-wider text-slate-500">
          Bu bölüme eklenebilir
        </p>
      )}
      <div className="flex flex-wrap gap-1.5">
        {alanlar.map((alan) => {
          const dolu = doluMu(taslak[alan.kolon], alan.bosDegerler);
          const deger = dolu ? kisaDeger(taslak[alan.kolon]) : null;
          return (
            <button
              key={alan.anahtar}
              type="button"
              aria-label={`${alan.etiket} — ${dolu ? "değiştir" : "ekle"}`}
              {...editableProps(alan.anahtar, ownerMode)}
              className={`rounded-full border px-3 py-1 text-[11px] font-medium transition ${
                dolu
                  ? "border-white/10 bg-white/[0.06] text-slate-300 hover:bg-white/10"
                  : "border-dashed border-white/20 bg-white/[0.03] text-slate-400 hover:bg-white/10 hover:text-slate-200"
              }`}
            >
              {dolu ? alan.etiket : `+ ${alan.etiket}`}
              {deger && <span className="ml-1.5 text-slate-500">{deger}</span>}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/** Müşteriye hiç görünmeyen bir bölümün sahip modundaki ince iskeleti.
 *
 * Bölüm gizliyken (ör. `showAbout` false) içindeki alanların sayfada
 * hiçbir yeri olmuyordu; rehber oraya gidemiyordu. İskelet o alanlara bir
 * ev verir.
 *
 * DÜRÜSTLÜK: "doldurunca bölüm görünür" DENMEZ — bazı bölümlerin görünmesi
 * koleksiyona bağlı (galeri karesi, yazı, soru), tek bir başlık yazmak
 * yetmez. Söylenen yalnız doğru olan: bölüm şu an görünmüyor.
 */
export function BolumIskeleti({ bolum, taslak, ownerMode }: Props) {
  if (!ownerMode || !taslak) return null;
  if (seritAlanlari(bolum, taslak).length === 0) return null;

  return (
    // Kimlik gerçek bölümle aynı: bölüm gizliyken de rehber "önce bölüme
    // in, sonra alana yaklaş" adımını uygulayabilsin (Faz 3b). Gerçek
    // bölümle iskelet asla birlikte çizilmez, kimlik çakışmaz.
    <section
      id={SECTION_DOM_ID[bolum]}
      className="max-w-7xl mx-auto px-6 sm:px-8 py-4"
    >
      {/* 2026-09-03: her gizli bölüm için dev kesikli kutu + aynı iki
       * cümlelik açıklama çiziliyordu; vitrin dükkân değil şantiye gibi
       * duruyordu (ekran görüntüsüyle görüldü). Kutu tek satırlık sakin
       * bir şeride indi. Tamamen kaldırmıyoruz: rehberin gizli bölümdeki
       * alana yürüyebilmesi için o alanların sayfada bir yeri olmalı. */}
      <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] px-4 py-2.5">
        <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-slate-500">
          {SECTION_LABELS[bolum]}
          <span className="ml-2 normal-case tracking-normal text-slate-600">
            müşteriye görünmüyor
          </span>
        </p>
        <BolumEksikleri bolum={bolum} taslak={taslak} ownerMode={ownerMode} sade />
      </div>
    </section>
  );
}
