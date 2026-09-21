import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  VITRIN_CONCEPTS,
  VITRIN_FIELDS,
  fieldsOfConcept,
} from "../src/lib/vitrinFieldSchema";
import {
  resolveVitrinConceptIntent,
  vitrinConceptPrompt,
} from "../src/lib/vitrinConceptIntent";

describe("Vixrex esnaf kavram katmanı", () => {
  it("46 alanı tam 12 kavram altında kayıpsız toplar", () => {
    expect(VITRIN_FIELDS).toHaveLength(46);
    expect(VITRIN_CONCEPTS).toHaveLength(12);

    const ids = new Set(VITRIN_CONCEPTS.map((kavram) => kavram.id));
    for (const alan of VITRIN_FIELDS) {
      expect(ids.has(alan.kavram), alan.anahtar).toBe(true);
    }

    const toplam = VITRIN_CONCEPTS.reduce(
      (sayac, kavram) => sayac + fieldsOfConcept(kavram.id).length,
      0,
    );
    expect(toplam).toBe(46);
  });

  it("zorunlu, kalite ve otomatik doldurma setlerini değiştirmez", () => {
    expect(VITRIN_FIELDS.filter((alan) => alan.zorunlu).map((alan) => alan.anahtar)).toEqual([
      "isletmeAdi", "kategori", "whatsapp", "adres", "il", "ilce",
    ]);
    expect(VITRIN_FIELDS.filter((alan) => alan.kalite).map((alan) => alan.anahtar)).toEqual([
      "heroRozet", "logo", "kapakGorseli", "mahalle", "calismaSaatleri",
      "haritaLinki", "hakkindaBaslik", "hakkindaMetin",
    ]);
    expect(VITRIN_FIELDS.filter((alan) => alan.otomatikDoldurulabilir).map((alan) => alan.anahtar)).toEqual([
      "heroRozet", "kisaTanitim", "kapakGorseli", "kategoriBolumBaslik",
      "urunBolumBaslik", "hakkindaBaslik", "galeriUstBaslik", "galeriBaslik",
      "galeriAksiyonMetni", "blogUstBaslik", "blogBaslik", "sssUstBaslik",
      "sssBaslik", "sssAciklama",
    ]);
  });

  it("geniş esnaf cümlesini kavrama yönlendirir ama alan komutunu ele geçirmez", () => {
    expect(resolveVitrinConceptIntent("İletişim bilgilerimi düzenlemek istiyorum")?.id).toBe("banaUlasin");
    expect(resolveVitrinConceptIntent("İşletme bilgilerimi güncellemek istiyorum")?.id).toBe("isletmem");
    expect(resolveVitrinConceptIntent("Konumumu değiştireceğim")?.id).toBe("konumum");
    expect(resolveVitrinConceptIntent("Kampanyamı düzenle")?.id).toBe("kampanyam");
    expect(resolveVitrinConceptIntent("Galerimi düzenlemek istiyorum")?.id).toBe("galerim");
    expect(resolveVitrinConceptIntent("Sık sorulanları düzenle")?.id).toBe("sss");
    expect(resolveVitrinConceptIntent("WhatsApp numaramı 0555 123 45 67 yap")).toBeNull();
    expect(resolveVitrinConceptIntent("Kampanya başlığını Hafta Sonu Fırsatı yap")).toBeNull();
  });

  it("kavram yanıtı yalnız yönlendirir, değer üretmez", () => {
    const kavram = VITRIN_CONCEPTS.find((item) => item.id === "banaUlasin");
    expect(kavram).toBeDefined();
    const mesaj = vitrinConceptPrompt(kavram!);
    expect(mesaj).toBe("WhatsApp, telefon veya e-posta bilgilerinden hangisini değiştirelim?");
  });

  it("normal görünüm kavramları, gelişmiş görünüm mevcut 46 alanı korur", () => {
    const kavramPaneli = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/components/ConceptProgressList.tsx"),
      "utf8",
    );
    const gelismis = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/components/SectionProgressList.tsx"),
      "utf8",
    );
    expect(kavramPaneli).toContain("VITRIN_CONCEPTS.map");
    expect(kavramPaneli).toContain("fieldsOfConcept");
    expect(gelismis).toContain("Gelişmiş · Tüm alanlar");
    expect(gelismis).toContain("VITRIN_FIELDS.filter");
    expect(gelismis).toContain("SECTION_ORDER.map");
  });

  it("kavram konuşması batch veya tek alan API çağrısı yapmadan önce kesilir", () => {
    const actions = readFileSync(
      resolve(__dirname, "../src/app/v/[slug]/hooks/useOwnerActions.ts"),
      "utf8",
    );
    const kavram = actions.indexOf("const kavramNiyeti");
    const batch = actions.indexOf('fetch("/api/owner-draft-batch"', kavram);
    const tek = actions.indexOf('fetch("/api/owner-draft"', kavram);
    expect(kavram).toBeGreaterThanOrEqual(0);
    expect(actions.slice(kavram, Math.min(batch, tek))).toContain("if (kavramNiyeti)");
    expect(actions.slice(kavram, Math.min(batch, tek))).toContain("return;");
  });
});
