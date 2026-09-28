import { readFileSync } from "fs";
import { resolve } from "path";
import { describe, expect, it } from "vitest";

// Faz 2 (2026-08-22) — "yazdığın anda sayfa değişsin".
//
// Vitrin sayfası sunucuda çiziliyor; sahip panelinin `yerelTaslak`'ı ise
// istemci tarafında ayrı duruyor. Kaydetme yolları yalnız yerel kopyayı
// güncelliyordu — esnaf kaydediyor, balon sıradaki alana geçiyor, ama
// sayfadaki yazı eski kalıyordu. `router.refresh()` sunucudan yeniden
// okutur; desen zaten yayınla/bırak/canlıya-döndür yollarında vardı.
//
// Ortam "node" (bkz. vitest.config.ts) — hook'u gerçekten çalıştıracak
// bir DOM yok. Bu yüzden depodaki diğer sözleşme testleri gibi kaynak
// üzerinden ölçülüyor (bkz. spotlight-guide-contract.test.ts).

const actionsPath = resolve(
  __dirname,
  "../src/app/v/[slug]/hooks/useOwnerActions.ts",
);
const spotlightPath = resolve(
  __dirname,
  "../src/app/v/[slug]/components/SpotlightGuide.tsx",
);
const panelPath = resolve(__dirname, "../src/app/v/[slug]/OwnerAssistantPanel.tsx");

const actionsSource = readFileSync(actionsPath, "utf8");
const spotlightSource = readFileSync(spotlightPath, "utf8");
const panelSource = readFileSync(panelPath, "utf8");

/** Bir `const <ad> = useCallback(` bloğunun gövdesi. */
function callbackGovdesi(kaynak: string, ad: string): string {
  const bas = kaynak.indexOf(`const ${ad} = useCallback(`);
  if (bas === -1) throw new Error(`${ad} bulunamadı`);
  const son = kaynak.indexOf("\n  );", bas);
  const son2 = kaynak.indexOf("\n  }, [", bas);
  const bitis = [son, son2].filter((i) => i > bas).sort((a, b) => a - b)[0];
  if (bitis === undefined) throw new Error(`${ad} gövdesi kapanmıyor`);
  return kaynak.slice(bas, bitis);
}

describe("kaydetme sayfayı tazeler", () => {
  it.each(["gonder", "gorselYukle", "hazirGorselSec"])(
    "%s başarılı kayıttan sonra router.refresh() çağırır",
    (ad) => {
      const govde = callbackGovdesi(actionsSource, ad);
      expect(govde).toContain("router.refresh()");
    },
  );

  it("tazeleme yerel kopyayı güncellemenin YERİNE geçmez, yanına gelir", () => {
    // İkisi birlikte olmalı: setAlan anında tepki verir (panel), refresh
    // sunucudan doğrulanmış hâli getirir (sayfa). Biri silinirse ya panel
    // ya sayfa geride kalır.
    // (2026-09-25) Alan kayıt yolu gonder'den kaydetSeciliAlana'a ayrıldı
    // (döngü kırıcı); sözleşme yeni yerde ölçülür.
    const govde = callbackGovdesi(actionsSource, "kaydetSeciliAlana");
    expect(govde).toContain("setAlan(alan.kolon, gonderilecek)");
    expect(govde).toContain("router.refresh()");
  });

  it("kaydedilen alan sayfada kısa süre parlatılır", () => {
    expect(actionsSource).toContain("function alaniParlat");
    expect(actionsSource).toContain('const PARLAMA_SINIFI = "vixrex-degisti"');
    for (const ad of ["kaydetSeciliAlana", "gorselYukle", "hazirGorselSec"]) {
      expect(callbackGovdesi(actionsSource, ad)).toContain(
        "alaniParlat(alan.anahtar)",
      );
    }
  });
});

describe("balon tazeleme sonrası hedefi kaybetmez", () => {
  it("ölçüm sabit setInterval yerine kare kare (rAF) yapılır", () => {
    expect(spotlightSource).toContain("requestAnimationFrame");
    expect(spotlightSource).toContain("cancelAnimationFrame");
    // Yorumda geçen "setInterval" değil, GERÇEK çağrı aranır.
    expect(spotlightSource).not.toMatch(/setInterval\(/);
  });

  it("sayfa içeriği büyüyüp küçülünce yeniden ölçülür", () => {
    expect(spotlightSource).toContain("ResizeObserver");
    expect(spotlightSource).toContain("govdeIzleyici?.disconnect()");
  });

  it("taslak değişince ölçüm yeniden tetiklenir", () => {
    expect(spotlightSource).toContain("olcumTetikleyici");
    expect(spotlightSource).toMatch(/\}, \[konumuGuncelle, olcumTetikleyici\]\);/);
    expect(panelSource).toContain("olcumTetikleyici={yerelTaslak}");
  });

  it("ölçüm değişmediyse state'e yazılmaz (kare kare boş çizim olmasın)", () => {
    expect(spotlightSource).toContain("setRect((onceki) =>");
    expect(spotlightSource).toContain("setViewport((onceki) =>");
  });
});

describe("kayıt sürerken sayfada iz kalır", () => {
  it("panel kaydetme sırasında body sınıfını açıp kapatır", () => {
    expect(panelSource).toContain(
      'document.body.classList.toggle("vixrex-kaydediliyor", actions.kaydediliyor)',
    );
    expect(panelSource).toContain(
      'document.body.classList.remove("vixrex-kaydediliyor")',
    );
  });

  it("stiller globals.css'te tanımlı ve hareket azaltmaya saygılı", () => {
    const css = readFileSync(resolve(__dirname, "../src/app/globals.css"), "utf8");
    expect(css).toContain(".vixrex-degisti");
    expect(css).toContain("body.vixrex-kaydediliyor .vixrex-secili-alan");
    expect(css).toContain("prefers-reduced-motion");
  });
});
