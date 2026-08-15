import { describe, expect, it } from "vitest";
import {
  assistantStateFromDraft,
  assistantStateFromRapor,
  upcomingActions,
} from "../src/lib/assistantState";
import { hazirlikRaporu } from "../src/lib/vitrinReadiness";
import { VITRIN_FIELDS } from "../src/lib/vitrinFieldSchema";
import { vixRexMesajlari } from "../src/lib/vixrexMesajlari";

/**
 * Faz G3 ön işi (Tek Asistan planı): AssistantState'in Next.js ikizi.
 * Golden test — aynı taslak verildiğinde `hazirlikRaporu` ile
 * `assistantStateFromDraft` aynı doluluk/sıradaki-alan cevabını vermeli.
 * Dart tarafındaki eşleniği: test/assistant_state_test.dart.
 */
describe("assistantStateFromRapor — hazirlikRaporu ile tutarlılık", () => {
  it("boş taslakta: kurulum aşaması, ilk temel alan sıradaki eksik", () => {
    const rapor = hazirlikRaporu({});
    const state = assistantStateFromRapor(rapor);

    expect(state.asama).toBe("kurulum");
    expect(state.sonrakiEksikAlan?.anahtar).toBe(rapor.eksikler[0]?.anahtar);
    expect(state.doluluk).toBe(rapor.yuzde);
    expect(state.doluAlan).toBe(rapor.doluSayisi);
    expect(state.toplamAlan).toBe(rapor.toplamSayisi);
    expect(state.eylemler).toHaveLength(1);
    expect(state.eylemler[0]?.primary).toBe(true);
    expect(state.eylemler[0]?.hedefAlan).toBe(rapor.eksikler[0]?.anahtar);
  });

  it("her şey dolu/atlanmışsa: gelistirme aşaması, sıradaki eksik yok", () => {
    const draft: Record<string, unknown> = {};
    const atlanmislar = new Set<string>();
    for (const alan of VITRIN_FIELDS) {
      if (!alan.zorunlu && !alan.kalite) {
        atlanmislar.add(alan.anahtar);
      } else {
        draft[alan.kolon] = "dolu";
      }
    }
    const rapor = hazirlikRaporu(draft, atlanmislar);
    const state = assistantStateFromRapor(rapor);

    expect(rapor.temelTamam).toBe(true);
    expect(state.asama).toBe("gelistirme");
    expect(state.sonrakiEksikAlan).toBeNull();
    expect(state.eylemler).toEqual([]);
    expect(state.mesajAnahtari).toBeNull();
    expect(state.sonrakiAdimCumlesi).toBeNull();
    expect(state.doluluk).toBe(100);
  });

  it("boş taslakta ilk eksik alan işletme adı — mesajAnahtari katalogdaki setup_name'e eşlenir", () => {
    const rapor = hazirlikRaporu({});
    const state = assistantStateFromRapor(rapor);
    expect(rapor.eksikler[0]?.anahtar).toBe("isletmeAdi");
    expect(state.mesajAnahtari).toBe("setup_name");
  });

  it("sonrakiAdimCumlesi, Flutter'ın da okuduğu AYNI katalog metnini taşır", () => {
    const rapor = hazirlikRaporu({});
    const state = assistantStateFromRapor(rapor);
    expect(state.sonrakiAdimCumlesi).toContain(
      vixRexMesajlari["setup_name_baslik"],
    );
    expect(state.sonrakiAdimCumlesi).toContain(
      vixRexMesajlari["setup_name_aciklama"],
    );
  });

  it("katalogda karşılığı olmayan bir alan için genel şablona düşer", () => {
    // hazirlikRaporu().eksikler yapısal olarak yalnız temel+kalite
    // alanlarını taşır (istege-bagli hiç girmez) ve ALAN_ONERI_ID bu
    // ikisinin tamamını kapsıyor — o yüzden bu dal normal akışta hiç
    // tetiklenmez. Yine de savunma amaçlı var (şemaya yeni bir zorunlu/
    // kalite alan eklenip ALAN_ONERI_ID'ye bağlanmazsa boş metin yerine
    // genel şablon gösterir). Sentetik bir rapor ile doğrudan test edilir.
    const sahteRapor = {
      temelTamam: false,
      yuzde: 10,
      doluSayisi: 1,
      toplamSayisi: 10,
      eksikler: [
        {
          anahtar: "hic-boyle-bir-alan-yok",
          etiket: "Uydurma Alan",
          bolum: "hero" as const,
          onem: "temel" as const,
        },
      ],
      sonrakiAdim: "Uydurma Alan eksik — genel şablon metni.",
    };
    const state = assistantStateFromRapor(sahteRapor);

    expect(state.mesajAnahtari).toBeNull();
    expect(state.sonrakiAdimCumlesi).toBe(sahteRapor.sonrakiAdim);
  });

  it("assistantStateFromDraft, hazirlikRaporu+assistantStateFromRapor'un kısayoludur", () => {
    const draft = { name: "Test" };
    const dolayli = assistantStateFromRapor(hazirlikRaporu(draft));
    const dogrudan = assistantStateFromDraft(draft);
    expect(dogrudan).toEqual(dolayli);
  });
});

describe("upcomingActions", () => {
  it("boş taslakta ilk 3 temel alanı eylem olarak döner", () => {
    const eylemler = upcomingActions({}, null, new Set(), 3);
    expect(eylemler).toHaveLength(3);
    expect(eylemler[0]?.primary).toBe(true);
    expect(eylemler[1]?.primary).toBe(false);
    expect(eylemler[2]?.primary).toBe(false);
  });

  it("her eylemin label'ı alanın etiketidir", () => {
    const eylemler = upcomingActions({}, null, new Set(), 1);
    const beklenenEtiket = VITRIN_FIELDS.find(
      (a) => a.anahtar === eylemler[0]?.hedefAlan,
    )?.etiket;
    expect(eylemler[0]?.label).toBe(beklenenEtiket);
  });
});
