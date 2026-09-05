import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

const oku = (yol: string) =>
  readFileSync(resolve(__dirname, `../src/${yol}`), "utf8");

/**
 * "Landing'de anlatılanın panele taşınması" (2026-09-02) — Faz G1'in tek
 * konuşma köprüsü landing'in niyet akışını zaten assistant_conversations'a
 * yazıyordu; panel bunu okuyup aynı bonus çıkarımını kullanır.
 * 5.6 itibarıyla mutation legacy owner-draft değil authoritative command'dır.
 */
describe("Landing — serbest niyet metni opsiyonel, kategori kutucuklarının yerini almaz", () => {
  const kaynak = oku("components/landing/LandingAsistanSohbeti.tsx");

  it("KategoriGrid hâlâ var — mevcut tıklamalı akış bozulmadı", () => {
    expect(kaynak).toContain("<KategoriGrid");
  });

  it("serbest metin NIYET_SERBEST_METIN_ANAHTARI ile işaretlenerek yazılır", () => {
    expect(kaynak).toContain('const NIYET_SERBEST_METIN_ANAHTARI = "niyet_serbest_metin";');
    expect(kaynak).toContain("messageKey: NIYET_SERBEST_METIN_ANAHTARI");
  });

  it("boşken 'Anlat ve devam et' düğmesi görünmez — zorlamaz", () => {
    expect(kaynak).toContain("niyetSerbestMetin.trim().length > 0 ? (");
  });

  it("serbest metinden de kategori çözülüp aynı Keşfet URL'sine gider", () => {
    const idx = kaynak.indexOf("NIYET_SERBEST_METIN_ANAHTARI }");
    const cevre = kaynak.slice(Math.max(0, idx - 400), idx + 50);
    expect(cevre).toContain("resolveBusinessCategory(metin)");
    expect(cevre).toContain("yalniz_kiralik=1");
  });
});

describe("useOwnerActions.bonusAlanlariCikarVeKaydet — authoritative ortak motor", () => {
  const kaynak = oku("app/v/[slug]/hooks/useOwnerActions.ts");

  it("dışa açık ve authoritative command kullanır", () => {
    expect(kaynak).toContain("export async function bonusAlanlariCikarVeKaydet");
    const baslangic = kaynak.indexOf("export async function bonusAlanlariCikarVeKaydet");
    const bitis = kaynak.indexOf("export function useOwnerActions", baslangic);
    const blok = kaynak.slice(baslangic, bitis);
    expect(blok).toContain("executeSmartEngineCommand({");
    expect(blok).toContain("initialDraftVersion");
    expect(blok).not.toContain('fetch("/api/owner-draft"');
  });
});

describe("OwnerAssistantPanel — taze taslakta landing'in niyet mesajını bulup işler", () => {
  const panel = oku("app/v/[slug]/OwnerAssistantPanel.tsx");

  it("aynı draftYeniOlusturuldu sinyaliyle, oturum başına bir kez tetiklenir", () => {
    expect(panel).toContain(
      "if (!draftYeniOlusturuldu || landingNiyetIslendiRef.current) return;"
    );
    expect(panel).toContain("landingNiyetIslendiRef.current = true;");
  });

  it("get_assistant_conversation'dan niyet_serbest_metin anahtarlı mesajı arar", () => {
    expect(panel).toContain('supabase.rpc("get_assistant_conversation")');
    expect(panel).toContain('m.message_key === "niyet_serbest_metin"');
  });

  it("bulunca aynı bonus motoruna server-loaded draft version verir", () => {
    expect(panel).toContain("bonusAlanlariCikarVeKaydet(");
    expect(panel).toContain("niyetMesaji.message_text,");
    expect(panel).toContain("draftVersion,");
    expect(panel).toContain("setDraftVersion,");
  });

  it("konuşma bulunamazsa/hata olursa sessizce geçer — normal tek-tek soru akışını bloklamaz", () => {
    const idx = panel.indexOf("landingNiyetIslendiRef.current = true;");
    const efektSonu = panel.indexOf(
      "}, [draftYeniOlusturuldu, slug, mesajEkle, setAlan, router, draftVersion, setDraftVersion]);"
    );
    const efektBlok = panel.slice(idx, efektSonu);
    expect(efektBlok).toContain("if (error || !data) return;");
    expect(efektBlok).toContain("} catch {");
  });
});
