import type { SupabaseClient } from "@supabase/supabase-js";
import { expect, it } from "vitest";
import { gomuluIslemOzeti, islemAsamasi, islemleriListele } from "@/lib/faturaIslemOku";

it("satırı olan iş devam edilebilir sayılır", () => {
  expect(islemAsamasi(13, "processed")).toBe("hazir");
  expect(islemAsamasi(1, null)).toBe("hazir");
});

it("sağlayıcı hâlâ çalışıyorsa iş okunuyor sayılır, devam düğmesi verilmez", () => {
  expect(islemAsamasi(0, "queued")).toBe("okunuyor");
  expect(islemAsamasi(0, "received")).toBe("okunuyor");
});

it("tek yanıttaki satır sayısı ve sağlayıcı durumu listeye taşınır, supplier_name sızdırılmaz", () => {
  const hazir = gomuluIslemOzeti({
    id: "a",
    status: "inceleme",
    supplier_name: "Gizli Toptancı A.Ş.",
    created_at: "2026-10-29T10:00:00Z",
    invoice_job_lines: [{ count: 13 }],
    invoice_provider_runs: [{ state: "processed", error_code: null }],
  });
  expect(hazir).toMatchObject({ satirSayisi: 13, asama: "hazir", tedarikci: "", hata: null });

  const yarida = gomuluIslemOzeti({
    id: "b",
    status: "eslestirme",
    supplier_name: null,
    created_at: "2026-10-29T10:00:00Z",
    invoice_job_lines: [{ count: 0 }],
    invoice_provider_runs: [{ state: "failed", error_code: "KART_YANITI_COZULEMEDI" }],
  });
  expect(yarida).toMatchObject({ satirSayisi: 0, asama: "yarida", tedarikci: "", hata: "KART_YANITI_COZULEMEDI" });
});

it("negatif uc durum: islemleriListele eski DB kaydındaki supplier_name alanını seçmez ve sızdırmaz", async () => {
  const secimler: string[] = [];
  const sahteAdmin = (gomuluHata: boolean) =>
    ({
      from: (tablo: string) => {
        let secilen = "";
        const z: Record<string, unknown> = {};
        z.select = (s: string) => {
          secilen = s;
          secimler.push(`${tablo}:${s}`);
          return z;
        };
        z.eq = () => z;
        z.in = () => z;
        z.order = () => z;
        z.limit = () => z;
        z.then = (basari: never, alici: never) => {
          if (tablo === "invoice_jobs" && secilen.includes("invoice_job_lines")) {
            if (gomuluHata) {
              return Promise.resolve({ data: null, error: { message: "embed_unavailable" } }).then(basari, alici);
            }
            return Promise.resolve({
              data: [
                {
                  id: "job-1",
                  status: "inceleme",
                  supplier_name: "Gizli Toptancı A.Ş.",
                  created_at: "2026-11-19T10:00:00Z",
                  invoice_job_lines: [{ count: 2 }],
                  invoice_provider_runs: [{ state: "processed", error_code: null }],
                },
              ],
              error: null,
            }).then(basari, alici);
          }
          if (tablo === "invoice_jobs") {
            return Promise.resolve({
              data: [
                {
                  id: "job-2",
                  status: "inceleme",
                  supplier_name: "Gizli Toptancı A.Ş.",
                  created_at: "2026-11-19T11:00:00Z",
                },
              ],
              error: null,
            }).then(basari, alici);
          }
          if (tablo === "invoice_job_lines") {
            return Promise.resolve({ data: [{ job_id: "job-2" }], error: null }).then(basari, alici);
          }
          return Promise.resolve({ data: [{ job_id: "job-2", state: "processed", error_code: null }], error: null }).then(basari, alici);
        };
        return z;
      },
    }) as unknown as SupabaseClient;

  const birincil = await islemleriListele(sahteAdmin(false), "store-1");
  expect(birincil).toEqual([
    {
      islemKimligi: "job-1",
      durum: "inceleme",
      tedarikci: "",
      olusturma: "2026-11-19T10:00:00Z",
      satirSayisi: 2,
      asama: "hazir",
      hata: null,
    },
  ]);

  const yedek = await islemleriListele(sahteAdmin(true), "store-1");
  expect(yedek).toEqual([
    {
      islemKimligi: "job-2",
      durum: "inceleme",
      tedarikci: "",
      olusturma: "2026-11-19T11:00:00Z",
      satirSayisi: 1,
      asama: "hazir",
      hata: null,
    },
  ]);

  expect(secimler.some((s) => s.includes("supplier_name"))).toBe(false);
  expect(JSON.stringify([...birincil, ...yedek])).not.toContain("Gizli Toptancı");
});

it("tek satır sayısı nesne olarak da gelebilir", () => {
  const ozet = gomuluIslemOzeti({
    id: "c",
    invoice_job_lines: { count: 4 },
    invoice_provider_runs: { state: "queued", error_code: null },
  });
  expect(ozet).toMatchObject({ satirSayisi: 4, asama: "hazir" });
});

it("satırı olmayan ve sağlayıcısı bitmiş iş yarıda kalmış sayılır", () => {
  expect(islemAsamasi(0, "failed")).toBe("yarida");
  expect(islemAsamasi(0, null)).toBe("yarida");
  expect(islemAsamasi(0, "")).toBe("yarida");
});
