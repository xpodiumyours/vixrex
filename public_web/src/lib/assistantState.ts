// Vixrex'in "sırada ne var" kararının Next.js tarafındaki biçimi.
//
// Faz E (Flutter, lib/models/assistant_state.dart) ile Faz G3 arasındaki
// boşluğu kapatır — PLAN.md Faz G3: "hazirlikRaporu çıktısı AssistantState'in
// TS ikizine map edilir (lib/assistantState.ts) — aynı alan adları, aynı
// anlam." Bu dosya o eşlemeyi kurar.
//
// DÜRÜSTLÜK NOTU: Dart'ın AssistantState'i Flutter'ın SOHBET AKIŞI
// (kurulum → yayın → paylaşım) etrafında kurulu — VixRexNextStep enum'u
// "name/whatsapp/address/legal/publish/share" gibi akış duraklarını taşır.
// Next.js'in sahip paneli farklı bir bağlamda çalışır: buraya yalnız
// ZATEN VAR olan (taslağı oluşturulmuş) bir vitrin için gelinir — "önce
// yayınla" gibi bir akış durağı burada anlamsız. Bu yüzden alan adları
// birebir aynı DEĞİL; anlamca karşılık gelen kısım (doluluk, sıradaki eksik
// alan, birincil eylem) aktarıldı, Flutter'a özgü akış kavramları
// (VixRexNextStep, publish/share fazları) zorla taşınmadı.
//
// KATALOG BAĞLANTISI (2026-08-15): şemadaki her zorunlu/kalite alanın
// Flutter'ın VixRexGuidanceService'inde bir karşılığı var — o kalemin
// başlık/açıklama/buton metni artık shared/vixrex_mesajlar.json'da
// (`<id>_baslik` vb.). ALAN_ONERI_ID eşlemesi bu dosyanın anahtarını o
// öneri id'sine bağlar; TS ve Dart AYNI cümleyi okur. İsteğe bağlı 31
// alanın (kisaTanitim hariç) Flutter'da özel bir önerisi hiç olmadı — bu
// alanlar için `hazirlikRaporu().sonrakiAdim`'in genel şablonuna düşülür,
// uydurma bir eşleme YAZILMADI.
import {
  hazirlikRaporu,
  sonrakiRehberAlanlar,
  type EksikAlan,
  type HazirlikRaporu,
} from "./vitrinReadiness";
import { vixRexMesajlari } from "./vixrexMesajlari";

/** Dart'ın `VixRexJourneyPhase`sinin Next.js'teki karşılığı — yalnız iki
 * hâl var çünkü sahip paneline yalnız var olan bir taslak için gelinir. */
export type AssistantJourneyPhase = "kurulum" | "gelistirme";

/** [AssistantState.eylemler] öğesi. Dart'ın `VixRexAction` enum'u (ekran
 * navigasyonu) burada karşılığı yok — Next.js'te "eylem" bir alana
 * odaklanmak/kaydırmaktır, `hedefAlan` bu yüzden bir enum değil şema
 * anahtarı taşır. */
export interface AssistantAction {
  hedefAlan: string | null;
  label: string;
  primary: boolean;
}

export interface AssistantState {
  asama: AssistantJourneyPhase;
  /** Sıradaki eksik alan — şemadan, sırası da şemadan. `null` ise eksik yok. */
  sonrakiEksikAlan: EksikAlan | null;
  /** Öneri metninin kataloğa gerçekten karşılık gelen anahtarı (ör.
   * "setup_category", "improve_cover") — eşleme yoksa null; o durumda
   * [sonrakiAdimCumlesi] genel şablondan gelir. */
  mesajAnahtari: string | null;
  /** Kullanıcıya gösterilecek tek cümle. Eşleme varsa katalogdan
   * (Flutter'la AYNI metin), yoksa `hazirlikRaporu().sonrakiAdim`'in genel
   * şablonundan. */
  sonrakiAdimCumlesi: string | null;
  /** Sıralı eylem listesi, ilki birincil. */
  eylemler: AssistantAction[];
  doluluk: number;
  doluAlan: number;
  toplamAlan: number;
}

/** Şema anahtarı → `shared/vixrex_mesajlar.json`'daki öneri id'si.
 * `lib/services/vixrex_guidance_service.dart`'ın hangi alan için hangi
 * öneriyi gösterdiğinin bire bir aynısı — elle senkron tutulur (ikisi de
 * aynı JSON'u okuduğu için METİN sapmaz, yalnız bu EŞLEME tablosu iki
 * dilde ayrı yazılı; biri değişirse öbürü unutulabilir, bu Faz F'nin ADR
 * 0001 kategori-2 riskiyle aynı — bilinçli, düşük etkili). */
const ALAN_ONERI_ID: Readonly<Record<string, string>> = {
  isletmeAdi: "setup_name",
  kategori: "setup_category",
  whatsapp: "setup_whatsapp",
  adres: "setup_address",
  il: "setup_address",
  ilce: "setup_address",
  kapakGorseli: "improve_cover",
  heroRozet: "improve_hero_badge",
  logo: "improve_logo",
  calismaSaatleri: "improve_working_hours",
  haritaLinki: "improve_google_link",
  hakkindaBaslik: "improve_about_title",
  hakkindaMetin: "improve_about_bio",
  kisaTanitim: "improve_desc",
};

function katalogCumlesi(oneriId: string): string {
  const baslik = vixRexMesajlari[`${oneriId}_baslik`];
  const aciklama = vixRexMesajlari[`${oneriId}_aciklama`];
  return baslik && aciklama ? `${baslik} — ${aciklama}` : (aciklama ?? baslik ?? "");
}

/** Zaten hesaplanmış bir `HazirlikRaporu`dan `AssistantState` üretir —
 * kendi kararını üretmez, yalnız biçimini tekilleştirir (Faz E'nin Dart
 * tarafındaki kuralıyla aynı). */
export function assistantStateFromRapor(rapor: HazirlikRaporu): AssistantState {
  const ilk = rapor.eksikler[0] ?? null;
  const oneriId = ilk ? (ALAN_ONERI_ID[ilk.anahtar] ?? null) : null;

  return {
    asama: rapor.temelTamam ? "gelistirme" : "kurulum",
    sonrakiEksikAlan: ilk,
    mesajAnahtari: oneriId,
    sonrakiAdimCumlesi: oneriId ? katalogCumlesi(oneriId) : rapor.sonrakiAdim,
    eylemler: ilk
      ? [{ hedefAlan: ilk.anahtar, label: `${ilk.etiket} ekle`, primary: true }]
      : [],
    doluluk: rapor.yuzde,
    doluAlan: rapor.doluSayisi,
    toplamAlan: rapor.toplamSayisi,
  };
}

/** `draftData`'dan doğrudan `AssistantState` üretir — `hazirlikRaporu` +
 * `assistantStateFromRapor`'u art arda çağırmanın kısayolu. */
export function assistantStateFromDraft(
  draftData: Record<string, unknown>,
  atlanmislar: ReadonlySet<string> = new Set(),
): AssistantState {
  return assistantStateFromRapor(hazirlikRaporu(draftData, atlanmislar));
}

/** "Sırada" listesi (Faz G3, `UpNextList`) için — sonraki [adet] eksik
 * alanı birincil eylem biçiminde döner. */
export function upcomingActions(
  draftData: Record<string, unknown>,
  suankiAnahtar: string | null,
  atlanmislar: ReadonlySet<string>,
  adet: number = 3,
): AssistantAction[] {
  return sonrakiRehberAlanlar(draftData, suankiAnahtar, atlanmislar, adet).map(
    (alan, index) => ({
      hedefAlan: alan.anahtar,
      label: alan.etiket,
      primary: index === 0,
    }),
  );
}
