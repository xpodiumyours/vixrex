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
import {
  hazirlikRaporu,
  sonrakiRehberAlanlar,
  type EksikAlan,
  type HazirlikRaporu,
} from "./vitrinReadiness";

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
  /** Öneri metninin anahtarı. Faz B kataloğu (shared/vixrex_mesajlar.json)
   * şu an yalnız sohbet-niyet yanıtlarını taşıyor, rehberlik önerisi
   * metnini değil (Dart tarafındaki aynı not — bkz.
   * lib/services/vixrex_guidance_service.dart). Bu alan bugün
   * `alan_<anahtar>` biçiminde kararlı bir kimlik taşır; gerçek metin
   * `hazirlikRaporu().sonrakiAdim`'den (zaten üretilmiş cümle) gelir. */
  mesajAnahtari: string;
  /** Sıralı eylem listesi, ilki birincil. */
  eylemler: AssistantAction[];
  doluluk: number;
  doluAlan: number;
  toplamAlan: number;
}

/** Zaten hesaplanmış bir `HazirlikRaporu`dan `AssistantState` üretir —
 * kendi kararını üretmez, yalnız biçimini tekilleştirir (Faz E'nin Dart
 * tarafındaki kuralıyla aynı). */
export function assistantStateFromRapor(rapor: HazirlikRaporu): AssistantState {
  const ilk = rapor.eksikler[0] ?? null;

  return {
    asama: rapor.temelTamam ? "gelistirme" : "kurulum",
    sonrakiEksikAlan: ilk,
    mesajAnahtari: ilk ? `alan_${ilk.anahtar}` : "tum_alanlar_tamam",
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
