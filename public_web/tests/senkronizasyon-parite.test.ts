import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

/**
 * Tek veri / senkronizasyon parite testi (sözleşme §10 "Realtime taslak"
 * satırı: △ Çift taraflı canlı test gerekli).
 *
 * Canlı iki cihaz E2E'si ayrı iştir; bu test, KAYNAK KOD düzeyinde iki
 * istemcinin aynı realtime sözleşmesini kullandığını kilitler:
 *
 *   Kanal 1: `vitrin_<slug>`  — stores UPDATE (postgres_changes)
 *   Kanal 2: `draft:<slug>`   — "alan_guncellendi" Broadcast (veri taşımaz)
 *
 * Kanal adı/olay/filtre değişirse test kırılır → iki taraf senkron bozulur.
 */

const flutterSync = readFileSync(
  resolve(__dirname, "../../lib/services/store_realtime_sync_service.dart"),
  "utf8",
);
const nextSync = readFileSync(
  resolve(__dirname, "../src/lib/canliVitrinSenkron.ts"),
  "utf8",
);

describe("Realtime kanal sözleşmesi (iki istemci aynı)", () => {
  it("her iki taraf aynı canlı kanalı dinler: vitrin_<slug>", () => {
    expect(flutterSync).toContain(".channel('vitrin_$slug')");
    expect(nextSync).toContain(".channel(`vitrin_${slug}`)");
  });

  it("her iki taraf aynı taslak kanalını dinler: draft:<slug>", () => {
    expect(flutterSync).toContain(".channel('draft:$slug')");
    expect(nextSync).toContain(".channel(`draft:${slug}`)");
  });

  it("canlı kanal: stores tablosu UPDATE + slug filtresi (iki taraf)", () => {
    // Flutter
    expect(flutterSync).toContain("PostgresChangeEvent.update");
    expect(flutterSync).toContain("table: 'stores'");
    expect(flutterSync).toContain("column: 'slug'");
    // Next
    expect(nextSync).toContain('"postgres_changes"');
    expect(nextSync).toContain('event: "UPDATE"');
    expect(nextSync).toContain('table: "stores"');
    expect(nextSync).toContain("filter: `slug=eq.${slug}`");
  });

  it("taslak kanal: aynı broadcast olay adı 'alan_guncellendi'", () => {
    expect(flutterSync).toContain("event: 'alan_guncellendi'");
    expect(nextSync).toContain('event: "alan_guncellendi"');
  });

  it("GÜVENLİK: Next taslak broadcast'i alan değeri TAŞIMAZ", () => {
    // Dosya başı güvenlik notu (code-review 2026-08-10): public anon key ile
    // kanala bağlanılabildiği için payload'da ASLA alan verisi olmamalı.
    // Yalnız göndereni tanıyan opak clientId kullanılır.
    expect(nextSync).toContain("clientId");
    expect(nextSync).not.toMatch(/payload\.payload\?\.(deger|kolon|anahtar|etiket)/);
  });

  it("YANKI: kendi yazdığın değişiklik kendi sekmesinde tazeleme tetiklemez", () => {
    expect(nextSync).toContain("senkronClientId");
    expect(nextSync).toMatch(/clientId === senkronClientId.*return|return.*clientId === senkronClientId/s);
  });

  it("Flutter taslak bildirimi callback ile haber verir, veri yazmaz", () => {
    // Servis controller-state'e dokunmaz (dosya başı sözleşme);
    // karar callback'lerle vericilere iletilir.
    expect(flutterSync).toContain("onTaslakDegisti");
    expect(flutterSync).toContain("onCanliDegisti");
  });

  it("temizlik: kanallar kaldırılır (Next removeChannel)", () => {
    expect(nextSync).toContain("removeChannel");
  });
});
