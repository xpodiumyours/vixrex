import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * Serbest metinle alan doldurma (2026-09-02) — kullanıcı NET olarak yeni
 * bir ekran elemanı istemedi, "sadece çalışmasında ve niyetinde değişiklik"
 * istedi. Bu yüzden ayrı bir kart YOK — mevcut soru kutusuna (gonder(),
 * useOwnerActions.ts) doğrudan cevaplanmayan alanları da bulan bir
 * "bonus çıkarım" eklendi. Panelin görünümü/DOM'u bu özellik için hiç
 * değişmedi.
 */
describe("OwnerAssistantPanel — yeni bir ekran elemanı yok", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("panelde serbest anlatım kartına/state'ine dair hiçbir iz yok", () => {
    expect(panel).not.toContain("anlatimAcik");
    expect(panel).not.toContain("IsletmeniAnlatKarti");
    expect(panel).not.toContain("serbestMetindenAlanlariCikar");
  });

  it("panel açılınca otomatik ilk-alan seçimi eski (2026-08-22'den beri değişmemiş) hâliyle çalışıyor", () => {
    expect(panel).toContain("if (!acik || seciliAlan) return;");
  });
});

describe("useOwnerActions.gonder() — mevcut kutuya bonus çıkarım katıldı", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerActions.ts");

  it("yalnız gonder()'ın (metin girişi) başarılı akışının İÇİNDE tetiklenir — ayrı bir buton/kart yok", () => {
    const gonderBaslangici = kaynak.indexOf("const gonder = useCallback(async () => {");
    const cagriIndex = kaynak.indexOf("bonusAlanlariCikarVeKaydet(", gonderBaslangici);
    expect(cagriIndex).toBeGreaterThan(gonderBaslangici);
  });

  it("kısa/tek kelimelik cevaplarda gereksiz yere çalışmaz (uzunluk eşiği var)", () => {
    expect(kaynak).toContain("metin.length >= 15");
  });

  it("az önce doğrudan cevaplanan alanın kolonu bonus setinden hariç tutulur — çift yazma yok", () => {
    expect(kaynak).toContain("alan.kolon === cevaplananKolon");
  });

  it("bonus başarısız olursa asıl kayıt/akış hiç etkilenmez — sessizce yutulur", () => {
    const idx = kaynak.indexOf("async function bonusAlanlariCikarVeKaydet");
    const fonksiyon = kaynak.slice(idx, idx + 1600);
    expect(fonksiyon).toContain("} catch {");
    expect(fonksiyon).toContain("Bonus bir zenginleştirme");
  });

  it("bonus bulunca aynı ✓ liste stilini kullanır (D3'teki desenle aynı)", () => {
    expect(kaynak).toContain("Yazdığından ayrıca şunları da anladım");
    expect(kaynak).toContain("basarili.map(({ etiket }) => `✓ ${etiket}`)");
  });
});

/**
 * Abstain (2026-09-03, Casper canlıda buldu): "işletme adım Konak Kafe,
 * whatsapp numaram 0542..." gibi zengin bir cümle İŞLETME ADI kutusu
 * seçiliyken yazılırsa, telefon numarası ham hâliyle isim alanına
 * yapışıyordu — bonus çıkarım işletme adını KASITLI OLARAK hiç
 * hedeflemiyor (serbestMetinCikarim.ts), o yüzden kapsamı dışındaki bir
 * alan için "hangi kısım kime ait" bölünemez. Düzeltme: kapsam dışı bir
 * alan seçiliyken cümlede başka tanınan alana ait ipucu varsa, ham cümle
 * o alana YAZILMAZ — dürüstçe sorulur, bonus diğer alanları yine kaydeder.
 */
describe("useOwnerActions.gonder() — kapsam dışı alanda zengin cümle yazılırsa (abstain)", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerActions.ts");

  it("bonusun kapsadığı gerçek kolonlar ayrı bir sabitte toplanır", () => {
    expect(kaynak).toContain("BONUS_KAPSAMINDAKI_KOLONLAR");
    expect(kaynak).toMatch(
      /BONUS_KAPSAMINDAKI_KOLONLAR[\s\S]*?=\s*new Set\(/,
    );
  });

  it("seçili alan kapsam dışıysa VE cümlede başka alan ipucu varsa ham cümle o alana kaydedilmez", () => {
    const gonderBaslangici = kaynak.indexOf(
      "const gonder = useCallback(async () => {",
    );
    // Abstain kontrolü, ham kaydetmeden (fetch("/api/owner-draft")) ÖNCE gelir.
    const abstainIndex = kaynak.indexOf(
      "!BONUS_KAPSAMINDAKI_KOLONLAR.has(alan.kolon)",
    );
    // Bilerek abstainIndex'TEN sonra aranır — `!seciliAlan` dalındaki
    // (NLU çoklu alan kaydı) daha ERKEN bir fetch çağrısı var, o farklı
    // bir yol; burada aranan seçili-tek-alan kaydının fetch'i.
    const fetchIndex = kaynak.indexOf('fetch("/api/owner-draft"', abstainIndex);
    expect(abstainIndex).toBeGreaterThan(gonderBaslangici);
    expect(fetchIndex).toBeGreaterThan(-1);
    expect(abstainIndex).toBeLessThan(fetchIndex);
  });

  it("abstain durumunda seçili alan DEĞİŞTİRİLMEZ — alanaGecVeyaBitir çağrılmadan return eder", () => {
    const abstainIndex = kaynak.indexOf(
      "!BONUS_KAPSAMINDAKI_KOLONLAR.has(alan.kolon)",
    );
    const blokSonu = kaynak.indexOf("\n    }\n\n    const gonderilecek", abstainIndex);
    const blok = kaynak.slice(abstainIndex, blokSonu);
    expect(blok).not.toContain("alanaGecVeyaBitir");
    expect(blok).toContain("return;");
  });

  it("abstain mesajı dürüstçe sorar, 'kaydettim' demez; bonus yine tetiklenir", () => {
    const abstainIndex = kaynak.indexOf(
      "!BONUS_KAPSAMINDAKI_KOLONLAR.has(alan.kolon)",
    );
    const blokSonu = kaynak.indexOf("\n    }\n\n    const gonderilecek", abstainIndex);
    const blok = kaynak.slice(abstainIndex, blokSonu);
    expect(blok).toContain("birden fazla bilgi var gibi görünüyor");
    expect(blok).toContain("bonusAlanlariCikarVeKaydet(metin, \"\"");
  });
});
