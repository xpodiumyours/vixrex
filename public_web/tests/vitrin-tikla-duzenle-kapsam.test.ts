import { describe, expect, it } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import { VITRIN_FIELDS } from "@/lib/vitrinFieldSchema";

// Tıkla-düzenle kapsam nöbetçisi (issue #215, Commit 9).
//
// Vitrinde "yazıya tıkla, düzenle" kısayolu (editableProps) her alan için
// kurulu olmalı. Şemaya yeni alan eklenip buraya düşmemesi için: her alan
// ya VitrinProfileView.tsx içinde editableProps("<anahtar>" çağrısıyla
// etiketlidir, ya da aşağıdaki istisna listesinde GEREKÇESİYLE yer alır.
// İstisna listesi yorum değil, gerçek bir sabittir — denetlenebilir.
//
// Kapsam yalnız VitrinProfileView.tsx; "Tüm alanlar" paneli
// (tests/tum-alanlar-erisim.test.ts) bu işin dışında, dokunulmaz.

const view = readFileSync(
  resolve(__dirname, "../src/app/v/[slug]/VitrinProfileView.tsx"),
  "utf-8"
);

// Bilinçli istisnalar — her biri gerekçesiyle. Issue #215 Out of Scope
// listesi + Commit 4'ün açık sınırı (galeriAksiyonLinki).
const TIKLAMA_ISTISNALARI: Record<string, string> = {
  isletmeTuru:
    "Kendi DOM elemanı yok — heroRozet/kategori ile aynı fallback zincirini (displayBadge) paylaşıyor.",
  il: "Tek bir birleşik span'da (districtProvinceLabel) gösteriliyor; ayrı ayrı tıklanabilir değil.",
  ilce: "Aynı birleşik span (districtProvinceLabel); ayırmak yeni UI kararı gerektirir.",
  enlem: "Sayfada metin olarak görünmüyor — yalnız harita gömme linkini (mapsEmbedUrl) üretiyor.",
  boylam: "Aynı — sayfada görünmüyor, yalnız harita linkini üretiyor.",
  yolTarifiGoster:
    "Ayrı bulgu adayı (buton mapsUrl doluluğuna bakıyor); issue #215 kapsamı dışında.",
  galeriAksiyonLinki:
    "galeriAksiyonMetni ile aynı tek elemanda gösteriliyor; bir elemana yalnız BİR alan etiketlenir (issue #215 Commit 4 — bilinçli sınır, href panelden düzenlenir).",
};

describe("Tıkla-düzenle kapsamı — şemadaki her alan ya etiketli ya gerekçeli istisna", () => {
  it("her alan ya editableProps ile işaretli ya da istisna listesinde", () => {
    for (const alan of VITRIN_FIELDS) {
      const etiketli = view.includes(`editableProps("${alan.anahtar}"`);
      const istisna = alan.anahtar in TIKLAMA_ISTISNALARI;
      expect(
        etiketli || istisna,
        `"${alan.anahtar}" (${alan.etiket}): ne editableProps ile işaretli ne de TIKLAMA_ISTISNALARI listesinde — "render ediliyor ama etiketlenmemiş" durumuna düşmüş`
      ).toBe(true);
    }
  });

  it("istisnalar gerekçeli — boş/kısa gerekçe olmaz", () => {
    for (const [anahtar, gerekce] of Object.entries(TIKLAMA_ISTISNALARI)) {
      expect(
        gerekce.trim().length,
        `"${anahtar}" istisnasının gerekçesi eksik`
      ).toBeGreaterThan(30);
    }
  });

  it("kullanılan etiketler şemada tanımlı alanlar", () => {
    // EYLEM_ALANI[buton.anahtar] ?? "" dinamik çağrısı boş dize üretir — atlanır.
    const cagrilar = [...view.matchAll(/editableProps\("([^"]*)"(?:,|\))/g)].map(
      (m) => m[1]
    );
    const schemaAnahtarlari = new Set(VITRIN_FIELDS.map((a) => a.anahtar));
    for (const cagri of cagrilar) {
      if (cagri === "") continue;
      expect(
        schemaAnahtarlari.has(cagri),
        `editableProps("${cagri}") — bu anahtar şemada yok, yanlış yazılmış`
      ).toBe(true);
    }
  });
});
